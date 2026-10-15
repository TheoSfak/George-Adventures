extends SceneTree
## A quick left click swings the sword also while the right mouse button is held (steering), also while moving:
##   godot --path . --headless --script tools/click_attack_test.gd
var failed := false
var p: Player
var swings := 0


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


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


func click(hold: float) -> void:
	mouse(MOUSE_BUTTON_LEFT, true)
	await wait(hold)
	mouse(MOUSE_BUTTON_LEFT, false)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await wait(1.5)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	p = get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	p.attacked.connect(func(_i): swings += 1)
	await wait(0.3)

	# 1. no right button: a quick click swings, a drag does not (as before)
	await click(0.08)
	await wait(0.2)
	check("a quick click swings", swings == 1)
	await wait(1.4)
	swings = 0
	mouse(MOUSE_BUTTON_LEFT, true)
	for i in 6:
		motion(-30, 0)
		await wait(0.02)
	mouse(MOUSE_BUTTON_LEFT, false)
	await wait(0.3)
	check("a left-button drag turns the camera and does not swing", swings == 0)
	await wait(1.2)

	# 2. right button held, standing: the click swings, he does not run off
	swings = 0
	mouse(MOUSE_BUTTON_RIGHT, true)
	await wait(0.2)
	var start := p.global_position
	await click(0.08)
	await wait(0.25)
	check("right button held, quick left click: he swings", swings == 1)
	check("and does not run forward like both buttons do (%.2f m)" % start.distance_to(p.global_position), start.distance_to(p.global_position) < 0.8)
	await wait(1.4)

	# 3. right button held while the mouse steers: the click still swings
	swings = 0
	mouse(MOUSE_BUTTON_LEFT, true)
	for i in 3:
		motion(-40, 0)
		await wait(0.03)
	mouse(MOUSE_BUTTON_LEFT, false)
	await wait(0.25)
	check("the mouse moving while he clicks does not matter", swings == 1)
	await wait(1.4)

	# 4. right button held and moving: he keeps going and the upper body swings
	Input.action_press("move_forward")
	Input.action_press("run")
	await wait(0.8)
	var speed0 := Vector2(p.velocity.x, p.velocity.z).length()
	swings = 0
	await click(0.08)
	await wait(0.12)
	var speed1 := Vector2(p.velocity.x, p.velocity.z).length()
	check("steering and running, a click swings the sword", swings == 1)
	check("he keeps running (%.1f of %.1f m/s)" % [speed1, speed0], speed1 > speed0 * 0.7 and speed1 > 5.0)
	check("with the upper-body layer", p._swing_layer)
	await wait(0.5)
	# the click again and again: the combo continues
	swings = 0
	for i in 3:
		await click(0.06)
		await wait(0.3)
	check("clicking again and again chains the hits (%d)" % swings, swings >= 3)
	Input.action_release("move_forward")
	Input.action_release("run")
	mouse(MOUSE_BUTTON_RIGHT, false)
	await wait(1.2)

	# 5. both buttons held: still runs forward and does not swing
	swings = 0
	var s2 := p.global_position
	mouse(MOUSE_BUTTON_LEFT, true)
	mouse(MOUSE_BUTTON_RIGHT, true)
	await wait(1.0)
	var ran := s2.distance_to(p.global_position)
	mouse(MOUSE_BUTTON_LEFT, false)
	mouse(MOUSE_BUTTON_RIGHT, false)
	await wait(0.3)
	check("both buttons held run forward (%.1f m)" % ran, ran > 3.0)
	check("and holding is not a swing", swings == 0)
	quit(1 if failed else 0)
