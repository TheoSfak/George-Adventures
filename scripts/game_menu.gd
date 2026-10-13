class_name GameMenu
extends CanvasLayer
## The title menu (shown when the game starts) and the pause menu (Esc). Both pause the game.
##   Title:  Συνέχεια / Νέο παιχνίδι / Ρυθμίσεις / Έξοδος
##   Pause:  Επιστροφή / Αποθήκευση / Ρυθμίσεις / Κεντρικό μενού / Έξοδος
## Settings: volumes, audio device and key re-binding (game_settings.gd).
## Also autosaves on quest completion, level up and at dawn (save_game.gd).

enum Page { MAIN, SETTINGS, HELP, CREDITS }

var _title := true                   # the title menu (true) or the pause menu (false)
var _open := false
var _page := Page.MAIN
var _confirm_new := false
var _help_from_hud := false         # the help page was opened with the "i" button / F1: Back closes the menu
var _capturing := ""                 # action waiting for a key press in the settings window
var _key_buttons := {}
var _dim: ColorRect
var _title_label: Label
var _panel: PanelContainer
var _box: VBoxContainer
var _player: Player
var _hud: Node
var _updater: Updater
var _update_hidden := false          # "Αργότερα" was pressed: no panel until the next start
var _update_card: PanelContainer     # the update panel, top right of the title screen
var _update_bar: FancyBar
var _update_label: Label
var _creators_label: Label
var _version_label: Label


func _ready() -> void:
	# Only in the real game: test drivers add the scene by hand and expect to start playing.
	if get_tree().current_scene != get_parent() and not SaveGame.menu_in_tests:
		queue_free()
		return
	add_to_group("game_menu")
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_root()
	_updater = Updater.new()
	add_child(_updater)
	_updater.state_changed.connect(_on_update_state)
	_updater.progress.connect(_on_update_progress)
	_hud = get_tree().get_first_node_in_group("hud")
	_player = get_tree().get_first_node_in_group("player") as Player
	await get_tree().process_frame
	match SaveGame.start_action:
		"continue":
			SaveGame.start_action = ""
			_continue_game()
		"new":
			SaveGame.start_action = ""
			_new_game()
		_:
			_show_title()
			_updater.check()
	var quests := Quests
	quests.quest_done.connect(func(_id): autosave())
	if _player:
		_player.leveled_up.connect(func(_l): autosave())
	var daynight := get_tree().get_first_node_in_group("daynight") as DayNight
	if daynight:
		daynight.dawn_started.connect(autosave)


# ------------------------------------------------------------------- layout ----

func _build_root() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.015, 0.01, 0.62)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	add_child(_dim)
	_title_label = UiKit.label(Strings.TITLE, 46, UiKit.GOLD_TEXT)
	_title_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title_label.offset_top = 70.0
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_constant_override("outline_size", 10)
	_dim.add_child(_title_label)
	_creators_label = UiKit.label(Strings.CREDITS_CREATORS_LINE, 15, UiKit.MUTED)
	_creators_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_creators_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_creators_label.offset_left = 22.0
	_creators_label.offset_bottom = -14.0
	_dim.add_child(_creators_label)
	_version_label = UiKit.label(Strings.VERSION_LABEL % Updater.current_version(), 15, UiKit.MUTED)
	_version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_version_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_version_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_version_label.offset_right = -22.0
	_version_label.offset_bottom = -14.0
	_dim.add_child(_version_label)
	_update_card = PanelContainer.new()
	_update_card.add_theme_stylebox_override("panel", UiKit.panel_style(0.94))
	_update_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_update_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_update_card.offset_right = -22.0
	_update_card.offset_top = 160.0                # beside the buttons, below the title
	_update_card.visible = false
	_dim.add_child(_update_card)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.panel_style(0.94))
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_dim.add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_panel.add_child(_box)


func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_key_buttons.clear()
	_update_bar = null
	_update_label = null


func _menu_button(text: String, callback: Callable, disabled := false) -> Button:
	var b := UiKit.button(text, callback, 340.0, 22)
	b.custom_minimum_size.y = 46
	b.disabled = disabled
	_box.add_child(b)
	return b


func _heading(text: String) -> void:
	var l := UiKit.label(text, 24, UiKit.GOLD_TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(l)


# -------------------------------------------------------------------- pages ----

func _show_title() -> void:
	_title = true
	_open_menu()
	_show_page(Page.MAIN)


func toggle_pause() -> void:
	if _open:
		if _page == Page.HELP and _help_from_hud:
			_close_menu()
		elif _page != Page.MAIN:
			_show_page(Page.MAIN)
		elif not _title:
			_close_menu()
		return
	_title = false
	_open_menu()
	_show_page(Page.MAIN)


## The controls help page, opened from the HUD ("i" button or F1). Pauses the game like the menu.
func open_help() -> void:
	if _open or _title or (_player != null and _player.busy):
		return
	_title = false
	_help_from_hud = true
	_open_menu()
	_show_page(Page.HELP)


func _open_menu() -> void:
	_open = true
	_dim.visible = true
	_title_label.visible = _title
	get_tree().paused = true
	if _hud:
		_hud.visible = not _title


func _close_menu() -> void:
	_open = false
	_help_from_hud = false
	_dim.visible = false
	_capturing = ""
	get_tree().paused = false
	if _hud:
		_hud.visible = true
	Sfx.ui("window_close")


func _show_page(page: Page) -> void:
	_page = page
	_confirm_new = false
	_title_label.visible = _title and page == Page.MAIN
	_creators_label.visible = _title and page == Page.MAIN
	_version_label.visible = _title and page == Page.MAIN
	_update_card.visible = false
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.custom_minimum_size = Vector2.ZERO
	_clear()
	if page == Page.MAIN:
		_help_from_hud = false
	if page == Page.SETTINGS:
		_build_settings()
	elif page == Page.HELP:
		_build_help()
	elif page == Page.CREDITS:
		_build_credits()
	elif _title:
		_build_title_page()
	else:
		_build_pause_page()


func _build_title_page() -> void:
	# the buttons hang from just below the title (six of them no longer fit centred under it)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.grow_vertical = Control.GROW_DIRECTION_END
	_panel.offset_left = -200.0                # a fixed 400 px wide column, independent of the last layout
	_panel.offset_right = 200.0
	_panel.offset_top = 150.0
	_panel.offset_bottom = 150.0
	_panel.custom_minimum_size.x = 400.0
	_panel.reset_size.call_deferred()          # the height follows the buttons added below
	_build_update_panel()
	var has_save := SaveGame.exists() and not SaveGame.read().is_empty()
	_menu_button(Strings.MENU_CONTINUE, _continue_game, not has_save)
	if has_save:
		var info := UiKit.label(SaveGame.summary(), 16, UiKit.MUTED)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(info)
	if _confirm_new:
		_box.add_child(UiKit.paragraph(Strings.MENU_NEW_SURE, 17, 340.0, UiKit.BAD))
		_menu_button(Strings.MENU_YES, _new_game)
		_menu_button(Strings.MENU_NO, func(): _show_page(Page.MAIN))
	else:
		_menu_button(Strings.MENU_NEW, func():
			if has_save:
				_confirm_new = true
				_clear()
				_build_title_page()
			else:
				_new_game())
	_menu_button(Strings.MENU_SETTINGS, func(): _show_page(Page.SETTINGS))
	_menu_button(Strings.MENU_CONTROLS, func(): _show_page(Page.HELP))
	_menu_button(Strings.MENU_CREDITS, func(): _show_page(Page.CREDITS))
	_menu_button(Strings.MENU_QUIT, func(): get_tree().quit())


## The update card in the top right corner of the title screen (nothing while there is no update
## or after "Αργότερα").
func _build_update_panel() -> void:
	for c in _update_card.get_children():
		_update_card.remove_child(c)
		c.queue_free()
	_update_card.visible = false
	if _updater == null or _update_hidden:
		return
	var st := _updater.state
	if st == Updater.State.IDLE or st == Updater.State.CHECKING or st == Updater.State.NONE:
		return
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_update_card.add_child(v)
	_update_card.visible = true
	match st:
		Updater.State.AVAILABLE:
			var head := UiKit.label(Strings.UPDATE_AVAILABLE % String(_updater.release.get("version", "")), 21, UiKit.GOLD_TEXT)
			head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(head)
			var cur := UiKit.label(Strings.UPDATE_CURRENT % Updater.current_version(), 14, UiKit.MUTED)
			cur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(cur)
			var notes := UpdateLogic.notes_head(String(_updater.release.get("notes", "")), 4, 60)
			if notes != "":
				v.add_child(UiKit.paragraph(notes, 15, 340.0))
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 10)
			row.add_child(UiKit.button(Strings.UPDATE_BUTTON, func(): _updater.start_update(), 170.0, 18))
			row.add_child(UiKit.button(Strings.UPDATE_LATER, _hide_update_panel, 130.0, 18))
			v.add_child(row)
		Updater.State.DOWNLOADING:
			_update_label = UiKit.label(Strings.UPDATE_DOWNLOADING % 0, 18)
			_update_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(_update_label)
			_update_bar = FancyBar.new()
			_update_bar.custom_minimum_size = Vector2(340, 14)
			_update_bar.glide = false
			v.add_child(_update_bar)
		Updater.State.VERIFYING:
			v.add_child(UiKit.label(Strings.UPDATE_VERIFYING, 18))
		Updater.State.INSTALLING:
			v.add_child(UiKit.label(Strings.UPDATE_INSTALLING, 18))
		Updater.State.DONE:
			v.add_child(UiKit.paragraph(Strings.UPDATE_DONE, 17, 340.0, UiKit.CREAM))
		Updater.State.FAILED:
			v.add_child(UiKit.paragraph(_updater.error_text, 16, 340.0, UiKit.BAD))
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 10)
			row.add_child(UiKit.button(Strings.UPDATE_OPEN_PAGE, func():
				OS.shell_open(String(_updater.release.get("page_url", Updater.PAGE_URL))), 220.0, 16))
			row.add_child(UiKit.button(Strings.UPDATE_LATER, _hide_update_panel, 110.0, 16))
			v.add_child(row)


func _hide_update_panel() -> void:
	_update_hidden = true
	_show_page(Page.MAIN)


func _on_update_state() -> void:
	if _open and _title and _page == Page.MAIN:
		_show_page(Page.MAIN)


func _on_update_progress(fraction: float) -> void:
	if is_instance_valid(_update_bar):
		_update_bar.value = fraction
	if is_instance_valid(_update_label):
		_update_label.text = Strings.UPDATE_DOWNLOADING % roundi(fraction * 100.0)


func _build_credits() -> void:
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_top = 30.0 if _title else 0.0
	_heading(Strings.CREDITS_HEADING)
	for entry in Strings.CREDITS_LINES:
		var head := UiKit.label(entry[0], 19, UiKit.GOLD_TEXT)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(head)
		var body := UiKit.paragraph(entry[1], 17, 560.0, UiKit.CREAM)
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(body)
	var version := UiKit.label(Strings.VERSION_LABEL % Updater.current_version(), 15, UiKit.MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(version)
	var center := CenterContainer.new()
	center.add_child(UiKit.button(Strings.MENU_BACK, func(): _show_page(Page.MAIN), 160.0, 18))
	_box.add_child(center)


func _build_pause_page() -> void:
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_top = 0.0
	_heading(Strings.MENU_PAUSED)
	_menu_button(Strings.MENU_RESUME, _close_menu)
	_menu_button(Strings.MENU_SAVE, func():
		autosave(true)
		_close_menu())
	_menu_button(Strings.MENU_SETTINGS, func(): _show_page(Page.SETTINGS))
	_menu_button(Strings.MENU_CONTROLS, func(): _show_page(Page.HELP))
	_menu_button(Strings.MENU_TITLE_SCREEN, _to_title)
	_menu_button(Strings.MENU_QUIT, func():
		autosave(true)
		get_tree().quit())


## The controls help: every key and mouse action in two columns, each with a key cap.
func _build_help() -> void:
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_top = 30.0 if _title else 0.0
	_heading(Strings.MENU_CONTROLS)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 46)
	grid.add_theme_constant_override("v_separation", 7)
	var entries: Array = Strings.CONTROLS_HELP
	var half := ceili(entries.size() / 2.0)
	for i in half:
		for col in 2:
			var idx := i + col * half
			if idx >= entries.size():
				grid.add_child(Control.new())
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			var cap_holder := Control.new()
			cap_holder.custom_minimum_size = Vector2(150, 0)
			var cap := UiKit.key_cap(entries[idx][0], 16)
			cap_holder.add_child(cap)
			cap_holder.custom_minimum_size.y = 34
			cap.position = Vector2(0, 3)
			row.add_child(cap_holder)
			var text := UiKit.label(entries[idx][1], 17)
			text.custom_minimum_size = Vector2(210, 34)
			text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(text)
			grid.add_child(row)
	_box.add_child(grid)
	var back := UiKit.button(Strings.MENU_BACK, func():
		if _help_from_hud:
			_close_menu()
		else:
			_show_page(Page.MAIN), 160.0, 18)
	var center := CenterContainer.new()
	center.add_child(back)
	_box.add_child(center)


func _build_settings() -> void:
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_top = 30.0 if _title else 0.0
	_heading(Strings.MENU_SETTINGS)
	_box.add_child(UiKit.label(Strings.SET_VOLUMES, 19, UiKit.GOLD_TEXT))
	for entry in [["master", Strings.SET_MASTER], ["music", Strings.SET_MUSIC], ["sfx", Strings.SET_SFX], ["ambient", Strings.SET_AMBIENT]]:
		_box.add_child(_volume_row(entry[0], entry[1]))
	_box.add_child(UiKit.label(Strings.SET_DEVICE, 19, UiKit.GOLD_TEXT))
	_box.add_child(_device_picker())
	var updates := CheckBox.new()
	updates.text = Strings.SET_UPDATES
	updates.button_pressed = GameSettings.check_updates
	updates.focus_mode = Control.FOCUS_NONE
	updates.add_theme_font_size_override("font_size", 18)
	updates.add_theme_color_override("font_color", UiKit.CREAM)
	updates.add_theme_icon_override("checked", _check_icon(true))
	updates.add_theme_icon_override("unchecked", _check_icon(false))
	updates.toggled.connect(func(on: bool): GameSettings.set_check_updates(on))
	_box.add_child(updates)
	_box.add_child(_graphics_row())
	_box.add_child(UiKit.label(Strings.SET_KEYS, 19, UiKit.GOLD_TEXT))
	_box.add_child(_key_list())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UiKit.button(Strings.SET_RESET_KEYS, func():
		GameSettings.reset_keys()
		_show_page(Page.SETTINGS), 220.0, 18))
	row.add_child(UiKit.button(Strings.MENU_BACK, func(): _show_page(Page.MAIN), 160.0, 18))
	_box.add_child(row)


## A checkbox picture that shows on the dark panel: rounded light-edged square, a gold tick when checked.
func _check_icon(checked: bool) -> ImageTexture:
	var s := 24
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			if (x < 3 or x >= s - 3) and (y < 3 or y >= s - 3):
				continue
			var edge := x < 2 or y < 2 or x >= s - 2 or y >= s - 2
			img.set_pixel(x, y, Color(0.78, 0.8, 0.92) if edge else Color(0.17, 0.19, 0.27))
	if checked:
		var gold := Color(1.0, 0.82, 0.35)
		for i in 5:
			for t in 2:
				img.set_pixel(5 + i, 12 + i + t, gold)
		for i in 10:
			for t in 2:
				img.set_pixel(10 + i, 16 - i + t, gold)
	return ImageTexture.create_from_image(img)


func _volume_row(id: String, text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name := UiKit.label(text, 18)
	name.custom_minimum_size.x = 120
	row.add_child(name)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = GameSettings.volumes[id]
	slider.custom_minimum_size = Vector2(300, 24)
	slider.focus_mode = Control.FOCUS_NONE
	row.add_child(slider)
	var value := UiKit.label("%d%%" % roundi(slider.value * 100.0), 18, UiKit.MUTED)
	value.custom_minimum_size.x = 56
	row.add_child(value)
	slider.value_changed.connect(func(v: float):
		GameSettings.set_volume(id, v)
		value.text = "%d%%" % roundi(v * 100.0))
	slider.drag_ended.connect(func(_changed: bool): Sfx.ui("ui_click"))
	return row


func _device_picker() -> Control:
	var option := OptionButton.new()
	option.focus_mode = Control.FOCUS_NONE
	option.custom_minimum_size = Vector2(480, 34)
	option.add_theme_font_size_override("font_size", 17)
	option.add_theme_color_override("font_color", UiKit.CREAM)
	for style in ["normal", "hover", "pressed"]:
		option.add_theme_stylebox_override(style, UiKit._button_box(Color(0.17, 0.19, 0.27, 0.96), Color(1, 1, 1, 0.20), 3))
	var devices := AudioServer.get_output_device_list()
	for i in devices.size():
		option.add_item(devices[i])
		if devices[i] == AudioServer.output_device:
			option.select(i)
	option.item_selected.connect(func(i: int):
		GameSettings.set_device(devices[i])
		Sfx.ui("bell_toll", -6.0))
	return option


## "Γραφικά": the renderer drop-down, a description of the chosen mode and the apply button. A renderer
## cannot change while the game runs, so applying writes override.cfg and restarts (graphics_mode.gd).
func _graphics_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name := UiKit.label(Strings.SET_GRAPHICS, 19, UiKit.GOLD_TEXT)
	name.custom_minimum_size.x = 90
	row.add_child(name)
	var option := OptionButton.new()
	option.focus_mode = Control.FOCUS_NONE
	option.custom_minimum_size = Vector2(200, 34)
	option.add_theme_font_size_override("font_size", 17)
	option.add_theme_color_override("font_color", UiKit.CREAM)
	for style in ["normal", "hover", "pressed"]:
		option.add_theme_stylebox_override(style, UiKit._button_box(Color(0.17, 0.19, 0.27, 0.96), Color(1, 1, 1, 0.20), 3))
	var ids := GraphicsMode.ids()
	var current := GraphicsMode.current()
	for i in ids.size():
		option.add_item(GraphicsMode.label(ids[i]))
		if ids[i] == current:
			option.select(i)
	row.add_child(option)
	var apply := UiKit.button(Strings.GFX_APPLY, func(): pass, 260.0, 16)
	apply.disabled = true
	row.add_child(apply)
	box.add_child(row)
	var desc := UiKit.paragraph(GraphicsMode.description(ids[option.selected]), 15, 640.0)
	box.add_child(desc)
	var status := UiKit.paragraph("", 15, 640.0, UiKit.BAD)
	status.visible = false
	box.add_child(status)
	option.item_selected.connect(func(i: int):
		apply.disabled = ids[i] == current
		desc.text = GraphicsMode.description(ids[i])
		desc.visible = true
		status.visible = false)
	apply.pressed.connect(func(): _apply_graphics(ids[option.selected], desc, status))
	return box


## A problem replaces the description line (the settings page has no room for an extra line).
func _apply_graphics(id: String, desc: Label, status: Label) -> void:
	var problem := ""
	if not GraphicsMode.can_restart():
		problem = Strings.GFX_ERR_EDITOR
	else:
		if not _title:
			autosave(true)                           # the restart must not lose progress
		var result := GraphicsMode.apply(id)
		if result["ok"]:
			get_tree().quit()
			return
		problem = Strings.GFX_ERR_WRITE if result["error"] == "write" else Strings.GFX_ERR_EDITOR
	status.text = problem
	status.visible = true
	desc.visible = false


func _key_list() -> Control:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 120)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	for entry in GameSettings.REBINDABLE:
		var action: String = entry[0]
		var label := UiKit.label(entry[1], 16)
		label.custom_minimum_size.x = 150
		grid.add_child(label)
		var b := UiKit.button(GameSettings.key_name(action), func(): _start_capture(action), 100.0, 16)
		grid.add_child(b)
		_key_buttons[action] = b
	return scroll


func _start_capture(action: String) -> void:
	_capturing = action
	for a in _key_buttons:
		(_key_buttons[a] as Button).text = Strings.SET_PRESS if a == action else GameSettings.key_name(a)


# -------------------------------------------------------------------- input ----

func _input(event: InputEvent) -> void:
	if _capturing == "" or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	if key.physical_keycode == KEY_ESCAPE:
		_capturing = ""
	else:
		GameSettings.rebind(_capturing, key)
		_capturing = ""
		Sfx.ui("ui_click")
	for a in _key_buttons:
		(_key_buttons[a] as Button).text = GameSettings.key_name(a)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _open:
		if _capturing == "":
			toggle_pause()
		get_viewport().set_input_as_handled()
		return
	# the game: Esc opens the pause menu unless a window is open (those close themselves first)
	if _hud != null and (_hud.is_dialogue_open() or _hud.is_shop_open()):
		return
	if _player != null and _player.busy:
		return
	toggle_pause()
	get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ actions ----

func _continue_game() -> void:
	var data := SaveGame.read()
	if data.is_empty():
		return
	_title = false
	_close_menu_silent()
	SaveGame.apply(data)
	for e in get_tree().get_nodes_in_group("enemies"):
		if SaveGame.boss_defeated(String(e.get("kind_id"))) and not e.is_in_group("invaders"):
			e.queue_free()                 # a boss killed in an earlier session
	Sfx.ui("heal")


func _new_game() -> void:
	SaveGame.delete()
	Quests.reset()
	_title = false
	_close_menu_silent()
	if _hud:
		_hud.start_prologue()


func _to_title() -> void:
	autosave(true)
	SaveGame.reset_progress()               # the file holds the progress; the next scene starts clean
	get_tree().paused = false
	get_tree().reload_current_scene()


func _close_menu_silent() -> void:
	_open = false
	_dim.visible = false
	get_tree().paused = false
	if _hud:
		_hud.visible = true


## Saves now. Silent calls (autosave) only show a small message in the feed.
func autosave(announce := false) -> void:
	if _title or (_player != null and _player.is_dead):
		return
	var ok := SaveGame.save()
	if _hud != null and (announce or ok):
		_hud.show_message(Strings.SAVED if ok else Strings.SAVE_FAILED)
