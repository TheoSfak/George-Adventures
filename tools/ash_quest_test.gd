extends SceneTree
## Plays story part 4 (the Ash Valley) from the first talk with Stavros to the ending (headless: no screenshots):
##   godot --path . --headless --script tools/ash_quest_test.gd
## or windowed with pictures: godot --path . --resolution 1280x720 --script tools/ash_quest_test.gd -- tools/_shots/part4
var out := "tools/_shots"
var failed := false
var p: Player
var q: Node
var hud: Node
var interiors
var av   # ash_valley.gd, loaded (it mentions the Quests autoload, so no type reference)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
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
	for id in ["f_return", "a_gate", "a_embers", "a_shards", "a_boss"]:
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
		if n is InteractSpot and n.global_position.distance_to(av.VILLAGE_GATE) < 4.5:
			return n
	return null


func _run() -> void:
	await process_frame
	av = load("res://scripts/ash_valley.gd")
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
		if id.begins_with("a_"):
			continue
		q.state[id] = q.S.DONE
	q._refresh_availability()
	check("a_gate is available after Part 3: " + states(), q.state["a_gate"] == q.S.AVAILABLE)
	check("Stavros shows a '!'", q.marker_for("stavros") == "!")

	# --- the gate is sealed until Stavros has spoken
	var spot := gate_spot()
	check("the Ash Gate exists", spot != null)
	p.teleport(spot.global_position + Vector3(0, 0.05, 0), 0.0)
	await create_timer(0.5).timeout
	await press("interact")
	await create_timer(0.8).timeout
	check("sealed: George stays in the village", not interiors.in_region())
	await shot("p4_01_gate_sealed")
	await talk("stavros", "p4_02_stavros_offer")
	check("accepted a_gate: " + states(), q.state["a_gate"] == q.S.ACTIVE)

	# --- through the gate
	p.teleport(spot.global_position + Vector3(0, 0.05, 0), 0.0)
	await create_timer(0.5).timeout
	await press("interact")
	await wait_region(true)
	check("in the valley, a_gate ready to hand in: " + states(), interiors.in_region() and interiors.current_kind == "ashvalley" and q.state["a_gate"] == q.S.READY)
	await shot("p4_03_entry")
	var level := get_first_node_in_group("ashvalley")
	check("the temple gate is sealed", not level._gate_open)
	check("Theofilos shows a '?'", q.marker_for("theofilos") == "?")
	await talk("theofilos", "p4_04_theofilos_complete")
	check("a_gate done, a_embers + a_shards available: " + states(), q.state["a_gate"] == q.S.DONE and q.state["a_embers"] == q.S.AVAILABLE and q.state["a_shards"] == q.S.AVAILABLE)
	check("Theofilos and Damianos show a '!'", q.marker_for("theofilos") == "!" and q.marker_for("damianos") == "!")

	# --- embers and shards
	await talk("theofilos")
	await talk("damianos", "p4_05_damianos_offer")
	check("accepted embers + shards: " + states(), q.state["a_embers"] == q.S.ACTIVE and q.state["a_shards"] == q.S.ACTIVE)
	var embers := await kill("ember_skeleton", 8)
	check("embers: not ready after only the skeletons", q.state["a_embers"] == q.S.ACTIVE)
	var casters := await kill("ash_caster", 4)
	print("   killed ", embers, " ember skeletons and ", casters, " casters")
	check("embers quest ready: " + states(), q.state["a_embers"] == q.S.READY)
	check("the temple gate is still sealed", not level._gate_open)
	var found := 0
	for item in root.find_children("*", "QuestItem", true, false):
		if item.item_id == "shard" and item.visible:
			found += 1
			p.teleport(item.global_position + Vector3(0, 0.05, 0), 0.0)
			await create_timer(0.5).timeout
	print("   shards found: ", found)
	check("shards ready: " + states(), q.state["a_shards"] == q.S.READY)
	await create_timer(1.2).timeout
	check("the temple gate opened", level._gate_open)
	await talk("theofilos")
	await talk("damianos")
	check("both handed in, a_boss available: " + states(), q.state["a_embers"] == q.S.DONE and q.state["a_shards"] == q.S.DONE and q.state["a_boss"] == q.S.AVAILABLE)

	# --- the Keeper: killed too early he comes back when the quest starts
	check("one Keeper stands in the temple", alive("pyrforos") == 1)
	await kill("pyrforos", 1)
	check("...and is dead now", alive("pyrforos") == 0)
	await talk("theofilos")
	check("accepted a_boss: " + states(), q.state["a_boss"] == q.S.ACTIVE)
	await create_timer(0.5).timeout
	check("the early-killed Keeper came back", alive("pyrforos") == 1)
	p.teleport(av.wp(0.0, -135.0, 0.05), PI)
	await create_timer(0.8).timeout
	await shot("p4_06_temple_gate_open")
	p.teleport(av.wp(0.0, -150.0, 0.05), PI)
	await create_timer(0.8).timeout
	await shot("p4_07_pyrforos")

	# --- he enrages and calls help
	var boss
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "pyrforos":
			boss = e
	boss.take_damage(boss.max_health * 0.55 * LevelScaling.health_mult(p.level), p.global_position)   # George's level scales the creatures live
	check("the Keeper enraged below half health", boss._enraged)
	var before := get_nodes_in_group("enemies").size()
	var called := false
	for i in 80:
		await create_timer(0.25).timeout
		if get_nodes_in_group("enemies").size() > before:
			called = true
			break
	check("...and called burning skeletons (enemies %d -> %d)" % [before, get_nodes_in_group("enemies").size()], called)
	await shot("p4_08_pyrforos_enraged")
	await kill("pyrforos", 1)
	check("the Keeper is dead, hand in at Theofilos: " + states(), q.state["a_boss"] == q.S.READY)
	var finished := [false]
	q.game_finished.connect(func(): finished[0] = true)
	await talk("theofilos", "p4_09_theofilos_end")
	await create_timer(4.5).timeout
	await shot("p4_10_the_end")
	check("part 4 finished: " + states(), q.state["a_boss"] == q.S.DONE and finished[0])
	print("level ", p.level, " gold ", p.gold, " potions ", p.potions)
	quit(1 if failed else 0)
