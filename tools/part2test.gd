extends SceneTree
## Plays story part 2 (the catacombs quests) with simulated input:
##   godot --path . --resolution 1280x720 --script tools/part2test.gd -- <outdir>
var out := "."
var p: Player
var q: Node
var hud: Node
var cat   # catacombs.gd, loaded (it mentions the Quests autoload, so no type reference)


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


func kill(kind: String, count: int) -> int:
	var killed := 0
	for e in get_nodes_in_group("enemies"):
		if killed >= count:
			break
		if e.kind_id == kind and not e.is_dead():
			e.take_damage(99999.0, p.global_position)
			killed += 1
	await create_timer(0.3).timeout
	return killed


func alive(kind: String) -> int:
	var n := 0
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == kind and not e.is_dead():
			n += 1
	return n


func states() -> String:
	var parts := []
	for id in ["king", "descent", "cguards", "pages", "wardens", "necro"]:
		parts.append("%s=%s" % [id, ["locked", "available", "active", "ready", "done"][q.state[id]]])
	return ", ".join(parts)


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)


func _run() -> void:
	await process_frame
	cat = load("res://scripts/catacombs.gd")
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	p = get_first_node_in_group("player") as Player
	hud = get_first_node_in_group("hud")
	p._invulnerable = 99999.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	for id in QuestData.QUESTS:
		if id in ["descent", "cguards", "pages", "wardens", "necro"]:
			continue
		q.state[id] = q.S.DONE
	q._refresh_availability()
	check("descent is available after the Bone King: " + states(), q.state["descent"] == q.S.AVAILABLE)
	check("Stavros shows a '!'", q.marker_for("stavros") == "!")
	check("Part 1 no longer ends the game (king has no ends_game)", not QuestData.QUESTS["king"].has("ends_game"))

	# --- the descent
	await talk("stavros", "p2_01_stavros_offer")
	check("accepted the descent: " + states(), q.state["descent"] == q.S.ACTIVE)
	var door: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.global_position.distance_to(Vector3(0, 0, -188)) < 4.0:
			door = n
	p.teleport(door.global_position + Vector3(0, 0.05, 2.0), PI)
	await create_timer(0.5).timeout
	await press("interact")
	for i in 80:
		await create_timer(0.1).timeout
		if get_first_node_in_group("interiors").is_inside() and not p.busy:
			break
	check("inside the catacombs, descent is ready to hand in: " + states(), q.state["descent"] == q.S.READY)
	check("Theodora shows a '?'", q.marker_for("theodora") == "?")
	await talk("theodora", "p2_02_theodora_complete")
	check("descent done, cguards + pages available: " + states(), q.state["descent"] == q.S.DONE and q.state["cguards"] == q.S.AVAILABLE and q.state["pages"] == q.S.AVAILABLE)

	# --- a boss killed before his quest is taken must come back later
	check("one Bone Warden stands in the dungeon", alive("warden_bone") == 1)
	await kill("warden_bone", 1)
	check("...and is dead now", alive("warden_bone") == 0)

	# --- guards and pages
	await talk("theodora")
	await talk("theodora")
	check("accepted guards + pages: " + states(), q.state["cguards"] == q.S.ACTIVE and q.state["pages"] == q.S.ACTIVE)
	var guards := await kill("cguard", 6)
	var acolytes := await kill("acolyte", 3)
	print("   killed ", guards, " guards and ", acolytes, " acolytes: ", q.tracker())
	check("guard quest ready: " + states(), q.state["cguards"] == q.S.READY)
	var pages := 0
	for item in root.find_children("*", "QuestItem", true, false):
		if item.item_id == "page" and item.visible:
			pages += 1
			p.teleport(item.global_position + Vector3(0, 0.05, 0), 0.0)
			await create_timer(0.5).timeout
	print("   pages found: ", pages)
	check("page quest ready: " + states(), q.state["pages"] == q.S.READY)
	await talk("theodora")
	await talk("theodora")
	check("both handed in, wardens available: " + states(), q.state["cguards"] == q.S.DONE and q.state["pages"] == q.S.DONE and q.state["wardens"] == q.S.AVAILABLE)

	# --- the three wardens
	await talk("theodora")
	check("accepted wardens: " + states(), q.state["wardens"] == q.S.ACTIVE)
	await create_timer(0.5).timeout
	check("the early-killed Bone Warden came back", alive("warden_bone") == 1)
	var level := get_first_node_in_group("catacombs")
	check("the gate is still sealed", not level._gate_open)
	p.teleport(cat.wp(30.0, 14.0, 0.05), PI)
	await create_timer(0.6).timeout
	await shot("p2_03_gate_sealed")
	await kill("warden_bone", 1)
	await kill("warden_flame", 1)
	check("two wardens down: gate still sealed", not level._gate_open)
	await kill("warden_shadow", 1)
	check("three wardens down: " + states(), q.state["wardens"] == q.S.READY)
	await create_timer(1.2).timeout
	check("the gate opened", level._gate_open)
	await shot("p2_04_gate_open")
	await talk("theodora")
	check("wardens done, necro available: " + states(), q.state["wardens"] == q.S.DONE and q.state["necro"] == q.S.AVAILABLE)
	await talk("theodora")
	check("accepted necro: " + states(), q.state["necro"] == q.S.ACTIVE)

	# --- the abbot: he summons helpers while fighting
	var boss
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "necromancer":
			boss = e
	p.teleport(cat.wp(30.0, 8.0, 0.05), 0.0)
	var before := get_nodes_in_group("enemies").size()
	var summoned := false
	for i in 120:
		await create_timer(0.25).timeout
		if get_nodes_in_group("enemies").size() > before:
			summoned = true
			break
	check("the necromancer summoned helpers (enemies %d -> %d)" % [before, get_nodes_in_group("enemies").size()], summoned)
	await shot("p2_05_abbot_fight")
	await kill("necromancer", 1)
	check("necromancer dead, hand in at Stavros: " + states(), q.state["necro"] == q.S.READY)

	# --- the ending
	var exit_spot: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_EXIT and n.global_position.distance_to(p.global_position) < 200.0:
			exit_spot = n
	p.teleport(exit_spot.global_position, PI)
	await create_timer(0.5).timeout
	await press("interact")
	await create_timer(1.8).timeout
	var finished := [false]
	q.game_finished.connect(func(): finished[0] = true)
	await talk("stavros", "p2_06_stavros_end")
	await create_timer(4.5).timeout
	await shot("p2_07_the_end")
	check("part 2 finished: " + states(), q.state["necro"] == q.S.DONE and finished[0])
	print("level ", p.level, " gold ", p.gold, " potions ", p.potions)
	quit()
