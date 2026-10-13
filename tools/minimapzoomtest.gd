extends SceneTree
## Minimap zoom buttons (+ / -), the map button and the close button:
##   godot --path . --resolution 1920x1080 --script tools/minimapzoomtest.gd -- <outdir>
var out := "."


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func button(text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if b.text == text and b.is_visible_in_tree():
			return b
	return null


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var p := get_first_node_in_group("player") as Player
	p.teleport(Vector3(0, 0.05, 30), PI)
	var hud := get_first_node_in_group("hud")
	await create_timer(1.0).timeout
	await shot("zoom_0_default")
	for step in 3:
		button("+").pressed.emit()
		await create_timer(0.3).timeout
	await shot("zoom_1_in")
	for step in 6:
		button("−").pressed.emit()
		await create_timer(0.2).timeout
	await shot("zoom_2_out")
	print("buttons: +", button("+") != null, " -", button("−") != null, " M", button("M") != null)
	button("M").pressed.emit()
	await create_timer(0.5).timeout
	print("big map visible after the M button: ", hud._big_map.visible)
	await shot("zoom_3_bigmap")
	button("✕").pressed.emit()
	await create_timer(0.3).timeout
	print("big map visible after the X button: ", hud._big_map.visible)
	# key hotkeys
	var ev := InputEventKey.new()
	ev.keycode = KEY_KP_ADD
	ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.3).timeout
	await shot("zoom_4_after_key")
	quit()
