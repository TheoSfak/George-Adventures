extends SceneTree
## Food buffs, cooking and the fish journal:
##   godot --path . --headless --script tools/kitchen_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var save = load("res://scripts/save_game.gd")
	# keep the player's real save safe: this test writes savegame.json
	var real_backup := "user://savegame.before_kitchen_test"
	var real_bak_backup := "user://savegame.bak.before_kitchen_test"
	if FileAccess.file_exists(save.PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(save.BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.BACKUP), ProjectSettings.globalize_path(real_bak_backup))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	var base_hp := p.max_health
	var base_damage := p.sword_damage
	check("starting with no meal", p.food.is_empty() and p.buff_time("food") == 0.0 and p.food_name() == "")

	# --- a meal bought with gold
	p.gold = 100
	check("fasolada is bought", p.prepare_meal("fasolada"))
	check("it cost 25 gold", p.gold == 75)
	check("max health +30", is_equal_approx(p.max_health, base_hp + 30.0))
	check("the buff has about 600 s", p.food_time() > 595.0 and p.food_name() == "Φασολάδα")
	check("the HUD sees it as a buff", p.buff_time("food") > 595.0)

	# --- fried fish: cheapest common fish are used, a new meal replaces the old one
	p.junk = {"goby": 2, "perch": 3}
	check("fried fish is cooked", p.prepare_meal("fried"))
	check("2 gobies and 1 perch were used", int(p.junk.get("goby", 0)) == 0 and int(p.junk.get("perch", 0)) == 2)
	check("5 gold was paid (75 -> 70)", p.gold == 70)
	check("the new meal replaced the old: max health +50 (not +80)", is_equal_approx(p.max_health, base_hp + 50.0))
	check("fried fish gives +1 regen", is_equal_approx(p.stats.total("regen"), 1.0))

	# --- a meal you cannot make changes nothing
	p.junk = {"trout": 1}
	var gold_before := p.gold
	check("soup needs 2 uncommon fish: refused", not p.prepare_meal("soup"))
	check("nothing was spent", p.gold == gold_before and int(p.junk["trout"]) == 1 and p.food["id"] == "fried")
	p.gold = 2
	check("fried fish without gold: refused", not p.prepare_meal("fried"))

	# --- damage and speed buffs change the numbers where they are used
	p.gold = 100
	check("kreas bought", p.prepare_meal("kreas"))
	check("kreas gives +10% damage", is_equal_approx(p.sword_damage, base_damage * 1.10))
	p.gold = 100
	p.prepare_meal("tyropita")
	check("tyropita gives +8% speed", is_equal_approx(p.stats.total("speed_mult"), 0.08))
	check("...and the damage buff is gone", is_equal_approx(p.sword_damage, base_damage))

	# --- the buff ends
	p.food["time"] = 0.05
	await create_timer(0.4).timeout
	check("the meal wore off", p.food.is_empty() and p.buff_time("food") == 0.0)
	check("max health and speed are back", is_equal_approx(p.max_health, base_hp) and p.stats.total("speed_mult") == 0.0)

	# --- the feast
	p.junk = {"king": 1}
	p.gold = 50
	check("the feast is cooked from the legendary fish", p.prepare_meal("feast"))
	check("it lasts 15 minutes", p.food_time() > 895.0)
	check("max health +100", is_equal_approx(p.max_health, base_hp + 100.0))
	check("the king was used", int(p.junk.get("king", 0)) == 0)

	# --- the journal
	p.fish_seen = []
	p.junk = {}
	check("the first goby is a new species", p.add_fish("goby"))
	check("the second one is not", not p.add_fish("goby"))
	check("two gobies in the bag", int(p.junk["goby"]) == 2)
	p.add_fish("king")
	check("journal has 2 species", p.fish_seen.size() == 2)

	# --- the journal survives a save and a load
	save.delete()
	check("saved", save.save())
	var data: Dictionary = save.read()
	check("fish_seen is in the save", data["player"]["fish_seen"] == ["goby", "king"])
	p.fish_seen = []
	save.apply(data)
	await create_timer(0.5).timeout
	check("the journal is restored", p.fish_seen == ["goby", "king"])
	var old: Dictionary = data.duplicate(true)
	old["player"].erase("fish_seen")
	p.fish_seen = ["x"]
	save.apply(old)
	await create_timer(0.5).timeout
	check("an old save without the key gives an empty journal", p.fish_seen.is_empty())

	save.delete()
	if FileAccess.file_exists(real_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_backup), ProjectSettings.globalize_path(save.PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(real_bak_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_bak_backup), ProjectSettings.globalize_path(save.BACKUP))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_bak_backup))
	quit(1 if failed else 0)
