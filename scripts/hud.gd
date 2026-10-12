extends CanvasLayer
## All on-screen UI (Greek): title card, controls, health/XP bars, gold and potions,
## message feed, quest tracker, "press R" prompt, NPC dialogue box, screen fades.

const BAR_SIZE := Vector2(320, 26)
const GOLD_TEXT := Color(1, 0.84, 0.35)
const CREAM := Color(1, 0.96, 0.85)

var _fill: ColorRect
var _health_text: Label
var _flash: ColorRect
var _death_text: Label
var _xp_fill: ColorRect
var _stats_text: Label
var _feed: VBoxContainer
var _banner: Label
var _end_text: Label
var _prompt: Label
var _fade: ColorRect
var _tracker: VBoxContainer
var _level := 1
var _health := 100.0
var _max_health := 100.0

# dialogue
var _dlg_panel: PanelContainer
var _dlg_name: Label
var _dlg_text: Label
var _dlg_hint: Label
var _dlg_lines: Array = []
var _dlg_index := 0
var _dlg_open_time := 0.0
var _dlg_done: Callable
var _dlg_tween: Tween
var _player: Player

# action bar, buffs, skill book
var _bar_slots: Array[ActionSlot] = []
var _buff_box: HBoxContainer
var _buff_labels := {}
var _hero: HeroWindow
var _shop: ShopWindow
var _hint: Label
var _clock_label: Label
var _clock_icon: Control
var _clock_is_night := false
var _daynight: DayNight
var _def_box: Control
var _def_label: Label
var _def_fill: ColorRect
var _banner_tween: Tween
var _mini_frame: Control
var _big_map: Control
var _interiors: Interiors


func _ready() -> void:
	add_to_group("hud")
	_player = get_tree().get_first_node_in_group("player") as Player

	var title := _label(Strings.TITLE, 50, Control.PRESET_TOP_WIDE)
	title.offset_top = 110.0
	var controls := _label(Strings.CONTROLS_1 + "\n" + Strings.CONTROLS_2, 16, Control.PRESET_BOTTOM_WIDE)
	controls.offset_top = -86.0
	controls.offset_bottom = -30.0
	controls.modulate.a = 0.85
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(title, "modulate:a", 0.0, 2.0)

	_build_bars()
	_build_tracker()
	_build_prompt_and_dialogue()
	_build_action_bar()
	_build_clock()
	_build_maps()
	_connect_signals()
	_refresh_tracker()

	if not Quests.intro_seen:
		await get_tree().create_timer(1.0).timeout
		show_dialogue(Strings.NARRATOR, QuestData.PROLOGUE, func(): Quests.intro_seen = true)


func _connect_signals() -> void:
	Quests.changed.connect(_refresh_tracker)
	Quests.message.connect(show_message)
	Quests.game_finished.connect(_on_game_finished)
	if _player == null:
		return
	_player.health_changed.connect(_on_health_changed)
	_player.xp_changed.connect(_on_xp_changed)
	_player.inventory_changed.connect(_on_inventory_changed)
	_player.message.connect(show_message)
	_player.leveled_up.connect(_on_level_up)
	_player.prompt_changed.connect(_on_prompt_changed)
	var invasion := get_parent().get_node_or_null("Invasion") as Invasion
	if invasion:
		invasion.updated.connect(_on_invasion_updated)
		invasion.banner.connect(show_banner)
	_player.died.connect(func(): _death_text.visible = true)
	_player.respawned.connect(func(): _death_text.visible = false)


# ----------------------------------------------------------------- helpers ----

func _label(text: String, size: int, preset: Control.LayoutPreset) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", CREAM)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.03))
	l.add_theme_constant_override("outline_size", maxi(4, size / 6))
	l.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _rect(color: Color, pos: Vector2, size: Vector2, parent: Node) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.position = pos
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _plain_label(text: String, size: int, color: Color = CREAM) -> Label:
	return UiKit.label(text, size, color)


func _panel_style() -> StyleBoxFlat:
	return UiKit.panel_style()


# -------------------------------------------------------------------- bars ----

func _build_bars() -> void:
	_flash = ColorRect.new()
	_flash.color = Color(0.8, 0.05, 0.05, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)

	var back := _rect(Color(0.07, 0.05, 0.04, 0.85), Vector2(28, 28), BAR_SIZE + Vector2(8, 8), self)
	_fill = _rect(Color(0.78, 0.16, 0.14), Vector2(4, 4), BAR_SIZE, back)
	_health_text = _label("", 18, Control.PRESET_TOP_LEFT)
	_health_text.position = Vector2(back.position.x + 8, back.position.y + 6)
	_health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var xp_back := _rect(Color(0.07, 0.05, 0.04, 0.85), Vector2(28, 68), Vector2(BAR_SIZE.x + 8, 14), self)
	_xp_fill = _rect(Color(0.95, 0.75, 0.2), Vector2(4, 3), Vector2(0, 8), xp_back)

	_stats_text = _label("", 18, Control.PRESET_TOP_LEFT)
	_stats_text.position = Vector2(28, 86)
	_stats_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_feed = VBoxContainer.new()
	_feed.position = Vector2(28, 126)
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_feed)

	_banner = _label("", 56, Control.PRESET_CENTER)
	_banner.anchor_left = 0.0       # full width, so long banners stay centred
	_banner.anchor_right = 1.0
	_banner.offset_left = 0.0
	_banner.offset_right = 0.0
	_banner.position.y -= 160.0
	_banner.modulate.a = 0.0

	_end_text = _label(Strings.TO_BE_CONTINUED, 72, Control.PRESET_CENTER)
	_end_text.modulate.a = 0.0

	_death_text = _label(Strings.FALLEN, 48, Control.PRESET_CENTER)
	_death_text.visible = false

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func _refresh_health_text() -> void:
	_health_text.text = "%s  %s %d   %d / %d" % [Strings.HERO, Strings.LEVEL_SHORT, _level, ceili(_health), ceili(_max_health)]


func _on_health_changed(current: float, maximum: float) -> void:
	var lost := current < _health
	_health = current
	_max_health = maximum
	_fill.size.x = BAR_SIZE.x * clampf(current / maximum, 0.0, 1.0)
	_refresh_health_text()
	if lost:
		_flash.color.a = 0.3
		create_tween().tween_property(_flash, "color:a", 0.0, 0.4)


func _on_xp_changed(level: int, xp: int, needed: int) -> void:
	_level = level
	_xp_fill.size.x = BAR_SIZE.x * clampf(float(xp) / float(needed), 0.0, 1.0)
	_refresh_health_text()


func _on_inventory_changed(gold: int, potions: int) -> void:
	_stats_text.text = "%s %d     %s %d  [H]" % [Strings.GOLD, gold, Strings.POTIONS, potions]


func _on_level_up(level: int) -> void:
	_banner.text = Strings.LEVEL_UP % level
	_banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.8)


## Short messages that stack under the stats and fade away.
func show_message(text: String) -> void:
	var l := _plain_label(text, 20)
	_feed.add_child(l)
	if _feed.get_child_count() > 6:
		_feed.get_child(0).queue_free()
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(l, "modulate:a", 0.0, 0.6)
	tween.tween_callback(l.queue_free)


func _on_game_finished() -> void:
	await get_tree().create_timer(1.0).timeout
	var tween := create_tween()
	tween.tween_property(_end_text, "modulate:a", 1.0, 2.0)
	tween.tween_interval(5.0)
	tween.tween_property(_end_text, "modulate:a", 0.0, 2.0)


# ------------------------------------------------------------ quest tracker ----

func _build_tracker() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_top = 244.0          # below the minimap
	panel.offset_right = -28.0
	panel.name = "TrackerPanel"
	add_child(panel)
	_tracker = VBoxContainer.new()
	_tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_tracker)


func _refresh_tracker() -> void:
	if _tracker == null:
		return
	for c in _tracker.get_children():
		c.queue_free()
	var quests := Quests.tracker()
	_tracker.get_parent().visible = not quests.is_empty()
	if quests.is_empty():
		return
	_tracker.add_child(_plain_label(Strings.QUESTS_HEADER, 22, GOLD_TEXT))
	for q in quests:
		var t := _plain_label(q["title"], 19, Color(0.55, 0.95, 0.5) if q["ready"] else CREAM)
		t.custom_minimum_size.x = 250
		_tracker.add_child(t)
		for line in q["lines"]:
			var l := _plain_label("  " + line, 16, Color(0.85, 0.82, 0.72))
			_tracker.add_child(l)


# --------------------------------------------------------- prompt, dialogue ----

func _build_prompt_and_dialogue() -> void:
	_prompt = _label("", 26, Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -262.0
	_prompt.offset_bottom = -222.0
	_prompt.add_theme_color_override("font_color", GOLD_TEXT)
	_prompt.visible = false

	_dlg_panel = PanelContainer.new()
	_dlg_panel.add_theme_stylebox_override("panel", _panel_style())
	_dlg_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_dlg_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dlg_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_dlg_panel.offset_bottom = -190.0
	_dlg_panel.custom_minimum_size = Vector2(900, 0)
	_dlg_panel.visible = false
	_dlg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dlg_panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dlg_panel.add_child(box)
	_dlg_name = _plain_label("", 26, GOLD_TEXT)
	box.add_child(_dlg_name)
	_dlg_text = _plain_label("", 22)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(850, 96)
	box.add_child(_dlg_text)
	_dlg_hint = _plain_label(Strings.PROMPT_CONTINUE, 16, Color(0.8, 0.75, 0.6))
	_dlg_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_dlg_hint)


func _on_prompt_changed(text: String) -> void:
	_prompt.text = text
	_prompt.visible = text != "" and not _dlg_panel.visible


func is_dialogue_open() -> bool:
	return _dlg_panel != null and _dlg_panel.visible


## Shows lines of speech one after another. on_done is called after the last line.
func show_dialogue(speaker: String, lines: Array, on_done: Callable = Callable()) -> void:
	if _dlg_panel.visible or lines.is_empty():
		return
	_dlg_lines = lines
	_dlg_index = 0
	_dlg_done = on_done
	_dlg_name.text = speaker
	_dlg_panel.visible = true
	_prompt.visible = false
	_dlg_open_time = Time.get_ticks_msec() / 1000.0
	if _player:
		_player.busy = true
	_show_line()


func _show_line() -> void:
	_dlg_text.text = _dlg_lines[_dlg_index]
	_dlg_text.visible_ratio = 0.0
	if _dlg_tween:
		_dlg_tween.kill()
	_dlg_tween = create_tween()
	var chars := _dlg_text.text.length()
	var last_blip := [0]
	_dlg_tween.tween_method(func(r: float):
		_dlg_text.visible_ratio = r
		var k := int(r * float(chars) / 3.0)
		if k != last_blip[0]:
			last_blip[0] = k
			Sfx.ui("dialogue_blip"), 0.0, 1.0, maxf(0.4, chars * 0.018))


func _advance_dialogue() -> void:
	if _dlg_text.visible_ratio < 1.0:
		_dlg_tween.kill()
		_dlg_text.visible_ratio = 1.0
		return
	_dlg_index += 1
	if _dlg_index < _dlg_lines.size():
		_show_line()
		return
	_dlg_panel.visible = false
	var done := _dlg_done
	_dlg_done = Callable()
	if done.is_valid():
		done.call()
	# Keep George still for a moment so the same key press does not restart the talk.
	await get_tree().create_timer(0.2).timeout
	if _player and not _dlg_panel.visible and not is_shop_open():
		_player.busy = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map") and not is_dialogue_open() and not _shop.is_open():
		_big_map.visible = not _big_map.visible
		Sfx.ui("window_open" if _big_map.visible else "window_close")
		get_viewport().set_input_as_handled()
		return
	if _big_map.visible and event.is_action_pressed("ui_cancel"):
		_big_map.visible = false
		Sfx.ui("window_close")
		get_viewport().set_input_as_handled()
		return
	if not is_dialogue_open() and not _shop.is_open():
		for pair in [["skillbook", "skills"], ["talents", "talents"], ["equipment", "gear"]]:
			if event.is_action_pressed(pair[0]):
				_hero.toggle(pair[1])
				get_viewport().set_input_as_handled()
				return
	if not is_dialogue_open():
		return
	if Time.get_ticks_msec() / 1000.0 - _dlg_open_time < 0.25:
		return
	var click := false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		click = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("interact"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()


# --------------------------------------------------------------- action bar ----

func _build_action_bar() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_bottom = -104.0
	row.name = "ActionBar"
	add_child(row)
	for i in 8:
		var slot := ActionSlot.new()
		slot.player = _player
		slot.slot_index = i
		slot.key_label = str(i + 1)
		row.add_child(slot)
		_bar_slots.append(slot)

	var hint := _plain_label(Strings.SKILLBOOK_KEY, 15, Color(0.85, 0.8, 0.65))
	_hint = hint
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.offset_bottom = -170.0
	hint.offset_top = -190.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	_buff_box = HBoxContainer.new()
	_buff_box.add_theme_constant_override("separation", 14)
	_buff_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buff_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_buff_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_buff_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_buff_box.offset_bottom = -194.0
	add_child(_buff_box)
	for id in ["power", "speed", "guard", "frenzy", "shout", "wall"]:
		var l := _plain_label("", 18, Color(1.0, 0.85, 0.4))
		l.visible = false
		_buff_box.add_child(l)
		_buff_labels[id] = l

	_build_windows()


func _process(_delta: float) -> void:
	_update_clock()
	if _interiors == null:
		_interiors = get_tree().get_first_node_in_group("interiors") as Interiors
	elif _mini_frame != null:
		_mini_frame.visible = not _interiors.is_inside()
	if _player == null:
		return
	var names := {"power": Strings.BUFF_POWER, "speed": Strings.BUFF_SPEED, "guard": Strings.BUFF_GUARD,
		"frenzy": Strings.BUFF_FRENZY, "shout": Strings.BUFF_SHOUT, "wall": Strings.BUFF_WALL}
	for id in _buff_labels:
		var t := _player.buff_time(id)
		var l: Label = _buff_labels[id]
		l.visible = t > 0.0
		if t > 0.0:
			l.text = "%s %d δ" % [names[id], ceili(t)]


# ------------------------------------------------- clock and invasion panel ----

func _build_clock() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.anchor_left = 0.5
	row.anchor_right = 0.5
	row.offset_left = -150.0
	row.offset_right = 150.0
	row.offset_top = 12.0
	row.offset_bottom = 46.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_clock_icon = Control.new()
	_clock_icon.custom_minimum_size = Vector2(30, 30)
	_clock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock_icon.draw.connect(func():
		Icons.draw(_clock_icon, Rect2(Vector2.ZERO, _clock_icon.size), "moon" if _clock_is_night else "sun",
				Color(0.85, 0.9, 1.0) if _clock_is_night else Color(1.0, 0.82, 0.3)))
	row.add_child(_clock_icon)
	_clock_label = _plain_label("", 22)
	row.add_child(_clock_label)

	_def_box = Control.new()
	_def_box.anchor_left = 0.5
	_def_box.anchor_right = 0.5
	_def_box.offset_left = -170.0
	_def_box.offset_right = 170.0
	_def_box.offset_top = 52.0
	_def_box.offset_bottom = 110.0
	_def_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_def_box.visible = false
	add_child(_def_box)
	_def_label = _plain_label("", 20, Color(1.0, 0.8, 0.7))
	_def_label.position = Vector2(0, 0)
	_def_label.size = Vector2(340, 26)
	_def_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_def_box.add_child(_def_label)
	var back := _rect(Color(0.07, 0.05, 0.04, 0.85), Vector2(0, 30), Vector2(340, 18), _def_box)
	_def_fill = _rect(Color(0.35, 0.75, 0.4), Vector2(3, 3), Vector2(334, 12), back)
	var cap := _plain_label(Strings.INVASION_SAFETY, 14, Color(0.9, 0.9, 0.85))
	cap.position = Vector2(0, 48)
	cap.size = Vector2(340, 18)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_def_box.add_child(cap)


func _update_clock() -> void:
	if _daynight == null:
		_daynight = get_tree().get_first_node_in_group("daynight") as DayNight
		if _daynight == null:
			return
	_clock_label.text = _daynight.clock_text()
	var night := _daynight.darkness() > 0.5
	if night != _clock_is_night:
		_clock_is_night = night
		_clock_icon.queue_redraw()


func _on_invasion_updated(active: bool, wave: int, waves: int, alive: int, safety: float) -> void:
	_def_box.visible = active
	if not active:
		return
	_def_label.text = Strings.INVASION_WAVE % [maxi(wave, 1), waves, alive]
	_def_fill.size.x = 334.0 * clampf(safety / 100.0, 0.0, 1.0)
	_def_fill.color = Color(0.35, 0.75, 0.4).lerp(Color(0.85, 0.2, 0.15), 1.0 - clampf(safety / 100.0, 0.0, 1.0))


## A big title in the middle of the screen that fades after `seconds`.
func show_banner(text: String, seconds: float = 2.5) -> void:
	_banner.text = text
	_banner.add_theme_font_size_override("font_size", clampi(int(1150.0 / (float(text.length()) * 0.62)), 32, 56))
	_banner.modulate.a = 1.0
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(seconds)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.8)


func _build_maps() -> void:
	# corner minimap
	_mini_frame = Panel.new()
	_mini_frame.anchor_left = 1.0
	_mini_frame.anchor_right = 1.0
	_mini_frame.offset_left = -228.0
	_mini_frame.offset_right = -28.0
	_mini_frame.offset_top = 28.0
	_mini_frame.offset_bottom = 228.0
	_mini_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_frame.add_theme_stylebox_override("panel", _map_frame_style())
	add_child(_mini_frame)
	var mini := Minimap.new()
	mini.position = Vector2(4, 4)
	mini.size = Vector2(192, 192)
	_mini_frame.add_child(mini)

	# full map (M)
	_big_map = Control.new()
	_big_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_big_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_big_map.visible = false
	add_child(_big_map)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_big_map.add_child(dim)
	var frame := Panel.new()
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -292.0
	frame.offset_right = 292.0
	frame.offset_top = -330.0
	frame.offset_bottom = 330.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _map_frame_style())
	_big_map.add_child(frame)
	var title := _plain_label(Strings.MAP_TITLE, 24, GOLD_TEXT)
	title.position = Vector2(0, 8)
	title.size = Vector2(584, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(title)
	var big := Minimap.new()
	big.big = true
	big.position = Vector2(12, 46)
	big.size = Vector2(560, 560)
	frame.add_child(big)
	var legend := _plain_label(Strings.MAP_LEGEND, 13, Color(0.9, 0.88, 0.8))
	legend.position = Vector2(0, 618)
	legend.size = Vector2(584, 24)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(legend)


func _map_frame_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.04, 0.92)
	sb.border_color = Color(0.85, 0.65, 0.3)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	return sb


func _build_windows() -> void:
	_hero = HeroWindow.new()
	_hero.player = _player
	add_child(_hero)
	_shop = ShopWindow.new()
	add_child(_shop)
	if _player:
		_player.talents_changed.connect(_update_hint)
		_player.leveled_up.connect(func(_l): _update_hint())
	_update_hint()


## The key hint under the action bar also tells when talent points are waiting.
func _update_hint() -> void:
	var free := _player.talent_points_free() if _player else 0
	_hint.text = Strings.SKILLBOOK_KEY + (Strings.HINT_TALENT_POINTS % free if free > 0 else "")


## Opens a shop window (called by shopkeepers after their greeting).
func open_shop(shop_id: String, player: Player) -> void:
	_shop.open(shop_id, player)


func is_shop_open() -> bool:
	return _shop != null and _shop.is_open()


# ------------------------------------------------------------------- fading ----

## Fades the screen to black (awaitable).
func fade_out(time: float = 0.35) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, time)
	await tween.finished


func fade_in(time: float = 0.35) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, time)
	await tween.finished
