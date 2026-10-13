extends SceneTree
## Compact action bar, the "i" button and the controls help page:
##   godot --path . --resolution 1920x1080 --script tools/uishot4.gd -- <outdir>
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


func _run() -> void:
	await process_frame
	var save = load("res://scripts/save_game.gd")
	save.menu_in_tests = true
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var menu = get_first_node_in_group("game_menu")
	menu._title = false                      # skip the title screen without touching the save file
	menu._close_menu()
	var p := get_first_node_in_group("player") as Player
	var hud := get_first_node_in_group("hud")
	p.gain_xp(400)
	p.collect("potion", 3)
	p.teleport(Vector3(0, 0.05, 30), PI)
	await create_timer(7.0).timeout
	await shot("ui4_1_compact_bar")
	hud._open_help()
	await create_timer(0.5).timeout
	print("help open: paused=", paused, " page=", menu._page, " from_hud=", menu._help_from_hud)
	await shot("ui4_2_help")
	menu.toggle_pause()                      # Esc: closes it again
	await create_timer(0.3).timeout
	print("after Esc: paused=", paused, " open=", menu._open)
	# the same page from the pause menu
	menu.toggle_pause()
	await create_timer(0.3).timeout
	await shot("ui4_3_pause_menu")
	menu._show_page(2)
	await create_timer(0.3).timeout
	menu.toggle_pause()                      # Esc on the help page goes back to the pause menu
	print("Esc on help (from the menu): page=", menu._page, " (0 = main) open=", menu._open)
	quit()
