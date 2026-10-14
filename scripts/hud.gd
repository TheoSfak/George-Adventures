extends CanvasLayer
## All on-screen UI (Greek): title card, controls, health/XP bars, gold and potions,
## message feed, quest tracker, "press R" prompt, NPC dialogue box, screen fades.

const BAR_SIZE := Vector2(280, 26)
const COMPACT_SLOT := 46.0        # the action bar slots (the skill book keeps the full size)
const GOLD_TEXT := Color(1, 0.84, 0.35)
const CREAM := Color(1, 0.96, 0.85)
const VOICE_TEXT_TAIL := 0.15     # a voiced line finishes typing this long after the voice ends

var _hp_bar: FancyBar
var _xp_bar: FancyBar
var _level_badge: UiKit.LevelBadge
var _gold_label: Label
var _potion_label: Label
var _mount_box: HBoxContainer          # [horseshoe] [G] Άλογο, shown once the horse is bought
var _mount_key: Label
var _mount_text: Label
var _mount_shown := ""                  # what the pill shows now ("" = hidden), so it is only rebuilt when it changes
var _flash: ColorRect
var _death_text: Label
var _feed: VBoxContainer
var _banner: Label
var _end_text: Label
var _prompt: Control              # the pill that holds the key cap and the text
var _prompt_text: Label
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
var _dlg_voice_seconds := 0.0          # length of the recording of the line on screen, 0 = no voice
var _player: Player

# action bar, buffs, skill book
var _bar_slots: Array[ActionSlot] = []
var _buff_box: HBoxContainer
var _buff_labels := {}
var _hero: HeroWindow
var _shop: ShopWindow
var _fishing: Fishing
var _hint: Label
var _clock_label: Label
var _clock_icon: Control
var _clock_is_night := false
var _clock_weather := ""                 # "", "cloud", "rain" or "storm" (replaces the sun or moon)
const WEATHER_ICON_COLORS := {
	"cloud": Color(0.85, 0.90, 0.97), "rain": Color(0.55, 0.78, 1.0), "storm": Color(1.0, 0.85, 0.35),
}
var _daynight: DayNight
var _def_box: Control
var _def_label: Label
var _def_bar: FancyBar
var _banner_tween: Tween
var _mini_frame: Control
var _big_map: Control
var _interiors: Interiors


func _ready() -> void:
	UiKit.install_font()
	add_to_group("hud")
	_player = get_tree().get_first_node_in_group("player") as Player

	var title := _label(Strings.TITLE, 50, Control.PRESET_TOP_WIDE)
	title.offset_top = 110.0
	_build_info_button()
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
		# with the title menu (game_menu.gd) the prologue starts from "New game" instead
		if not Quests.intro_seen and get_tree().get_first_node_in_group("game_menu") == null:
			start_prologue()


func start_prologue() -> void:
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
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.75))
	l.add_theme_constant_override("outline_size", maxi(4, size / 7))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("shadow_offset_y", maxi(2, size / 16))
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

	# the hero card: level badge, name, health, experience, gold and potions on one glass panel
	var card := PanelContainer.new()
	card.position = Vector2(24, 20)
	var card_style := UiKit.panel_style(0.80)
	card_style.content_margin_left = 14
	card_style.content_margin_right = 20
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_style)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.name = "HeroCard"
	add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	_level_badge = UiKit.LevelBadge.new()
	_level_badge.custom_minimum_size = Vector2(66, 66)
	_level_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_level_badge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	col.add_child(_plain_label(Strings.HERO, 21, GOLD_TEXT))
	_hp_bar = FancyBar.new()
	_hp_bar.custom_minimum_size = Vector2(BAR_SIZE.x, 26)
	_hp_bar.top_color = Color(1.0, 0.50, 0.44)
	_hp_bar.bottom_color = Color(0.74, 0.10, 0.14)
	_hp_bar.text_size = 16
	_hp_bar.ticks = 5
	col.add_child(_hp_bar)
	_xp_bar = FancyBar.new()
	_xp_bar.custom_minimum_size = Vector2(BAR_SIZE.x, 9)
	_xp_bar.top_color = Color(1.0, 0.90, 0.45)
	_xp_bar.bottom_color = Color(0.86, 0.58, 0.10)
	_xp_bar.value = 0.0
	col.add_child(_xp_bar)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(stats)
	stats.add_child(UiKit.glyph("coin", Color(1.0, 0.82, 0.30), 22))
	_gold_label = _plain_label("0", 19, Color(1.0, 0.92, 0.6))
	stats.add_child(_gold_label)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(14, 0)
	stats.add_child(gap)
	stats.add_child(UiKit.glyph("potion", Color(0.95, 0.35, 0.40), 22))
	_potion_label = _plain_label("0", 19, Color(1.0, 0.85, 0.85))
	stats.add_child(_potion_label)
	stats.add_child(UiKit.key_cap("H", 13))
	var mount_gap := Control.new()
	mount_gap.custom_minimum_size = Vector2(10, 0)
	stats.add_child(mount_gap)
	_mount_box = HBoxContainer.new()
	_mount_box.add_theme_constant_override("separation", 6)
	_mount_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mount_box.visible = false
	stats.add_child(_mount_box)
	_mount_box.add_child(UiKit.glyph("horseshoe", Color(0.86, 0.78, 0.60), 22))
	var mount_cap := UiKit.key_cap("G", 13)
	_mount_key = mount_cap.get_child(0) as Label
	_mount_box.add_child(mount_cap)
	_mount_text = _plain_label(Strings.MOUNT_PILL, 17, Color(0.92, 0.88, 0.78))
	_mount_box.add_child(_mount_text)

	_feed = VBoxContainer.new()
	_feed.position = Vector2(28, 168)
	_feed.add_theme_constant_override("separation", 6)
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
	_hp_bar.text = "%d / %d" % [ceili(_health), ceili(_max_health)]


func _on_health_changed(current: float, maximum: float) -> void:
	var lost := current < _health
	_health = current
	_max_health = maximum
	_hp_bar.value = current / maximum
	_refresh_health_text()
	if lost:
		_flash.color.a = 0.3
		create_tween().tween_property(_flash, "color:a", 0.0, 0.4)


func _on_xp_changed(level: int, xp: int, needed: int) -> void:
	_level = level
	_level_badge.level = level
	_level_badge.queue_redraw()
	_xp_bar.value = float(xp) / float(needed)
	_refresh_health_text()


func _on_inventory_changed(gold: int, potions: int) -> void:
	_gold_label.text = str(gold)
	_potion_label.text = str(potions)


func _on_level_up(level: int) -> void:
	_banner.text = Strings.LEVEL_UP % level
	_banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.8)


## Short messages that stack under the stats and fade away.
func show_message(text: String) -> void:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.pill_style())
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(_plain_label(text, 18))
	_feed.add_child(pill)
	if _feed.get_child_count() > 6:
		_feed.get_child(0).queue_free()
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(pill, "modulate:a", 0.0, 0.6)
	tween.tween_callback(pill.queue_free)


func _on_game_finished() -> void:
	await get_tree().create_timer(1.0).timeout
	var tween := create_tween()
	tween.tween_property(_end_text, "modulate:a", 1.0, 2.0)
	tween.tween_interval(5.0)
	tween.tween_property(_end_text, "modulate:a", 0.0, 2.0)


# ------------------------------------------------------------ quest tracker ----

func _build_tracker() -> void:
	var panel := PanelContainer.new()
	var style := UiKit.panel_style(0.80)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_top = 244.0          # below the minimap
	panel.offset_right = -28.0
	panel.name = "TrackerPanel"
	add_child(panel)
	_tracker = VBoxContainer.new()
	_tracker.add_theme_constant_override("separation", 3)
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
	_tracker.add_child(_plain_label(Strings.QUESTS_HEADER.to_upper(), 15, GOLD_TEXT))
	for q in quests:
		var sep := ColorRect.new()
		sep.color = Color(1, 1, 1, 0.10)
		sep.custom_minimum_size = Vector2(0, 1)
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tracker.add_child(sep)
		var t := _plain_label(q["title"], 19, UiKit.GOOD if q["ready"] else CREAM)
		t.custom_minimum_size.x = 260
		_tracker.add_child(t)
		if q["ready"]:
			for line in q["lines"]:
				_tracker.add_child(_plain_label("✓ " + line, 16, UiKit.GOOD))
			continue
		for o in q["objectives"]:
			var line_row := HBoxContainer.new()
			line_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var txt := _plain_label(o["text"], 15, Color(0.86, 0.86, 0.88))
			txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			txt.custom_minimum_size.x = 210
			line_row.add_child(txt)
			var count := _plain_label("%d/%d" % [o["cur"], o["max"]], 15, GOLD_TEXT)
			count.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			line_row.add_child(count)
			_tracker.add_child(line_row)
			var bar := FancyBar.new()
			bar.custom_minimum_size = Vector2(0, 7)
			bar.top_color = Color(1.0, 0.88, 0.45)
			bar.bottom_color = Color(0.85, 0.58, 0.12)
			bar.glide = false
			bar.value = float(o["cur"]) / maxf(1.0, float(o["max"]))
			_tracker.add_child(bar)


# --------------------------------------------------------- prompt, dialogue ----

func _build_prompt_and_dialogue() -> void:
	# the "press R" prompt: a capsule with a key cap and the action
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.pill_style(Color(1.0, 0.82, 0.38, 0.85), 0.86))
	pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
	pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pill.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pill.offset_bottom = -148.0
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.visible = false
	add_child(pill)
	_prompt = pill
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 10)
	prow.name = "Row"
	prow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(prow)
	_prompt_text = _plain_label("", 22, GOLD_TEXT)
	prow.add_child(_prompt_text)

	_dlg_panel = PanelContainer.new()
	var dlg_style := UiKit.panel_style(0.90)
	dlg_style.set_corner_radius_all(20)
	dlg_style.content_margin_left = 30
	dlg_style.content_margin_right = 30
	dlg_style.content_margin_top = 20
	dlg_style.content_margin_bottom = 16
	_dlg_panel.add_theme_stylebox_override("panel", dlg_style)
	_dlg_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_dlg_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dlg_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_dlg_panel.offset_bottom = -120.0
	_dlg_panel.custom_minimum_size = Vector2(900, 0)
	_dlg_panel.visible = false
	_dlg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dlg_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dlg_panel.add_child(box)
	# the speaker's name on a gold-rimmed tag
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UiKit.pill_style(Color(1.0, 0.82, 0.38, 0.9), 0.95))
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(chip)
	_dlg_name = _plain_label("", 24, GOLD_TEXT)
	chip.add_child(_dlg_name)
	_dlg_text = _plain_label("", 23)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(840, 96)
	box.add_child(_dlg_text)
	_dlg_hint = _plain_label(Strings.PROMPT_CONTINUE, 16, Color(0.72, 0.72, 0.76))
	_dlg_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_dlg_hint)


func _on_prompt_changed(text: String) -> void:
	# "[R] Μίλα: Παπά-Σταύρος" -> a key cap with R and the words next to it
	var row := _prompt.get_node("Row") as HBoxContainer
	for c in row.get_children():
		if c != _prompt_text:
			c.queue_free()
	var words := text
	if text.begins_with("[") and text.find("]") > 0:
		var close := text.find("]")
		var cap := UiKit.key_cap(text.substr(1, close - 1), 18)
		row.add_child(cap)
		row.move_child(cap, 0)
		words = text.substr(close + 1).strip_edges()
	_prompt_text.text = words
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


## The text types in step with the voice when the line has a recording (VoiceOver), otherwise fast with blips.
func _show_line() -> void:
	var line: String = _dlg_lines[_dlg_index]
	_dlg_text.text = line
	_dlg_text.visible_ratio = 0.0
	if _dlg_tween:
		_dlg_tween.kill()
	_dlg_voice_seconds = VoiceOver.play(_dlg_name.text, line)
	var voiced := _dlg_voice_seconds > 0.0
	var duration := _dlg_voice_seconds + VOICE_TEXT_TAIL if voiced else maxf(0.4, line.length() * 0.018)
	_dlg_tween = create_tween()
	var chars := line.length()
	var last_blip := [0]
	_dlg_tween.tween_method(func(r: float):
		_dlg_text.visible_ratio = r
		if voiced:
			return
		var k := int(r * float(chars) / 3.0)
		if k != last_blip[0]:
			last_blip[0] = k
			Sfx.ui("dialogue_blip"), 0.0, 1.0, duration)


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
	VoiceOver.stop()
	_dlg_voice_seconds = 0.0
	var done := _dlg_done
	_dlg_done = Callable()
	if done.is_valid():
		done.call()
	# Keep George still for a moment so the same key press does not restart the talk.
	await get_tree().create_timer(0.2).timeout
	if _player and not _dlg_panel.visible and not is_shop_open():
		_player.busy = false


## Opens or closes the full map (key M, or the map button next to the minimap).
func toggle_big_map() -> void:
	if is_dialogue_open() or _shop.is_open():
		return
	if _interiors != null and _interiors.in_region():
		Quests.message.emit(Strings.MSG_NO_MAP)
		return
	_big_map.visible = not _big_map.visible
	Sfx.ui("window_open" if _big_map.visible else "window_close")


func _zoom_minimap(step: int) -> void:
	Minimap.zoom(step)
	Sfx.ui("ui_click")


## A small round "i" button in the bottom-right corner: opens the controls help (also F1).
func _build_info_button() -> void:
	var b := UiKit.button("i", func(): _open_help(), 38.0, 20)
	for style_name in ["normal", "hover", "pressed"]:
		var sb := (b.get_theme_stylebox(style_name) as StyleBoxFlat).duplicate() as StyleBoxFlat
		sb.set_corner_radius_all(19)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		b.add_theme_stylebox_override(style_name, sb)
	b.custom_minimum_size = Vector2(38, 38)
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = -62.0
	b.offset_right = -24.0
	b.offset_top = -62.0
	b.offset_bottom = -24.0
	b.tooltip_text = Strings.HELP_TOOLTIP
	b.name = "InfoButton"
	add_child(b)


func _open_help() -> void:
	var menu := get_tree().get_first_node_in_group("game_menu")
	if menu != null and not is_dialogue_open() and not _shop.is_open():
		menu.open_help()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_open_help()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("map") and not is_dialogue_open() and not _shop.is_open():
		toggle_big_map()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and not _big_map.visible:
		var code: int = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
		if code == KEY_KP_ADD or code == KEY_EQUAL or code == KEY_PLUS:
			_zoom_minimap(1)
		elif code == KEY_KP_SUBTRACT or code == KEY_MINUS:
			_zoom_minimap(-1)
	if _hero.visible and event.is_action_pressed("ui_cancel"):
		_hero.visible = false
		Sfx.ui("window_close")
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
	if click or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()


# --------------------------------------------------------------- action bar ----

func _build_action_bar() -> void:
	var dock := PanelContainer.new()
	var dock_style := UiKit.panel_style(0.72)
	dock_style.set_corner_radius_all(16)
	dock_style.shadow_size = 8
	dock_style.content_margin_left = 8
	dock_style.content_margin_right = 8
	dock_style.content_margin_top = 6
	dock_style.content_margin_bottom = 6
	dock.add_theme_stylebox_override("panel", dock_style)
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.offset_bottom = -14.0
	dock.name = "ActionBar"
	add_child(dock)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_child(row)
	for i in 8:
		var slot := ActionSlot.new()
		slot.custom_minimum_size = Vector2(COMPACT_SLOT, COMPACT_SLOT)     # a compact action bar leaves the view free
		slot.player = _player
		slot.slot_index = i
		slot.key_label = str(i + 1)
		row.add_child(slot)
		_bar_slots.append(slot)

	var hint := _plain_label(Strings.SKILLBOOK_KEY, 14, Color(0.80, 0.80, 0.84))
	_hint = hint
	hint.add_theme_stylebox_override("normal", UiKit.pill_style(Color(0, 0, 0, 0), 0.45))
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_bottom = -78.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	_buff_box = HBoxContainer.new()
	_buff_box.add_theme_constant_override("separation", 14)
	_buff_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buff_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_buff_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_buff_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_buff_box.offset_bottom = -110.0
	add_child(_buff_box)
	for id in ["power", "speed", "guard", "frenzy", "shout", "wall", "food"]:
		var l := _plain_label("", 17, Color(1.0, 0.88, 0.5))
		l.add_theme_stylebox_override("normal", UiKit.pill_style(Color(1.0, 0.82, 0.38, 0.8), 0.85))
		l.visible = false
		_buff_box.add_child(l)
		_buff_labels[id] = l

	_build_windows()


func _process(_delta: float) -> void:
	_update_clock()
	if _interiors == null:
		_interiors = get_tree().get_first_node_in_group("interiors") as Interiors
	elif _mini_frame != null:
		_mini_frame.visible = not (_interiors.is_inside() or _interiors.in_region())
	if _player == null:
		return
	_refresh_mount_pill()
	var names := {"power": Strings.BUFF_POWER, "speed": Strings.BUFF_SPEED, "guard": Strings.BUFF_GUARD,
		"frenzy": Strings.BUFF_FRENZY, "shout": Strings.BUFF_SHOUT, "wall": Strings.BUFF_WALL, "food": ""}
	for id in _buff_labels:
		var t := _player.buff_time(id)
		var l: Label = _buff_labels[id]
		l.visible = t > 0.0
		if t > 0.0:
			if id == "food":
				l.text = "%s %d:%02d" % [_player.food_name(), floori(t / 60.0), int(t) % 60]
			else:
				l.text = "%s %d δ" % [names[id], ceili(t)]


## The horse in the corner panel once it is bought: [G] Άλογο, [G] Κατέβα while riding. The key shown is
## the one bound to the "mount" action (it can be rebound in the settings).
func _refresh_mount_pill() -> void:
	if _mount_box == null:
		return
	var key := _mount_key_name()
	var text := ""
	if _player.horse_owned:
		text = key + "|" + (Strings.MOUNT_PILL_OFF if _player.mounted else Strings.MOUNT_PILL)
	if text == _mount_shown:
		return
	_mount_shown = text
	_mount_box.visible = text != ""
	if text != "":
		_mount_key.text = key
		_mount_text.text = text.get_slice("|", 1)


func _mount_key_name() -> String:
	for ev in InputMap.action_get_events("mount"):
		if ev is InputEventKey:
			var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
			return OS.get_keycode_string(code)
	return "G"


# ------------------------------------------------- clock and invasion panel ----

func _build_clock() -> void:
	# a capsule at the top centre: sun or moon and the time of day
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0, 0, 0, 0), 0.78))
	pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pill.offset_top = 14.0
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	_clock_icon = Control.new()
	_clock_icon.custom_minimum_size = Vector2(28, 28)
	_clock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock_icon.draw.connect(func():
		var rect := Rect2(Vector2.ZERO, _clock_icon.size)
		if _clock_weather != "":
			Icons.draw(_clock_icon, rect, _clock_weather, WEATHER_ICON_COLORS[_clock_weather])
		else:
			Icons.draw(_clock_icon, rect, "moon" if _clock_is_night else "sun",
					Color(0.85, 0.9, 1.0) if _clock_is_night else Color(1.0, 0.82, 0.3)))
	row.add_child(_clock_icon)
	_clock_label = _plain_label("", 21)
	row.add_child(_clock_label)

	# the village safety panel during a night invasion
	_def_box = PanelContainer.new()
	var def_style := UiKit.panel_style(0.82)
	def_style.content_margin_top = 10
	def_style.content_margin_bottom = 10
	_def_box.add_theme_stylebox_override("panel", def_style)
	_def_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	_def_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_def_box.offset_top = 66.0
	_def_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_def_box.visible = false
	add_child(_def_box)
	var dcol := VBoxContainer.new()
	dcol.add_theme_constant_override("separation", 5)
	dcol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_def_box.add_child(dcol)
	_def_label = _plain_label("", 20, Color(1.0, 0.85, 0.75))
	_def_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dcol.add_child(_def_label)
	_def_bar = FancyBar.new()
	_def_bar.custom_minimum_size = Vector2(340, 18)
	_def_bar.top_color = Color(0.55, 0.95, 0.60)
	_def_bar.bottom_color = Color(0.20, 0.62, 0.30)
	_def_bar.ticks = 4
	dcol.add_child(_def_bar)
	var cap := _plain_label(Strings.INVASION_SAFETY, 14, Color(0.85, 0.85, 0.88))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dcol.add_child(cap)


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
	var weather := get_tree().get_first_node_in_group("weather")
	var wid: String = weather.icon_id() if weather != null else ""
	if wid != _clock_weather:
		_clock_weather = wid
		_clock_icon.queue_redraw()


func _on_invasion_updated(active: bool, wave: int, waves: int, alive: int, safety: float) -> void:
	_def_box.visible = active
	if not active:
		return
	_def_label.text = Strings.INVASION_WAVE % [maxi(wave, 1), waves, alive]
	var level := clampf(safety / 100.0, 0.0, 1.0)
	_def_bar.value = level
	_def_bar.top_color = Color(0.55, 0.95, 0.60).lerp(Color(1.0, 0.50, 0.40), 1.0 - level)
	_def_bar.bottom_color = Color(0.20, 0.62, 0.30).lerp(Color(0.72, 0.10, 0.12), 1.0 - level)


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
	mini.position = Vector2(6, 6)
	mini.size = Vector2(188, 188)
	_mini_frame.add_child(mini)
	_mini_frame.add_child(_map_rim(Rect2(0, 0, 200, 200), 18, 6))     # rounded rim over the corners of the map
	# buttons left of the minimap: zoom in, zoom out, open the big map (they work with a mouse or a finger)
	var tools := [["+", func(): _zoom_minimap(1), "Μεγέθυνση  [+]"], ["−", func(): _zoom_minimap(-1), "Σμίκρυνση  [-]"],
			["M", func(): toggle_big_map(), "Χάρτης  [M]"]]
	for i in tools.size():
		var b := UiKit.button(tools[i][0], tools[i][1], 32.0, 20)
		b.custom_minimum_size = Vector2(32, 32)
		b.size = Vector2(32, 32)
		b.position = Vector2(-38, 4 + i * 38)
		b.tooltip_text = tools[i][2]
		_mini_frame.add_child(b)

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
	frame.add_child(_map_rim(Rect2(4, 38, 576, 576), 18, 8))
	var legend := _plain_label(Strings.MAP_LEGEND, 13, Color(0.9, 0.88, 0.8))
	legend.position = Vector2(0, 618)
	legend.size = Vector2(584, 24)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(legend)
	var close := UiKit.button("✕", func(): toggle_big_map(), 36.0, 18)
	close.custom_minimum_size = Vector2(36, 34)
	close.size = Vector2(36, 34)
	close.position = Vector2(540, 8)
	close.tooltip_text = "Κλείσιμο  [M]"
	frame.add_child(close)


func _map_frame_style() -> StyleBoxFlat:
	var sb := UiKit.panel_style(0.92)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb


## A rounded ring drawn over a square picture (a map) to give it rounded corners and a light rim.
func _map_rim(rect: Rect2, radius: int, width: int) -> Panel:
	var rim := Panel.new()
	rim.position = rect.position
	rim.size = rect.size
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(UiKit.GLASS.r, UiKit.GLASS.g, UiKit.GLASS.b, 1.0)
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	rim.add_theme_stylebox_override("panel", sb)
	# a thin gold line on the inner edge of the ring
	var line := Panel.new()
	line.position = Vector2(width - 2, width - 2)
	line.size = rect.size - Vector2(width - 2, width - 2) * 2.0
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lb := StyleBoxFlat.new()
	lb.bg_color = Color(0, 0, 0, 0)
	lb.border_color = Color(1.0, 0.82, 0.38, 0.75)
	lb.set_border_width_all(2)
	lb.set_corner_radius_all(maxi(2, radius - width + 2))
	lb.anti_aliasing = true
	line.add_theme_stylebox_override("panel", lb)
	rim.add_child(line)
	return rim


func _build_windows() -> void:
	_hero = HeroWindow.new()
	_hero.player = _player
	add_child(_hero)
	_shop = ShopWindow.new()
	add_child(_shop)
	_fishing = Fishing.new()
	add_child(_fishing)
	if _player:
		_player.talents_changed.connect(_update_hint)
		_player.leveled_up.connect(func(_l): _update_hint())
	_update_hint()


## The key hint under the action bar also tells when talent points are waiting.
func _update_hint() -> void:
	var free := _player.talent_points_free() if _player else 0
	# the key list moved to the "i" help page; only the talent-point reminder stays (and only while there are points)
	_hint.text = Strings.HINT_TALENT_POINTS.strip_edges() % free + "   [T]" if free > 0 else ""
	_hint.visible = free > 0
	_hint.reset_size()                 # shrink the pill to the new text and keep it centred
	_hint.offset_left = -_hint.size.x / 2.0
	_hint.offset_right = _hint.size.x / 2.0


## Opens a shop window (called by shopkeepers after their greeting).
func open_shop(shop_id: String, player: Player) -> void:
	_shop.open(shop_id, player)


## Starts fishing: George stands at `stand` and casts toward the water spot `target` (the dock calls this).
func start_fishing(player: Player, stand: Vector3, target: Vector3) -> void:
	_fishing.begin(player, stand, target)


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
