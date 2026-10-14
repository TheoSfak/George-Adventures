extends SceneTree
## The bandits' hideout and the four bandit types, screenshots and frame rate:
##   godot --path . --resolution 1920x1080 --script tools/banditshot.gd -- <outdir> [night]
## George stays at the village so nobody attacks while a free camera takes the pictures.
var out := "."
var night := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	night = args.size() > 1 and args[1] == "night"
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _look(cam: Camera3D, target: Vector3, from: Vector3) -> void:
	cam.global_position = from
	cam.look_at(target, Vector3.UP)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var dn := get_first_node_in_group("daynight") as DayNight
	dn.running = false
	dn.set_time(22.0 if night else 12.0)
	var p := get_first_node_in_group("player") as Player
	p.max_health = 50000.0
	p.health = 50000.0
	var cam := Camera3D.new()
	cam.fov = 60.0
	main.add_child(cam)
	cam.make_current()
	var c := Vector3(-140.0, 0.0, -90.0)
	var tag := "night_" if night else ""

	# the camp from the mill side, from above, and from the north
	_look(cam, c + Vector3(0, 2.0, 0), c + Vector3(26.0, 9.0, 22.0))
	await shot(tag + "bandit_camp_a")
	await create_timer(1.5).timeout
	print("fps at the camp: ", Engine.get_frames_per_second())
	_look(cam, c + Vector3(0, 1.0, 0), c + Vector3(-4.0, 34.0, 20.0))
	await shot(tag + "bandit_camp_top")
	_look(cam, c + Vector3(0, 2.0, 0), c + Vector3(-12.0, 6.0, -28.0))
	await shot(tag + "bandit_camp_north")

	# the four types, one by one
	var seen := {}
	for e in get_nodes_in_group("enemies"):
		var k := String(e.kind_id)
		if k.begins_with("bandit") and not seen.has(k) and e.global_position.distance_to(c) < 30.0:
			seen[k] = e
	for k in seen:
		var e = seen[k]
		var at: Vector3 = e.global_position
		var dist := 8.0 if k == "bandit_chief" else 5.0
		_look(cam, at + Vector3(0, 1.4 * e.model_scale, 0), at + Vector3(dist * 0.6, 2.0 * e.model_scale + 0.6, dist))
		await shot(tag + k)
	# the signpost on the way from the mill
	_look(cam, Vector3(-118, 3.5, -74), Vector3(-104, 5.0, -62))
	await shot(tag + "bandit_sign")
	# the map
	cam.queue_free()
	for cc in p.find_children("*", "Camera3D", true, false):
		(cc as Camera3D).make_current()
	get_first_node_in_group("hud").toggle_big_map()
	await create_timer(0.5).timeout
	await shot(tag + "bandit_map")
	get_first_node_in_group("hud").toggle_big_map()
	print("types seen: ", seen.keys())
	quit()
