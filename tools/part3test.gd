extends SceneTree
## Plays story part 3 (the Frontier) from the first talk with Stavros to the ending:
##   godot --path . --resolution 1280x720 --script tools/part3test.gd -- tools/_shots/part3
var out := "."
var failed := false
var p: Player
var q: Node
var hud: Node
var interiors
var fr   # frontier.gd, loaded (it mentions the Quests autoload, so no type reference)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
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
	while hud.is_dialogue_open() and guard < 40:
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
	for id in ["necro", "f_gate", "f_guards", "f_symbols", "f_wall", "f_malakar", "f_return"]:
		parts.append("%s=%s" % [id, ["locked", "available", "active", "ready", "done"][q.state[id]]])
	return ", ".join(parts)


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func wait_region(on: bool) -> void:
	for i in 150:
		await create_timer(0.1).timeout
		if interiors.in_region() == on and not p.busy:
			return


func gate_spot() -> InteractSpot:
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.global_position.distance_to(fr.VILLAGE_GATE + Vector3(0, 0, 3)) < 2.0:
			return n
	return null


func _run() -> void:
	await process_frame
	fr = load("res://scripts/frontier.gd")
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	p = get_first_node_in_group("player") as Player
	hud = get_first_node_in_group("hud")
	interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	for id in QuestData.QUESTS:
		if id.begins_with("f_"):
			continue
		q.state[id] = q.S.DONE
	q._refresh_availability()
	check("f_gate is available after Part 2: " + states(), q.state["f_gate"] == q.S.AVAILABLE)
	check("Stavros shows a '!'", q.marker_for("stavros") == "!")

	# --- the gate is sealed until Stavros has spoken
	var spot := gate_spot()
	check("the pass gate exists", spot != null)
	p.teleport(fr.VILLAGE_GATE + Vector3(0, 0.05, 6), 0.0)
	await create_timer(0.5).timeout
	await press("interact")
	await create_timer(0.8).timeout
	check("sealed: George stays in the village", not interiors.in_region())
	await shot("p3_01_gate_sealed")
	await talk("stavros", "p3_02_stavros_offer")
	check("accepted f_gate: " + states(), q.state["f_gate"] == q.S.ACTIVE)

	# --- through the gate
	p.teleport(fr.VILLAGE_GATE + Vector3(0, 0.05, 6), 0.0)
	await create_timer(0.5).timeout
	await press("interact")
	await wait_region(true)
	check("in the Frontier, f_gate ready to hand in: " + states(), interiors.in_region() and q.state["f_gate"] == q.S.READY)
	await shot("p3_03_entry")
	check("the corner minimap is hidden", not hud._mini_frame.visible)
	var level := get_first_node_in_group("frontier")
	check("the fortress gate is sealed", not level._gate_open)
	check("Ilarion shows a '?'", q.marker_for("ilarion") == "?")
	await talk("ilarion", "p3_04_ilarion_complete")
	check("f_gate done, f_guards + f_symbols available: " + states(), q.state["f_gate"] == q.S.DONE and q.state["f_guards"] == q.S.AVAILABLE and q.state["f_symbols"] == q.S.AVAILABLE)

	# --- the pass: guards and symbols
	await talk("ilarion")
	await talk("elpida", "p3_05_elpida_offer")
	check("accepted guards + symbols: " + states(), q.state["f_guards"] == q.S.ACTIVE and q.state["f_symbols"] == q.S.ACTIVE)
	var knights := await kill("shadow_knight", 5)
	var collectors := await kill("soul_collector", 3)
	print("   killed ", knights, " knights and ", collectors, " collectors")
	check("guards quest ready: " + states(), q.state["f_guards"] == q.S.READY)
	check("the fortress gate is still sealed", not level._gate_open)
	var found := 0
	for item in root.find_children("*", "QuestItem", true, false):
		if item.item_id == "symbol" and item.visible:
			found += 1
			p.teleport(item.global_position + Vector3(0, 0.05, 0), 0.0)
			await create_timer(0.5).timeout
	print("   symbols found: ", found)
	check("symbols ready: " + states(), q.state["f_symbols"] == q.S.READY)
	await create_timer(1.2).timeout
	check("the fortress gate opened", level._gate_open)
	await talk("ilarion")
	await talk("elpida")
	check("both handed in, f_wall available: " + states(), q.state["f_guards"] == q.S.DONE and q.state["f_symbols"] == q.S.DONE and q.state["f_wall"] == q.S.AVAILABLE)

	# --- the giant: a giant killed too early comes back when the quest starts
	check("one giant skeleton stands in the courtyard", alive("giant_skeleton") == 1)
	await kill("giant_skeleton", 1)
	check("...and is dead now", alive("giant_skeleton") == 0)
	await talk("ilarion")
	check("accepted f_wall: " + states(), q.state["f_wall"] == q.S.ACTIVE)
	await create_timer(0.5).timeout
	check("the early-killed giant came back", alive("giant_skeleton") == 1)
	p.teleport(fr.wp(0.0, -100.0, 0.05), PI)
	await create_timer(0.8).timeout
	await shot("p3_06_fortress_gate_open")
	await kill("giant_skeleton", 1)
	check("giant dead, f_wall ready: " + states(), q.state["f_wall"] == q.S.READY)
	await talk("ilarion")
	check("f_wall done, f_malakar available: " + states(), q.state["f_wall"] == q.S.DONE and q.state["f_malakar"] == q.S.AVAILABLE)
	await talk("elpida")
	check("accepted f_malakar: " + states(), q.state["f_malakar"] == q.S.ACTIVE)

	# --- Malakar enrages and calls help
	var boss
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "malakar":
			boss = e
	p.teleport(fr.wp(0.0, -134.0, 0.05), PI)
	await create_timer(0.8).timeout
	await shot("p3_07_malakar")
	boss.take_damage(boss.max_health * 0.55, p.global_position)
	check("Malakar enraged below half health", boss._enraged)
	var before := get_nodes_in_group("enemies").size()
	var called := false
	for i in 80:
		await create_timer(0.25).timeout
		if get_nodes_in_group("enemies").size() > before:
			called = true
			break
	check("...and called shadow knights (enemies %d -> %d)" % [before, get_nodes_in_group("enemies").size()], called)
	await shot("p3_08_malakar_enraged")
	await kill("malakar", 1)
	check("Malakar dead, hand in at Ilarion: " + states(), q.state["f_malakar"] == q.S.READY)
	await talk("ilarion")
	check("f_malakar done, f_return available: " + states(), q.state["f_malakar"] == q.S.DONE and q.state["f_return"] == q.S.AVAILABLE)
	await talk("ilarion")
	check("accepted f_return: " + states(), q.state["f_return"] == q.S.ACTIVE)

	# --- away from home: no invasion, saves work (the real save and its backup are kept safe)
	var invasion = get_first_node_in_group("invasion")
	invasion.start(1)
	check("the invasion is skipped while George is away", not invasion.active)
	var save = load("res://scripts/save_game.gd")
	var real_backup := "user://savegame.before_part3test"
	var real_bak_backup := "user://savegame.bak.before_part3test"
	if FileAccess.file_exists(save.PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(save.BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.BACKUP), ProjectSettings.globalize_path(real_bak_backup))
	save.delete()
	save.save()
	check("the save knows he is in the Frontier", bool(save.read()["player"].get("in_frontier", false)))
	save.delete()
	if FileAccess.file_exists(real_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_backup), ProjectSettings.globalize_path(save.PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(real_bak_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_bak_backup), ProjectSettings.globalize_path(save.BACKUP))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_bak_backup))

	# --- home again
	var exit_spot: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_FRONTIER_BACK:
			exit_spot = n
	p.teleport(exit_spot.global_position, PI)
	await create_timer(0.5).timeout
	await press("interact")
	await wait_region(false)
	check("back in the village, f_return ready: " + states(), not interiors.in_region() and q.state["f_return"] == q.S.READY)
	var finished := [false]
	q.game_finished.connect(func(): finished[0] = true)
	await talk("stavros", "p3_09_stavros_end")
	await create_timer(4.5).timeout
	await shot("p3_10_the_end")
	check("part 3 finished: " + states(), q.state["f_return"] == q.S.DONE and finished[0])
	print("level ", p.level, " gold ", p.gold, " potions ", p.potions)
	quit(1 if failed else 0)
