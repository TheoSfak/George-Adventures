extends SceneTree
## Close-ups of the three bone totems (quest "Τα Οστέινα Τοτέμ") and where each one stands:
##   godot --path . --resolution 1920x1080 --script tools/totemshot.gd -- <outdir>
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
	var q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	dn.running = false
	dn.set_time(12.0)
	p.max_health = 50000.0
	p.health = 50000.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	q.state["totems"] = 2
	q.changed.emit()
	await create_timer(0.5).timeout
	var cam := Camera3D.new()
	cam.fov = 55.0
	main.add_child(cam)
	cam.make_current()
	var i := 0
	for t in get_nodes_in_group("breakables"):
		var pos: Vector3 = t.global_position
		print("totem ", i, " at ", pos, " visible ", t.visible)
		p.teleport(pos + Vector3(0, 0.05, 14), PI)
		await create_timer(0.6).timeout
		for k in 3:
			var angle := TAU * float(k) / 3.0 + 0.6
			var from := pos + Vector3(cos(angle) * 11.0, 2.2, sin(angle) * 11.0)
			cam.global_position = from
			cam.look_at(pos + Vector3(0, 3.0, 0), Vector3.UP)
			await shot("totem_%d_%d" % [i, k])
		# a ray straight down: what is under the totem?
		var space: PhysicsDirectSpaceState3D = main.get_viewport().world_3d.direct_space_state
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(pos + Vector3(0, 30, 0), pos + Vector3(0, -5, 0), 1))
		print("   ground under the totem (collision layer 1) y = ", hit.get("position", Vector3.ZERO).y if not hit.is_empty() else "none")
		i += 1
	quit()
