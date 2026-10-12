extends SceneTree
## Title and pause menus:  godot --path . --resolution 1920x1080 --script tools/menutest.gd -- <outdir>
var out := "."
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	_run()
func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
func _run() -> void:
	await process_frame
	var save = load("res://scripts/save_game.gd")
	save.menu_in_tests = true
	var quests := root.get_node("/root/Quests")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var menu = get_first_node_in_group("game_menu")
	print("menu present: ", menu != null, "  paused: ", paused, "  save exists: ", save.exists())
	await shot("menu_title")
	menu._show_page(1)                       # settings
	await create_timer(0.3).timeout
	await shot("menu_settings")
	menu._show_page(0)
	print("-- Continue")
	menu._continue_game()
	await create_timer(0.5).timeout
	var p := get_first_node_in_group("player") as Player
	print("after Continue: paused=", paused, " level ", p.level, " gold ", p.gold)
	# Esc opens the pause menu
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await create_timer(0.4).timeout
	print("after Esc: paused=", paused)
	await shot("menu_pause")
	menu.toggle_pause()
	await create_timer(0.3).timeout
	print("after Esc again: paused=", paused)
	# New game from a fresh title is exercised separately; check the key rebinding API
	var settings = load("res://scripts/game_settings.gd")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_UP
	settings.rebind("jump", ev)
	print("jump re-bound to: ", settings.key_name("jump"), "  (file: ", settings.PATH, ")")
	settings.reset_keys()
	print("jump after reset: ", settings.key_name("jump"))
	quit()
