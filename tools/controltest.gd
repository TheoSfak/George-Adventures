extends SceneTree
## Checks the WoW-style controls with simulated input:
##   godot --path . --resolution 1280x720 --script tools/controltest.gd -- <outdir>
var out := "."
var p: Player


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run()


func act(action: String, down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	Input.parse_input_event(ev)


func mouse(button: MouseButton, down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = down
	ev.position = Vector2(640, 360)
	Input.parse_input_event(ev)


func motion(dx: float, dy: float = 0.0) -> void:
	var ev := InputEventMouseMotion.new()
	ev.relative = Vector2(dx, dy)
	ev.position = Vector2(640, 360)
	Input.parse_input_event(ev)


func wait(t: float) -> void:
	await create_timer(t).timeout


func heading_deg() -> float:
	return fposmod(rad_to_deg(p._heading), 360.0)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	# keep skeletons out of the way for movement tests
	await wait(1.2)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	p = get_first_node_in_group("player") as Player
	await wait(0.3)
	print("cursor mode at start (0=visible,2=captured): ", Input.mouse_mode)

	# 1. A turns George, camera follows
	var h0 := heading_deg()
	act("turn_left", true)
	await wait(0.5)
	act("turn_left", false)
	print("1) turn_left 0.5s: heading ", snappedf(h0, 0.1), " -> ", snappedf(heading_deg(), 0.1), " (expect ~-86deg change: turning left = heading decreases by 3*0.5 rad)")

	# 2. W walks along heading
	var pos0 := p.global_position
	act("move_forward", true)
	await wait(0.8)
	act("move_forward", false)
	var d := p.global_position - pos0
	var f := Vector3(sin(p._heading), 0, cos(p._heading))
	print("2) forward: moved ", snappedf(d.length(), 0.1), " m, alignment with heading ", snappedf(d.normalized().dot(f), 0.01), " (expect ~1)")
	await wait(0.4)

	# 3. Right mouse + mouse move turns character and camera; A/D strafe
	mouse(MOUSE_BUTTON_RIGHT, true)
	await wait(0.1)
	print("3) cursor mode while RMB held (expect 2): ", Input.mouse_mode)
	var yaw0 := p._yaw
	var h1 := heading_deg()
	print("   dbg pre-motion yaw ", rad_to_deg(p._yaw), " heading ", heading_deg())
	for i in 10:
		motion(30)
		await wait(0.02)
		print("   dbg i=", i, " yaw ", snappedf(rad_to_deg(p._yaw), 0.1))
	await wait(0.2)
	print("   dbg settled yaw ", rad_to_deg(p._yaw))
	print("   RMB mouse move: camera yaw changed ", snappedf(rad_to_deg(p._yaw - yaw0), 0.1), "deg, heading ", snappedf(h1, 0.1), " -> ", snappedf(heading_deg(), 0.1), " (should match camera)")
	pos0 = p.global_position
	act("turn_right", true)
	await wait(0.6)
	act("turn_right", false)
	d = p.global_position - pos0
	var r := Vector3(-cos(p._heading), 0, sin(p._heading))
	print("   D while RMB strafes right: moved ", snappedf(d.length(), 0.1), " m, alignment with right vector ", snappedf(d.normalized().dot(r), 0.01), ", heading unchanged by D: ", snappedf(heading_deg(), 0.1))
	await shot("ctl_rmb")
	mouse(MOUSE_BUTTON_RIGHT, false)
	await wait(0.2)
	print("   cursor mode after release (expect 0): ", Input.mouse_mode)

	# 4. Left mouse drag orbits camera but does not turn George
	var h2 := p._heading
	var y2 := p._yaw
	mouse(MOUSE_BUTTON_LEFT, true)
	await wait(0.1)
	for i in 10:
		motion(-30, 4)
		await wait(0.02)
	var turned := rad_to_deg(p._yaw - y2)
	await wait(0.2)
	print("4) LMB drag: camera yaw changed ", snappedf(turned, 0.1), "deg, George heading changed ", snappedf(rad_to_deg(p._heading - h2), 0.1), "deg (expect 0), attack queued: ", p._attack_queued)
	mouse(MOUSE_BUTTON_LEFT, false)
	await wait(0.15)
	print("   after drag release, attacking? ", p._attacking, " (expect false)")
	await wait(1.2)

	# 5. Quick left click = attack
	mouse(MOUSE_BUTTON_LEFT, true)
	await wait(0.08)
	mouse(MOUSE_BUTTON_LEFT, false)
	await wait(0.15)
	print("5) quick LMB click: attacking? ", p._attacking, " (expect true)")
	await wait(1.4)

	# 6. Both buttons run forward
	pos0 = p.global_position
	mouse(MOUSE_BUTTON_LEFT, true)
	mouse(MOUSE_BUTTON_RIGHT, true)
	await wait(0.8)
	mouse(MOUSE_BUTTON_LEFT, false)
	mouse(MOUSE_BUTTON_RIGHT, false)
	d = p.global_position - pos0
	f = Vector3(sin(p._heading), 0, cos(p._heading))
	print("6) both buttons: moved ", snappedf(d.length(), 0.1), " m, alignment ", snappedf(d.normalized().dot(f), 0.01), " (expect ~1, and nonzero)")

	# 7. S walks backwards slower
	pos0 = p.global_position
	act("move_back", true)
	await wait(0.8)
	act("move_back", false)
	d = p.global_position - pos0
	print("7) backward: moved ", snappedf(d.length(), 0.1), " m in 0.8s, dot with facing ", snappedf(d.normalized().dot(f), 0.01), " (expect negative)")

	# 8. Wheel zoom
	var len0 := p._arm.spring_length
	var w := InputEventMouseButton.new()
	w.button_index = MOUSE_BUTTON_WHEEL_UP
	w.pressed = true
	Input.parse_input_event(w)
	await wait(0.1)
	print("8) wheel up: spring length ", len0, " -> ", p._arm.spring_length)
	await shot("ctl_end")
	quit()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
