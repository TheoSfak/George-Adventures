extends SceneTree
## Plays the whole quest line with simulated input:
##   godot --path . --resolution 1280x720 --script tools/questtest.gd -- <outdir>
var out := "."
var p: Player
var q: Node
var hud: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.1).timeout
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)


func npc(id: String) -> Node3D:
	for n in get_nodes_in_group("interactables"):
		if n.get("npc_id") != null and n.get("npc_id") == id:
			return n
	return null


## Walks up to an NPC, talks, and clicks through the whole dialogue.
func talk(id: String, take_shot := "") -> void:
	var n = npc(id)
	p.teleport(n.global_position + Vector3(2.5, 0.05, 0), -PI / 2.0)
	await create_timer(0.5).timeout
	await press("interact")
	await create_timer(0.5).timeout
	if take_shot != "":
		await create_timer(1.0).timeout
		await shot(take_shot)
	var guard := 0
	while hud.is_dialogue_open() and guard < 30:
		guard += 1
		await create_timer(0.4).timeout
		await press("interact")
	await create_timer(0.6).timeout


func kill_nearest(count: int, kind := "") -> void:
	var killed := 0
	for e in get_nodes_in_group("enemies"):
		if killed >= count:
			break
		if kind == "" or e.kind_id == kind:
			e.take_damage(9999.0, p.global_position)
			killed += 1
	await create_timer(0.3).timeout


func states() -> String:
	var parts := []
	for id in QuestData.QUESTS:
		parts.append("%s=%s" % [id, ["locked", "available", "active", "ready", "done"][q.state[id]]])
	return ", ".join(parts)


func _run() -> void:
	await process_frame
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	p = get_first_node_in_group("player") as Player
	hud = get_first_node_in_group("hud")
	print("1) start: ", states())
	print("   stavros marker: '", q.marker_for("stavros"), "'  maria marker: '", q.marker_for("maria"), "'")

	# --- quest 1: kill four skeletons
	await talk("stavros", "quest_dialogue")
	print("2) after talking to Stavros: ", states())
	await shot("quest_tracker_1")
	await kill_nearest(3)
	print("   after 3 kills: ", q.tracker())
	await kill_nearest(1)
	print("   after 4 kills: ", states(), " stavros marker '", q.marker_for("stavros"), "'")
	var xp0: int = p.xp
	var gold0: int = p.gold
	await talk("stavros")
	print("3) handed in: ", states(), "  gold +", p.gold - gold0, " potions ", p.potions, " xp now ", p.xp, " level ", p.level)
	print("   markers: maria '", q.marker_for("maria"), "' nikitas '", q.marker_for("nikitas"), "' giannis '", q.marker_for("giannis"), "'")

	# --- quests 2-4
	await talk("maria")
	await talk("nikitas")
	await talk("giannis")
	print("4) accepted three quests: ", states())
	var items := []
	for n in get_nodes_in_group("interactables"):
		pass
	for item in root.find_children("*", "QuestItem", true, false):
		items.append(item)
	print("   quest items in world: ", items.size(), " visible: ", items.filter(func(i): return i.visible).size())
	for item in items:
		if item.visible:
			p.teleport(item.global_position + Vector3(0, 0.05, 0), 0.0)
			await create_timer(0.4).timeout
	await create_timer(0.5).timeout
	print("   after collecting: ", states(), " items left in world: ", root.find_children("*", "QuestItem", true, false).size())
	await kill_nearest(1, "captain")
	print("   after captain: ", states())
	await talk("maria")
	await talk("nikitas")
	var dmg0: float = p.sword_damage
	await talk("giannis")
	print("5) handed in 2-4: ", states(), " gold ", p.gold, " sword ", p.sword_damage, " level ", p.level)

	# --- final quest
	await talk("stavros")
	print("6) king quest accepted: ", states())
	await kill_nearest(1, "king")
	print("   king dead: ", states())
	var finished := [false]
	q.game_finished.connect(func(): finished[0] = true)
	await talk("stavros", "quest_end_dialogue")
	await create_timer(4.5).timeout
	await shot("the_end")
	print("7) finished: ", states(), " game_finished fired: ", finished[0], " level ", p.level, " gold ", p.gold, " potions ", p.potions)
	quit()
