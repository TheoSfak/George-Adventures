extends SceneTree
## Real first-launch flow (prologue NOT skipped) with simulated key presses:
##   godot --path . --resolution 1920x1080 --script tools/inputtest.gd
func _initialize() -> void:
	_run()
func key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
func _run() -> void:
	await process_frame
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var p := get_first_node_in_group("player") as Player
	var hud := get_first_node_in_group("hud")
	for t in [0.5, 2.0, 4.0]:
		await create_timer(t if t == 0.5 else t - (0.5 if t == 2.0 else 2.0)).timeout
		print("t=%.1f dialogue_open=%s busy=%s" % [t, hud.is_dialogue_open(), p.busy])
	var start := p.global_position
	key(KEY_W, true)
	await create_timer(1.0).timeout
	key(KEY_W, false)
	print("after holding W 1 s: moved %.2f m, busy=%s dialogue=%s" % [p.global_position.distance_to(start), p.busy, hud.is_dialogue_open()])
	for i in 6:
		key(KEY_R, true)
		await create_timer(0.1).timeout
		key(KEY_R, false)
		await create_timer(0.7).timeout
		print("after R #%d: dialogue=%s busy=%s" % [i + 1, hud.is_dialogue_open(), p.busy])
	start = p.global_position
	key(KEY_W, true)
	await create_timer(1.0).timeout
	key(KEY_W, false)
	print("after dialogue, holding W 1 s: moved %.2f m, busy=%s" % [p.global_position.distance_to(start), p.busy])
	# Space must also be able to finish the prologue (fresh game)
	var main2 := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.queue_free()
	await create_timer(0.2).timeout
	root.get_node("/root/Quests").intro_seen = false
	root.add_child(main2)
	await create_timer(3.0).timeout
	var p2 := get_first_node_in_group("player") as Player
	var hud2 := get_first_node_in_group("hud")
	print("fresh game: dialogue=%s busy=%s" % [hud2.is_dialogue_open(), p2.busy])
	for i in 8:
		key(KEY_SPACE, true)
		await create_timer(0.1).timeout
		key(KEY_SPACE, false)
		await create_timer(0.6).timeout
	print("after 8 x Space: dialogue=%s busy=%s" % [hud2.is_dialogue_open(), p2.busy])
	quit()
