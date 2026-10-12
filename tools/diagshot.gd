extends SceneTree
## Shows the F12 diagnostics overlay:  godot --path . --resolution 1920x1080 --script tools/diagshot.gd -- <outdir>
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
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.0).timeout
	key(KEY_F12, true)
	await create_timer(0.1).timeout
	key(KEY_F12, false)
	key(KEY_W, true)
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/diag.png")
	key(KEY_W, false)
	quit()
