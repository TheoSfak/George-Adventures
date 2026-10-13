extends SceneTree
## The graphics row of the settings page:
##   godot --path . --resolution 1280x720 --script tools/graphicsmenutest.gd -- <outdir>
var out := "."
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func find_option(node: Node) -> OptionButton:
	for c in node.find_children("*", "OptionButton", true, false):
		if (c as OptionButton).item_count == 3 and (c as OptionButton).get_item_text(0) == Strings.GFX_HIGH:
			return c
	return null


func find_button(node: Node, text: String) -> BaseButton:
	for c in node.find_children("*", "BaseButton", true, false):
		if (c as BaseButton).get("text") == text and (c as BaseButton).is_visible_in_tree():
			return c
	return null


func has_label(node: Node, text: String) -> bool:
	for c in node.find_children("*", "Label", true, false):
		if (c as Label).text == text and (c as Label).is_visible_in_tree():
			return true
	return false


func _run() -> void:
	await process_frame
	GameSettings.ensure_loaded()
	GameSettings.check_updates = false              # no network in tests
	var save = load("res://scripts/save_game.gd")
	save.menu_in_tests = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var menu = get_first_node_in_group("game_menu")
	menu._show_page(1)                                # settings
	await create_timer(0.4).timeout
	var option := find_option(menu)
	check("the graphics drop-down has three entries", option != null)
	check("the heading is there", has_label(menu, Strings.SET_GRAPHICS))
	var apply := find_button(menu, Strings.GFX_APPLY)
	check("the apply button is there", apply != null)
	if option == null or apply == null:
		quit(1)
		return
	var ids := GraphicsMode.ids()
	check("it starts on the renderer in use (%s)" % GraphicsMode.current(), ids[option.selected] == GraphicsMode.current())
	check("the entries are the three Greek labels", option.get_item_text(1) == Strings.GFX_MEDIUM and option.get_item_text(2) == Strings.GFX_COMPAT)
	check("apply is disabled while nothing changed", apply.disabled)
	check("the description of the current mode is shown", has_label(menu, GraphicsMode.description(GraphicsMode.current())))
	await shot("gfx_0_settings")
	# choose another mode
	var other := 1 if ids[option.selected] != "mobile" else 0
	option.select(other)
	option.item_selected.emit(other)
	await create_timer(0.2).timeout
	check("apply is enabled for another mode", not apply.disabled)
	check("the description follows the choice", has_label(menu, GraphicsMode.description(ids[other])))
	# pressing apply outside the exported game explains and writes nothing
	var exe_dir := GraphicsMode.exe_dir()
	var before := FileAccess.file_exists(exe_dir.path_join("override.cfg"))
	apply.pressed.emit()
	await create_timer(0.3).timeout
	check("the editor message is shown", has_label(menu, Strings.GFX_ERR_EDITOR))
	check("no override.cfg was written next to the editor", FileAccess.file_exists(exe_dir.path_join("override.cfg")) == before)
	check("the game keeps running", get_first_node_in_group("game_menu") != null)
	await shot("gfx_1_editor_message")
	# the page still fits: the key list is reachable and the back button is visible
	check("the back button is visible", find_button(menu, Strings.MENU_BACK) != null)
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
