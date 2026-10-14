extends SceneTree
## The rescue event: the alert card, the ring around Andreas, the bar, the map, the fight:
##   godot --path . --resolution 1920x1080 --script tools/rescueshot.gd -- <outdir>
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


func _look(cam: Camera3D, target: Vector3, from: Vector3) -> void:
	cam.global_position = from
	cam.look_at(target, Vector3.UP)


func _alert_card() -> Node:
	for c in get_first_node_in_group("hud").get_children():
		if c.get_script() != null and c.get_script().get_global_name() == &"RescueAlert":
			return c
	return null


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	dn.running = false
	dn.set_time(12.0)
	p.max_health = 50000.0
	p.health = 50000.0
	var r = get_first_node_in_group("rescue")
	r.set_process(false)

	# the alert card
	r.trigger_now()
	await create_timer(0.6).timeout
	await shot("rescue_alert")
	_alert_card()._accept()
	await create_timer(0.8).timeout

	# the minimap arrow while George is still far away (a close-up of the corner, 2x)
	await shot("rescue_arrow_far")
	var corner := root.get_viewport().get_texture().get_image().get_region(Rect2i(1530, 20, 390, 330))
	corner.resize(corner.get_width() * 2, corner.get_height() * 2, Image.INTERPOLATE_LANCZOS)
	corner.save_png("%s/rescue_arrow_corner.png" % out)

	# the ring from a free camera, then with the HUD and the map
	var site := Vector3(r.SITE.x, 0.0, r.SITE.y)
	var cam := Camera3D.new()
	cam.fov = 60.0
	main.add_child(cam)
	cam.make_current()
	p.teleport(site + Vector3(-30.0, 0.05, 0.0), -PI / 2.0)
	await create_timer(0.6).timeout
	_look(cam, site + Vector3(0, 1.2, 0), site + Vector3(-9.0, 4.0, 3.0))
	await shot("rescue_ring_near")
	_look(cam, site + Vector3(0, 1.2, 0), site + Vector3(-22.0, 9.0, 12.0))
	await shot("rescue_ring_far")
	r.step(70.0)
	await create_timer(0.4).timeout
	_look(cam, site + Vector3(0, 1.8, 0), site + Vector3(-5.5, 2.6, 1.0))
	await shot("rescue_bar_low")
	cam.queue_free()
	for c in p.find_children("*", "Camera3D", true, false):
		(c as Camera3D).make_current()
	await create_timer(0.3).timeout
	await shot("rescue_hud")

	# the big map
	get_first_node_in_group("hud").toggle_big_map()
	await create_timer(0.5).timeout
	await shot("rescue_map")
	get_first_node_in_group("hud").toggle_big_map()

	# George runs in and fights
	p.teleport(site + Vector3(-14.0, 0.05, 0.0), -PI / 2.0)
	await create_timer(1.0).timeout
	Input.action_press("move_forward")
	Input.action_press("run")
	await create_timer(1.8).timeout
	Input.action_release("move_forward")
	Input.action_release("run")
	await shot("rescue_fight")
	print("besiegers chasing George: ", get_nodes_in_group("besiegers").filter(func(e): return not e.is_besieging() and not e.is_dead()).size(),
			"  fps: ", Engine.get_frames_per_second())
	quit()
