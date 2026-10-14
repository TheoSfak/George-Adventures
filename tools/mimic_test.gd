extends SceneTree
## The mimic chests: godot --path . --headless --script tools/mimic_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


## (Chest is not named as a type: its script mentions the Quests autoload, which does not exist while this file compiles.)
func chest_at(pos: Vector2) -> Node:
	for c in get_nodes_in_group("chests"):
		if Vector2(c.global_position.x, c.global_position.z).distance_to(pos) < 0.5:
			return c
	return null


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var save = load("res://scripts/save_game.gd")
	var backup := FileAccess.get_file_as_bytes("user://savegame.json") if FileAccess.file_exists("user://savegame.json") else PackedByteArray()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	var village = load("res://scripts/village.gd")
	var mimics := 0
	var normal := 0
	for c in village.CHESTS:
		if c.size() > 7 and c[7]:
			mimics += 1
		else:
			normal += 1
	check("three chests of the village are mimics, the others are not (%d / %d)" % [mimics, normal], mimics == 3 and normal >= 8)
	check("the golden chest of the cult is in the list", chest_at(CultSite.CHEST) != null and chest_at(CultSite.CHEST).golden)

	var spot := Vector2(-30, -135)
	var chest := chest_at(spot)
	check("the mimic chest by the crypt road exists", chest != null and chest.mimic)
	check("it looks and prompts like any chest", chest.interact_prompt() == Strings.PROMPT_OPEN and chest.is_in_group("interactables"))
	var plain := chest_at(Vector2(-133, -76))
	check("an ordinary chest has the same prompt and is no mimic", plain != null and not plain.mimic and plain.interact_prompt() == Strings.PROMPT_OPEN)

	p.teleport(chest.global_position + Vector3(0, 0.05, 2.5), PI)
	await create_timer(0.5).timeout
	var enemies_before := get_nodes_in_group("enemies").size()
	var gold_before := p.gold
	chest.interact(p)
	await create_timer(1.2).timeout
	var mimic: Enemy = null
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "mimic":
			mimic = e
	check("opening it brings a mimic to life where the chest stood", mimic != null and Vector2(mimic.global_position.x, mimic.global_position.z).distance_to(spot) < 5.0)   # it has already hopped toward George
	check("the chest itself is gone (no coins, no second prompt)", not is_instance_valid(chest) or chest.is_queued_for_deletion() or not chest.is_in_group("interactables"))
	check("George got no gold from it", p.gold == gold_before)
	check("the creature is named and awake (it bites)", mimic != null and mimic.display_name == "Μίμικ" and mimic._state != Enemy.State.DORMANT)
	check("the save remembers the chest as opened", save.opened_chests.has(save.key_for(Vector3(spot.x, 0, spot.y))))

	# it fights and gives its reward
	p._invulnerable = 0.0
	p.max_health = 100000.0
	p.health = 100000.0
	var hp0 := p.health
	for i in 5 * 60:
		await physics_frame
	check("the mimic hops to George and bites (%.0f damage)" % (hp0 - p.health), p.health < hp0 and mimic._state != Enemy.State.DEAD)
	var gold1 := p.gold
	mimic.take_damage(10000.0, mimic.global_position + Vector3(1, 0, 0))
	await create_timer(1.0).timeout
	var coins := 0
	for n in get_nodes_in_group("pickups"):
		coins += 1
	check("killing it drops its loot (%d pickups)" % coins, coins > 0 or p.gold > gold1)
	await create_timer(1.5).timeout
	var again := 0
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "mimic":
			again += 1
	check("and it never comes back", again == 0)

	# an opened chest from an older game is just an open chest (no mimic)
	var sibling := chest_at(Vector2(128, -52))
	check("the second mimic chest is still closed", sibling != null and not sibling.opened)
	sibling.mark_opened()
	check("a chest marked opened (loading a save) shows the open lid and cannot be opened again", sibling.opened and sibling.interact_prompt() == "")
	sibling.interact(p)
	await create_timer(0.8).timeout
	var made := 0
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "mimic":
			made += 1
	check("no mimic comes out of it", made == 0)

	# put the real save file back
	if backup.size() > 0:
		var f := FileAccess.open("user://savegame.json", FileAccess.WRITE)
		f.store_buffer(backup)
		f.close()
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
