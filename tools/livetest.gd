extends SceneTree
## Live check with a real window (inject real key presses from outside):
##   godot --path . --script tools/livetest.gd
## Logs every key the window receives, the player's position, window/audio facts.
var elapsed := 0.0
var log_t := 0.0
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	root.window_input.connect(func(ev):
		if ev is InputEventKey and not ev.echo:
			print("KEY  phys=%s key=%s pressed=%s" % [OS.get_keycode_string(ev.physical_keycode), OS.get_keycode_string(ev.keycode), ev.pressed]))
	print("screen ", DisplayServer.screen_get_size(), " usable ", DisplayServer.screen_get_usable_rect(), " window ", DisplayServer.window_get_size(), " pos ", DisplayServer.window_get_position(), " mode ", DisplayServer.window_get_mode())
	print("audio device '", AudioServer.get_output_device(), "' mix rate ", AudioServer.get_mix_rate(), " devices ", AudioServer.get_output_device_list())
	print("master mute ", AudioServer.is_bus_mute(0), " master db ", AudioServer.get_bus_volume_db(0))
func _process(delta: float) -> bool:
	elapsed += delta
	log_t += delta
	if log_t >= 1.0:
		log_t = 0.0
		var p := get_first_node_in_group("player") as Player
		var hud := get_first_node_in_group("hud")
		var sm = get_first_node_in_group("sound_manager")
		if p != null:
			print("t=%.0f focused=%s pos=(%.1f, %.1f) busy=%s dialogue=%s music=%s musicdb=%.0f" % [elapsed, DisplayServer.window_is_focused(), p.global_position.x, p.global_position.z, p.busy, hud.is_dialogue_open(), sm._music_id if sm else "-", AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Music"), 0)])
	if elapsed > 22.0:
		quit()
	return false
