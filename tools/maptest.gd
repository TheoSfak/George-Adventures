extends SceneTree
## Map screenshots:  godot --path . --resolution 1280x720 --script tools/maptest.gd -- <outdir>
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
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
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var hud := get_first_node_in_group("hud") as CanvasLayer
	print("enemies: ", get_nodes_in_group("enemies").size(), "  interactables: ", get_nodes_in_group("interactables").size())

	# top-down overview
	hud.visible = false
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 560.0
	cam.far = 2000.0
	cam.position = Vector3(0, 800, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(cam)
	cam.make_current()
	await create_timer(1.0).timeout
	await shot("map_top")
	cam.queue_free()
	hud.visible = true

	# ground-level views: [name, x, z, heading in degrees (180 = looking north)]
	for v in [["view_well", 0.0, 22.0, 180.0], ["view_church", 0.0, -40.0, 180.0], ["view_tavern", -40.0, -10.0, 90.0],
			["view_camp", -140.0, 20.0, 90.0], ["view_quarry", 105.0, 100.0, 300.0], ["view_crypt_gate", 0.0, -128.0, 180.0],
			["view_crypt", 0.0, -160.0, 180.0]]:
		p.teleport(Vector3(v[1], 0.05, v[2]), deg_to_rad(v[3]))
		await create_timer(1.2).timeout
		await shot(v[0])
	quit()
