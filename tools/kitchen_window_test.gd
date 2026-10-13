extends SceneTree
## The kitchen window, the cook in the tavern, the HUD food pill, the journal line:
##   godot --path . --headless --script tools/kitchen_window_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func rows_of(shop: Node) -> int:
	return shop._list.get_child_count()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var hud = get_first_node_in_group("hud")
	var interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	p.gold = 200
	p.junk = {"goby": 3, "trout": 2}

	# --- the window
	hud.open_shop("kitchen", p)
	await create_timer(0.4).timeout
	var shop = hud.find_child("ShopWindow", true, false)
	check("the kitchen window opens and George stands still", shop.is_open() and p.busy)
	check("the meals tab lists 3 meals", rows_of(shop) == 3)
	shop._set_tab("cook")
	await create_timer(0.2).timeout
	check("the cook tab lists 4 meals", rows_of(shop) == 4)
	var hp_before := p.max_health
	shop._eat("fried")
	await create_timer(0.3).timeout
	check("cooking fried fish through the window works", p.food.get("id", "") == "fried" and int(p.junk.get("goby", 0)) == 0 and p.max_health == hp_before + 50.0)
	check("the window refreshed (still 4 rows)", rows_of(shop) == 4)
	shop._set_tab("buy")
	shop._eat("kreas")
	await create_timer(0.3).timeout
	check("buying a meal replaces the buff", p.food["id"] == "kreas")
	shop.close()
	await create_timer(0.5).timeout
	check("closing frees George", not p.busy)

	# --- the HUD pill
	await create_timer(0.3).timeout
	var pill: Label = hud._buff_labels["food"]
	check("the HUD shows a food pill with the meal name and minutes: '%s'" % pill.text, pill.visible and pill.text.begins_with("Κρέας με Πατάτες") and pill.text.contains(":"))

	# --- the cook stands in the tavern
	interiors.enter("tavern_test", "tavern", Vector3(-59, 0.05, 5), 0.0, p)
	for i in 60:
		await create_timer(0.1).timeout
		if interiors.is_inside() and not p.busy:
			break
	var cook = null
	for n in get_nodes_in_group("interactables"):
		if n.get("npc_id") == "thanasis":
			cook = n
	check("Thanasis stands in the tavern", cook != null)
	if cook != null:
		check("his prompt is a trade prompt", cook.interact_prompt() == Strings.PROMPT_TRADE % "Θανάσης ο Μάγειρας")

	# --- the journal line in the hero window
	p.fish_seen = ["goby", "king", "eel"]
	var hero = hud.find_child("HeroWindow", true, false)
	if hero == null:
		hero = hud._hero
	hero.toggle("gear")
	await create_timer(0.3).timeout
	var found := false
	for l in hero.find_children("*", "Label", true, false):
		if (l as Label).text == "Ψάρια: 3/13":
			found = true
	check("the hero window shows 'Ψάρια: 3/13'", found)
	quit(1 if failed else 0)
