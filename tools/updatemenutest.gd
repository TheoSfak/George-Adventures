extends SceneTree
## The update panel, version label, creators line, Credits page and settings checkbox:
##   godot --path . --resolution 1280x720 --script tools/updatemenutest.gd -- <outdir>
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


## The first Button / CheckBox under `node` whose text is `text`.
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
	var had_settings := FileAccess.file_exists(GameSettings.PATH)
	var settings_backup := FileAccess.get_file_as_bytes(GameSettings.PATH) if had_settings else PackedByteArray()
	var save = load("res://scripts/save_game.gd")
	save.menu_in_tests = true
	GameSettings.ensure_loaded()
	GameSettings.check_updates = false              # no network in tests
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var menu = get_first_node_in_group("game_menu")
	check("title menu is open", menu != null and paused)
	var u: Updater = menu._updater
	check("the updater exists and did not check (flag off)", u != null and u.state == Updater.State.NONE)
	check("creators line is shown", has_label(menu, Strings.CREDITS_CREATORS_LINE))
	check("version label is shown", has_label(menu, Strings.VERSION_LABEL % Updater.current_version()))
	check("no update panel without an update", find_button(menu, Strings.UPDATE_BUTTON) == null)
	await shot("update_0_title")

	# an available update
	u.release = {"version": "1.1.0", "tag": "v1.1.0", "notes": "## Novo\n- Prwto\n- Deftero", "page_url": Updater.PAGE_URL,
		"zip_url": "", "zip_name": "", "zip_size": 1000, "sha_url": ""}
	u._set_state(Updater.State.AVAILABLE)
	await create_timer(0.3).timeout
	check("panel shows the new version", has_label(menu, Strings.UPDATE_AVAILABLE % "1.1.0"))
	check("panel has the update button", find_button(menu, Strings.UPDATE_BUTTON) != null)
	await shot("update_1_available")
	find_button(menu, Strings.UPDATE_LATER).pressed.emit()
	await create_timer(0.2).timeout
	check("Later hides the panel", find_button(menu, Strings.UPDATE_BUTTON) == null)
	# progress
	menu._update_hidden = false
	u._set_state(Updater.State.DOWNLOADING)
	await create_timer(0.2).timeout
	u.progress.emit(0.34)
	await create_timer(0.2).timeout
	check("progress text", has_label(menu, Strings.UPDATE_DOWNLOADING % 34))
	await shot("update_2_downloading")
	# failure
	u.error_text = Strings.UPDATE_ERR_CHECKSUM
	u._set_state(Updater.State.FAILED)
	await create_timer(0.2).timeout
	check("failure message shown", has_label(menu, Strings.UPDATE_ERR_CHECKSUM))
	check("open-page button shown", find_button(menu, Strings.UPDATE_OPEN_PAGE) != null)
	await shot("update_3_failed")
	menu._update_hidden = true
	menu._show_page(0)

	# credits
	find_button(menu, Strings.MENU_CREDITS).pressed.emit()
	await create_timer(0.3).timeout
	check("credits page is open (page 3)", menu._page == 3)
	check("credits show the creators", has_label(menu, "Theodore Sfakianakis & George Sfakianakis"))
	await shot("update_4_credits")
	menu.toggle_pause()                              # Esc: back to the main page
	await create_timer(0.2).timeout
	check("Esc returns to the main page", menu._page == 0)

	# settings checkbox
	menu._show_page(1)
	await create_timer(0.3).timeout
	var box := find_button(menu, Strings.SET_UPDATES) as CheckBox
	check("settings has the update checkbox", box != null)
	await shot("update_5_settings")
	if box != null:
		check("checkbox reflects the flag (off)", not box.button_pressed)
		box.button_pressed = true
		check("toggling it turns the flag on", GameSettings.check_updates)
		box.button_pressed = false
		check("...and off again", not GameSettings.check_updates)
	# restore the real settings file
	if had_settings:
		var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		f.store_buffer(settings_backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
