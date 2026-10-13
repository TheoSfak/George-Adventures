extends SceneTree
## The pass gate, entering and leaving the Frontier region:
##   godot --path . --headless --script tools/frontier_enter_test.gd
var failed := false
var p: Player
var q: Node
var interiors


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func gate_spot() -> InteractSpot:
	var fr = load("res://scripts/frontier.gd")
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.global_position.distance_to(fr.VILLAGE_GATE + Vector3(0, 0, 3)) < 2.0:
			return n
	return null


func _run() -> void:
	await process_frame
	var fr = load("res://scripts/frontier.gd")
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0

	var spot := gate_spot()
	check("the pass gate exists in the village", spot != null)
	if spot == null:
		quit(1)
		return
	check("sealed prompt before the quest", spot.interact_prompt().contains(Strings.FRONTIER_SEALED))
	spot.interact(p)
	await create_timer(0.6).timeout
	check("a sealed gate does not let George through", not interiors.in_region())

	q.state["f_gate"] = q.S.ACTIVE
	check("open prompt after the quest", spot.interact_prompt().contains(Strings.BUILDING_NAMES["frontier"]))
	# while the village is attacked George cannot leave it
	var invasion = get_first_node_in_group("invasion")
	invasion.start(1)
	check("an invasion is running", invasion.active)
	spot.interact(p)
	await create_timer(0.6).timeout
	check("George cannot leave while the village is attacked", not interiors.in_region())
	invasion._on_dawn()
	check("the invasion ended", not invasion.active)
	spot.interact(p)
	for i in 100:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	check("George is in the region", interiors.in_region() and not interiors.is_inside())
	check("the region kind is frontier", interiors.current_kind == "frontier")
	var spawn: Vector3 = fr.wp(fr.ENTRY.x, fr.ENTRY.y, 0.05)
	check("he stands at the entry (%s)" % str(p.global_position), p.global_position.distance_to(spawn) < 1.5)
	check("the sun is still on (outdoor)", (root.find_child("Sun", true, false) as Light3D).visible)
	check("the quest 'arrive' objective counted", q.state["f_gate"] == q.S.READY)
	check("the level node exists", get_first_node_in_group("frontier") != null)

	# back out through the arch
	var exit_spot: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_FRONTIER_BACK:
			exit_spot = n
	check("there is a way back", exit_spot != null)
	p.teleport(exit_spot.global_position, PI)
	exit_spot.interact(p)
	for i in 100:
		await create_timer(0.1).timeout
		if not interiors.in_region() and not p.busy:
			break
	check("George is back in the village", not interiors.in_region() and p.global_position.distance_to(fr.VILLAGE_GATE) < 12.0)

	# a second visit reuses the level
	spot.interact(p)
	for i in 100:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	check("second visit works", interiors.in_region())
	check("only one Frontier node exists", get_nodes_in_group("frontier").size() == 1)
	quit(1 if failed else 0)
