extends SceneTree
## Interior at night:  godot --path . --resolution 1280x720 --script tools/nightinterior.gd -- <outdir>
var out := "."
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	_run()
func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	for e in get_nodes_in_group("enemies"): e.queue_free()
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight")
	dn.running = false
	dn.set_time(22.0)
	var env: Environment = main.get_node("WorldEnvironment").environment
	var sun: Light3D = main.get_node("Sun")
	var moon: Light3D = main.get_node("Moon")
	await create_timer(1.0).timeout
	print("outside: sun visible ", sun.visible, " moon visible ", moon.visible, " bg ", env.background_mode, " ambient src ", env.ambient_light_source)
	var interiors := get_first_node_in_group("interiors")
	interiors.enter("tavern_1", "tavern", Vector3(-45, 0, -9.8), 1.57, p)
	await create_timer(1.5).timeout
	print("inside: inside ", interiors.is_inside(), " sun visible ", sun.visible, " moon visible ", moon.visible, " bg ", env.background_mode, " ambient src ", env.ambient_light_source, " energy ", env.ambient_light_energy)
	await shot("night_inside")
	interiors._exit_room("tavern_1", p)
	await create_timer(1.5).timeout
	print("outside again: inside ", interiors.is_inside(), " sun visible ", sun.visible, " moon visible ", moon.visible, " bg ", env.background_mode, " ambient src ", env.ambient_light_source, " energy ", env.ambient_light_energy)
	await shot("night_outside_again")
	quit()
