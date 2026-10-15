extends SceneTree
## The horse pill in the corner panel (before and after buying the horse, riding) and the controls page ("i"):
##   godot --path . --resolution 1920x1080 --script tools/mountuishot.gd -- <outdir> [help]
## With "help" only the controls page is shot (the game menu is switched on for that).
var out := "."
var help_only := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	help_only = args.size() > 1 and args[1] == "help"
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	if help_only:
		load("res://scripts/save_game.gd").menu_in_tests = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	if help_only:
		var menu = get_first_node_in_group("game_menu")
		menu._title = false                  # the title menu is up at the start: close it, then open the page like the "i" button does
		menu._close_menu()
		await create_timer(0.3).timeout
		menu.open_help()
		await create_timer(0.6).timeout
		await shot("mountui_help_page")
		quit()
		return
	var p := get_first_node_in_group("player") as Player
	var hud = get_first_node_in_group("hud")
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.4).timeout
	p.gold = 123
	p.inventory_changed.emit(p.gold, p.potions)
	await create_timer(0.3).timeout
	await shot("mountui_1_no_horse")
	p.horse_owned = true
	await create_timer(0.4).timeout
	await shot("mountui_2_owned")
	p.mount()
	await create_timer(0.8).timeout
	await shot("mountui_3_riding")
	p.dismount()
	quit()
