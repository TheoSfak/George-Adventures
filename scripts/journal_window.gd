class_name JournalWindow
extends PanelContainer
## Modern dark-glass window for Achievements & Bestiary Lore.
## Features:
##   - Tab 1: 37+ Achievements with progress bars, filters, and reward badges
##   - Tab 2: Bestiary with interactive 3D turntable model viewer, Greek lore,
##            tactical weaknesses, combat stats, and loot drop rate tables.

const AchievementDataClass := preload("res://scripts/achievement_data.gd")
const BestiaryDataClass := preload("res://scripts/bestiary_data.gd")
const JournalManagerClass := preload("res://scripts/journal_manager.gd")

var _manager: Node
var _player: Player
var _current_tab := "achievements" # "achievements" or "bestiary"
var _ach_filter := "all"
var _bestiary_filter := "all"
var _selected_bestiary_kind := "warrior"

# Main Layout
var _content_box: VBoxContainer
var _tab_ach_btn: Button
var _tab_bes_btn: Button
var _ach_view: VBoxContainer
var _bestiary_view: HBoxContainer

# Bestiary 3D Viewport & Nodes
var _sub_viewport: SubViewport
var _turntable: Node3D
var _cam: Camera3D
var _model_holder: Node3D
var _is_dragging_3d := false
var _drag_start_x := 0.0

# Bestiary Details Controls
var _bes_name_lbl: Label
var _bes_family_lbl: Label
var _bes_kills_lbl: Label
var _bes_tier_lbl: Label
var _bes_lore_text: RichTextLabel
var _bes_stats_box: VBoxContainer
var _bes_weakness_text: Label
var _bes_drops_box: HBoxContainer
var _bes_list_box: VBoxContainer

func _ready() -> void:
	name = "JournalWindow"
	visible = false
	custom_minimum_size = Vector2(940, 610)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	var bg_style := UiKit.panel_style(0.95)
	bg_style.border_color = Color(1.0, 0.84, 0.35, 0.90)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(18)
	bg_style.shadow_size = 16
	bg_style.shadow_color = Color(0, 0, 0, 0.75)
	bg_style.content_margin_left = 22
	bg_style.content_margin_right = 22
	bg_style.content_margin_top = 18
	bg_style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", bg_style)

	if _content_box == null:
		_build_ui()


func _process(delta: float) -> void:
	if visible and _current_tab == "bestiary" and _turntable != null and not _is_dragging_3d:
		_turntable.rotation.y += delta * 0.75


func open(player: Player, tab: String = "achievements") -> void:
	if _content_box == null:
		_build_ui()
	_player = player
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		_manager = tree.get_first_node_in_group("journal_manager")
		if _manager and _manager.has_method("check_achievements"):
			_manager.check_achievements()

	_current_tab = tab
	visible = true
	Sfx.ui("window_open")
	_refresh_tab_display()


func close() -> void:
	if not visible:
		return
	visible = false
	Sfx.ui("window_close")


func toggle(player: Player, tab: String = "achievements") -> void:
	if visible and _current_tab == tab:
		close()
	elif visible and _current_tab != tab:
		_current_tab = tab
		_refresh_tab_display()
	else:
		open(player, tab)


func is_open() -> bool:
	return visible


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	# --- Header Bar ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var icon_badge := UiKit.label("📜", 26, Color(1.0, 0.84, 0.35))
	header.add_child(icon_badge)

	var title := Label.new()
	title.text = "ΗΜΕΡΟΛΟΓΙΟ: ΕΠΙΤΕΥΓΜΑΤΑ & ΤΕΡΑΤΟΛΟΓΙΟ"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(34, 34)
	close_btn.tooltip_text = "Κλείσιμο [J / Esc]"
	var close_sb := UiKit.panel_style(0.60)
	close_sb.set_corner_radius_all(8)
	close_btn.add_theme_stylebox_override("normal", close_sb)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	# --- Main Navigation Tabs ---
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 10)
	root.add_child(tabs_row)

	_tab_ach_btn = Button.new()
	_tab_ach_btn.text = "🏆 Επιτεύγματα Ηρώων"
	_tab_ach_btn.custom_minimum_size = Vector2(210, 38)
	_tab_ach_btn.pressed.connect(func():
		_current_tab = "achievements"
		_refresh_tab_display()
	)
	tabs_row.add_child(_tab_ach_btn)

	_tab_bes_btn = Button.new()
	_tab_bes_btn.text = "📖 Τερατολόγιο & Lore"
	_tab_bes_btn.custom_minimum_size = Vector2(210, 38)
	_tab_bes_btn.pressed.connect(func():
		_current_tab = "bestiary"
		_refresh_tab_display()
	)
	tabs_row.add_child(_tab_bes_btn)

	# Divider line
	var sep := ColorRect.new()
	sep.color = Color(1.0, 0.84, 0.35, 0.25)
	sep.custom_minimum_size = Vector2(0, 2)
	root.add_child(sep)

	# Content Area
	_content_box = VBoxContainer.new()
	_content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content_box)

	_build_achievements_view()
	_build_bestiary_view()


# =============================================================================
# ACHIEVEMENTS VIEW
# =============================================================================

func _build_achievements_view() -> void:
	_ach_view = VBoxContainer.new()
	_ach_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ach_view.add_theme_constant_override("separation", 10)
	_content_box.add_child(_ach_view)

	# Filter bar and progress summary
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	_ach_view.add_child(top_bar)

	var filter_lbl := Label.new()
	filter_lbl.text = "Κατηγορία:"
	filter_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
	top_bar.add_child(filter_lbl)

	for cat_id in AchievementDataClass.CATEGORIES:
		var btn := Button.new()
		btn.text = AchievementDataClass.CATEGORIES[cat_id]
		btn.custom_minimum_size = Vector2(0, 28)
		btn.pressed.connect(func():
			_ach_filter = cat_id
			_render_achievements_list()
		)
		top_bar.add_child(btn)

	# Scroll list of achievements
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_ach_view.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "AchievementsList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)


func _render_achievements_list() -> void:
	if not _manager:
		var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree != null:
			_manager = tree.get_first_node_in_group("journal_manager")

	var list := _ach_view.find_child("AchievementsList", true, false) as VBoxContainer
	if not list:
		return
	for c in list.get_children():
		c.queue_free()

	var all_achs := AchievementDataClass.ACHIEVEMENTS
	var unlocked_count := 0
	for a in all_achs:
		if _manager and _manager.is_achievement_unlocked(a["id"]):
			unlocked_count += 1

	var filtered := AchievementDataClass.get_by_category(_ach_filter)

	for ach in filtered:
		var aid: String = ach["id"]
		var is_unlocked: bool = _manager != null and _manager.is_achievement_unlocked(aid)
		var cur_val: int = _manager.get_achievement_progress(ach) if _manager else 0
		var target: int = int(ach.get("target", 1))

		var card := PanelContainer.new()
		var card_style := UiKit.panel_style(0.88 if is_unlocked else 0.65)
		card_style.set_corner_radius_all(10)
		card_style.border_color = Color(1.0, 0.84, 0.35, 0.85) if is_unlocked else Color(0.45, 0.45, 0.52, 0.40)
		card_style.set_border_width_all(1)
		card_style.content_margin_left = 12
		card_style.content_margin_right = 14
		card_style.content_margin_top = 8
		card_style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", card_style)
		list.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)

		# Icon Box
		var icon_box := PanelContainer.new()
		icon_box.custom_minimum_size = Vector2(44, 44)
		var ib_style := UiKit.panel_style(0.90)
		ib_style.set_corner_radius_all(8)
		ib_style.border_color = Color(1.0, 0.84, 0.35, 0.9) if is_unlocked else Color(0.35, 0.35, 0.40, 0.5)
		ib_style.set_border_width_all(1)
		icon_box.add_theme_stylebox_override("panel", ib_style)
		var icon_lbl := Label.new()
		icon_lbl.text = ach.get("icon", "🏆")
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 20)
		icon_box.add_child(icon_lbl)
		row.add_child(icon_box)

		# Title & Desc & Bar
		var mid := VBoxContainer.new()
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.add_theme_constant_override("separation", 3)
		row.add_child(mid)

		var title_row := HBoxContainer.new()
		mid.add_child(title_row)

		var t_lbl := Label.new()
		t_lbl.text = ach["title"]
		t_lbl.add_theme_font_size_override("font_size", 16)
		t_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35) if is_unlocked else Color(0.92, 0.92, 0.95))
		title_row.add_child(t_lbl)

		var d_lbl := Label.new()
		d_lbl.text = ach["desc"]
		d_lbl.add_theme_font_size_override("font_size", 13)
		d_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mid.add_child(d_lbl)

		# Progress bar
		var p_row := HBoxContainer.new()
		p_row.add_theme_constant_override("separation", 8)
		mid.add_child(p_row)

		var pbar := ProgressBar.new()
		pbar.custom_minimum_size = Vector2(0, 8)
		pbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pbar.show_percentage = false
		pbar.max_value = target
		pbar.value = clampi(cur_val, 0, target)
		p_row.add_child(pbar)

		var p_lbl := Label.new()
		p_lbl.text = "%d / %d" % [clampi(cur_val, 0, target), target]
		p_lbl.add_theme_font_size_override("font_size", 12)
		p_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
		p_row.add_child(p_lbl)

		# Right: Rewards & Status
		var right := VBoxContainer.new()
		right.custom_minimum_size = Vector2(160, 0)
		right.alignment = BoxContainer.ALIGNMENT_CENTER
		right.add_theme_constant_override("separation", 4)
		row.add_child(right)

		var rew: Dictionary = ach.get("reward", {})
		var rew_lbl := Label.new()
		rew_lbl.text = "+%d XP  +%d 💰" % [int(rew.get("xp", 0)), int(rew.get("gold", 0))]
		rew_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rew_lbl.add_theme_font_size_override("font_size", 12)
		rew_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
		right.add_child(rew_lbl)

		var status_badge := Label.new()
		status_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_badge.add_theme_font_size_override("font_size", 13)
		if is_unlocked:
			status_badge.text = "✓ Ολοκληρώθηκε"
			status_badge.add_theme_color_override("font_color", Color(0.35, 0.95, 0.45))
		else:
			status_badge.text = "Σε εξέλιξη"
			status_badge.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
		right.add_child(status_badge)


# =============================================================================
# BESTIARY VIEW (3D TURNTABLE & LORE)
# =============================================================================

func _build_bestiary_view() -> void:
	_bestiary_view = HBoxContainer.new()
	_bestiary_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bestiary_view.add_theme_constant_override("separation", 16)
	_content_box.add_child(_bestiary_view)

	# --- Left Column: List of Monsters ---
	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(260, 0)
	left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 8)
	_bestiary_view.add_child(left_col)

	var filter_row := HBoxContainer.new()
	left_col.add_child(filter_row)

	var cat_btn := OptionButton.new()
	cat_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for cat_id in BestiaryDataClass.CATEGORIES:
		cat_btn.add_item(BestiaryDataClass.CATEGORIES[cat_id])
	cat_btn.item_selected.connect(func(idx: int):
		var keys := BestiaryDataClass.CATEGORIES.keys()
		if idx < keys.size():
			_bestiary_filter = keys[idx]
			_render_bestiary_list()
	)
	filter_row.add_child(cat_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(scroll)

	_bes_list_box = VBoxContainer.new()
	_bes_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bes_list_box.add_theme_constant_override("separation", 4)
	scroll.add_child(_bes_list_box)

	# --- Right Column: 3D Turntable, Stats & Lore ---
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 10)
	_bestiary_view.add_child(right_col)

	# Top Section: 3D Turntable on Left, Lore & Info on Right
	var top_split := HBoxContainer.new()
	top_split.custom_minimum_size = Vector2(0, 240)
	top_split.add_theme_constant_override("separation", 14)
	right_col.add_child(top_split)

	# 3D SubViewport Container
	var vp_container := SubViewportContainer.new()
	vp_container.custom_minimum_size = Vector2(250, 240)
	vp_container.stretch = true

	var vp_frame := PanelContainer.new()
	var vp_style := UiKit.panel_style(0.85)
	vp_style.set_corner_radius_all(12)
	vp_style.border_color = Color(1.0, 0.84, 0.35, 0.70)
	vp_style.set_border_width_all(2)
	vp_frame.add_theme_stylebox_override("panel", vp_style)
	vp_frame.add_child(vp_container)
	top_split.add_child(vp_frame)

	_sub_viewport = SubViewport.new()
	_sub_viewport.size = Vector2i(250, 240)
	_sub_viewport.transparent_bg = true
	_sub_viewport.own_world_3d = true
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_container.add_child(_sub_viewport)

	_setup_3d_viewport()

	# Mouse drag to rotate monster
	vp_container.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_is_dragging_3d = mb.pressed
				_drag_start_x = mb.position.x
		elif event is InputEventMouseMotion and _is_dragging_3d:
			var mm := event as InputEventMouseMotion
			if _turntable:
				_turntable.rotation.y += mm.relative.x * 0.015
	)

	# Info & Lore on Right of Top Section
	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 6)
	top_split.add_child(info_box)

	_bes_name_lbl = Label.new()
	_bes_name_lbl.add_theme_font_size_override("font_size", 20)
	_bes_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
	info_box.add_child(_bes_name_lbl)

	var badges_row := HBoxContainer.new()
	badges_row.add_theme_constant_override("separation", 10)
	info_box.add_child(badges_row)

	_bes_family_lbl = Label.new()
	_bes_family_lbl.add_theme_font_size_override("font_size", 13)
	_bes_family_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.95))
	badges_row.add_child(_bes_family_lbl)

	_bes_kills_lbl = Label.new()
	_bes_kills_lbl.add_theme_font_size_override("font_size", 13)
	_bes_kills_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))
	badges_row.add_child(_bes_kills_lbl)

	_bes_tier_lbl = Label.new()
	_bes_tier_lbl.add_theme_font_size_override("font_size", 13)
	_bes_tier_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	badges_row.add_child(_bes_tier_lbl)

	_bes_lore_text = RichTextLabel.new()
	_bes_lore_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bes_lore_text.bbcode_enabled = true
	_bes_lore_text.add_theme_font_size_override("normal_font_size", 13)
	_bes_lore_text.add_theme_color_override("default_color", Color(0.92, 0.92, 0.95))
	info_box.add_child(_bes_lore_text)

	# Bottom Section: Combat Stats, Tactical Weaknesses & Loot Table
	var bot_box := VBoxContainer.new()
	bot_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bot_box.add_theme_constant_override("separation", 8)
	right_col.add_child(bot_box)

	var bot_split := HBoxContainer.new()
	bot_split.add_theme_constant_override("separation", 14)
	bot_box.add_child(bot_split)

	# Stats column
	var stats_panel := PanelContainer.new()
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sp_style := UiKit.panel_style(0.80)
	sp_style.set_corner_radius_all(10)
	sp_style.content_margin_left = 12
	sp_style.content_margin_right = 12
	sp_style.content_margin_top = 8
	sp_style.content_margin_bottom = 8
	stats_panel.add_theme_stylebox_override("panel", sp_style)
	bot_split.add_child(stats_panel)

	_bes_stats_box = VBoxContainer.new()
	_bes_stats_box.add_theme_constant_override("separation", 4)
	stats_panel.add_child(_bes_stats_box)

	# Weakness & Drops column
	var weak_panel := PanelContainer.new()
	weak_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var wp_style := UiKit.panel_style(0.80)
	wp_style.set_corner_radius_all(10)
	wp_style.content_margin_left = 12
	wp_style.content_margin_right = 12
	wp_style.content_margin_top = 8
	wp_style.content_margin_bottom = 8
	weak_panel.add_theme_stylebox_override("panel", wp_style)
	bot_split.add_child(weak_panel)

	var weak_box := VBoxContainer.new()
	weak_box.add_theme_constant_override("separation", 6)
	weak_panel.add_child(weak_box)

	var w_title := Label.new()
	w_title.text = "🎯 Τακτική Αδυναμία & Αντιμετώπιση:"
	w_title.add_theme_font_size_override("font_size", 14)
	w_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	weak_box.add_child(w_title)

	_bes_weakness_text = Label.new()
	_bes_weakness_text.add_theme_font_size_override("font_size", 13)
	_bes_weakness_text.add_theme_color_override("font_color", Color(0.92, 0.90, 0.85))
	_bes_weakness_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weak_box.add_child(_bes_weakness_text)

	var d_title := Label.new()
	d_title.text = "🎁 Πιθανά Λάφυρα (Drop Rates):"
	d_title.add_theme_font_size_override("font_size", 14)
	d_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	weak_box.add_child(d_title)

	_bes_drops_box = HBoxContainer.new()
	_bes_drops_box.add_theme_constant_override("separation", 8)
	weak_box.add_child(_bes_drops_box)


func _setup_3d_viewport() -> void:
	if not _sub_viewport:
		return

	# Isolated World3D & Camera
	_cam = Camera3D.new()
	_cam.fov = 38.0
	_cam.position = Vector3(0.0, 1.25, 3.4)
	_cam.look_at_from_position(_cam.position, Vector3(0.0, 0.85, 0.0), Vector3.UP)
	_sub_viewport.add_child(_cam)

	# Key Light (Warm Sun)
	var light1 := DirectionalLight3D.new()
	light1.rotation_degrees = Vector3(-35.0, 45.0, 0.0)
	light1.light_color = Color(1.0, 0.95, 0.85)
	light1.light_energy = 1.3
	_sub_viewport.add_child(light1)

	# Rim Light (Cool Azure)
	var light2 := DirectionalLight3D.new()
	light2.rotation_degrees = Vector3(25.0, -135.0, 0.0)
	light2.light_color = Color(0.40, 0.60, 0.95)
	light2.light_energy = 0.9
	_sub_viewport.add_child(light2)

	# Ambient World Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.10, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.45)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	_sub_viewport.add_child(we)

	# Turntable & Stone Podium
	_turntable = Node3D.new()
	_sub_viewport.add_child(_turntable)

	var podium := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.15
	cyl.bottom_radius = 1.25
	cyl.height = 0.15
	podium.mesh = cyl
	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.20, 0.22, 0.26)
	p_mat.roughness = 0.85
	podium.material_override = p_mat
	podium.position = Vector3(0.0, -0.075, 0.0)
	_turntable.add_child(podium)

	_model_holder = Node3D.new()
	_turntable.add_child(_model_holder)


func _render_bestiary_list() -> void:
	if not _manager:
		var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree != null:
			_manager = tree.get_first_node_in_group("journal_manager")

	for c in _bes_list_box.get_children():
		c.queue_free()

	var entries := BestiaryDataClass.get_by_category(_bestiary_filter)

	for e in entries:
		var kid: String = e["kind_id"]
		var kills: int = int(_manager.get_kill_count(kid)) if _manager else 0
		var tier := BestiaryDataClass.get_unlock_tier(kills, e.get("is_boss", false))

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var dname: String = e["name"] if tier >= 1 else "??? Άγνωστο Πλάσμα"
		btn.text = "%s (%d)" % [dname, kills]

		var sb := UiKit.panel_style(0.85 if kid == _selected_bestiary_kind else 0.55)
		sb.set_corner_radius_all(6)
		if kid == _selected_bestiary_kind:
			sb.border_color = Color(1.0, 0.84, 0.35, 0.95)
			sb.set_border_width_all(2)
		btn.add_theme_stylebox_override("normal", sb)

		btn.pressed.connect(func():
			_selected_bestiary_kind = kid
			_render_bestiary_list()
			_display_bestiary_entry(kid)
		)
		_bes_list_box.add_child(btn)

	_display_bestiary_entry(_selected_bestiary_kind)


func _display_bestiary_entry(kind_id: String) -> void:
	if not _manager:
		var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree != null:
			_manager = tree.get_first_node_in_group("journal_manager")

	var e := BestiaryDataClass.get_entry(kind_id)
	if e.is_empty():
		return

	var kills: int = int(_manager.get_kill_count(kind_id)) if _manager else 0
	var tier := BestiaryDataClass.get_unlock_tier(kills, e.get("is_boss", false))

	# Header details
	if tier >= 1:
		_bes_name_lbl.text = e["name"]
		_bes_family_lbl.text = "Φατρία: %s" % BestiaryDataClass.CATEGORIES.get(e["category"], "Πλάσματα")
		_bes_kills_lbl.text = "Εξοντώθηκαν: %d" % kills
		_bes_tier_lbl.text = "Βαθμός Γνώσης: %d/3" % tier
	else:
		_bes_name_lbl.text = "??? Άγνωστο Πλάσμα"
		_bes_family_lbl.text = "Φατρία: Άγνωστη"
		_bes_kills_lbl.text = "Εξοντώθηκαν: 0"
		_bes_tier_lbl.text = "Βαθμός Γνώσης: 0/3 (Μη ανακαλυφθέν)"

	# Lore Box
	if tier >= 3:
		_bes_lore_text.text = "[color=#f0e6d2]%s[/color]" % e.get("lore", "")
	elif tier >= 1:
		_bes_lore_text.text = "[color=#d8d8d8]Έχεις αντιμετωπίσει αυτό το πλάσμα αλλά απαιτούνται περισσότερες εξοντώσεις (15+) για την πλήρη καταγραφή της ιστορίας και των συνηθειών του.[/color]"
	else:
		_bes_lore_text.text = "[color=#888888]Αυτό το πλάσμα δεν έχει εξοντωθεί ποτέ ακόμη. Εξερεύνησε τον Άγιο Βλάση, πολέμησε και νίκησέ το για να ξεκλειδώσεις πληροφορίες στο Τερατολόγιο.[/color]"

	# Stats Column
	for c in _bes_stats_box.get_children():
		c.queue_free()

	var st_title := Label.new()
	st_title.text = "📊 Στατιστικά Μάχης:"
	st_title.add_theme_font_size_override("font_size", 14)
	st_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	_bes_stats_box.add_child(st_title)

	if tier >= 2:
		var st: Dictionary = e.get("stats", {})
		_add_stat_row("Ζωή (HP):", "%d" % int(st.get("hp", 0)), Color(1.0, 0.45, 0.45))
		_add_stat_row("Ζημιά (DMG):", "%d" % int(st.get("damage", 0)), Color(1.0, 0.85, 0.35))
		_add_stat_row("Ταχύτητα:", "%.1f m/s" % float(st.get("speed", 0)), Color(0.45, 0.85, 1.0))
		_add_stat_row("Στυλ Μάχης:", String(st.get("style", "Melee")), Color(0.9, 0.9, 0.9))
		_add_stat_row("Άμυνα:", String(st.get("defense", "Κανονική")), Color(0.85, 0.70, 0.95))
	else:
		var hidden_lbl := Label.new()
		hidden_lbl.text = "Απαιτούνται 5+ εξοντώσεις για αποκάλυψη στατιστικών."
		hidden_lbl.add_theme_font_size_override("font_size", 12)
		hidden_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
		_bes_stats_box.add_child(hidden_lbl)

	# Tactical Weakness
	if tier >= 3:
		_bes_weakness_text.text = e.get("weakness", "Καμία γνωστή αδυναμία.")
	else:
		_bes_weakness_text.text = "Απαιτείται βαθμός γνώσης 3/3 (15+ kills) για τις αδυναμίες."

	# Drops Box
	for c in _bes_drops_box.get_children():
		c.queue_free()

	if tier >= 2:
		var drops: Array = e.get("drops", [])
		for d in drops:
			var pill := PanelContainer.new()
			var p_sb := UiKit.panel_style(0.90)
			p_sb.set_corner_radius_all(6)
			p_sb.content_margin_left = 8
			p_sb.content_margin_right = 8
			p_sb.content_margin_top = 4
			p_sb.content_margin_bottom = 4
			pill.add_theme_stylebox_override("panel", p_sb)
			var l := Label.new()
			l.text = "%s (%s)" % [d["item"], d["chance"]]
			l.add_theme_font_size_override("font_size", 12)
			l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.80))
			pill.add_child(l)
			_bes_drops_box.add_child(pill)
	else:
		var hd_lbl := Label.new()
		hd_lbl.text = "Απαιτούνται 5+ εξοντώσεις για τα ποσοστά drop rates."
		hd_lbl.add_theme_font_size_override("font_size", 12)
		hd_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
		_bes_drops_box.add_child(hd_lbl)

	# Update 3D Model in Turntable
	_display_3d_model(e, tier)


func _add_stat_row(label_text: String, val_text: String, val_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.80, 0.80, 0.85))
	row.add_child(l)
	var v := Label.new()
	v.text = val_text
	v.add_theme_font_size_override("font_size", 12)
	v.add_theme_color_override("font_color", val_color)
	row.add_child(v)
	_bes_stats_box.add_child(row)


func _display_3d_model(entry: Dictionary, tier: int) -> void:
	if not _model_holder:
		return

	# Clear previous model
	for c in _model_holder.get_children():
		c.queue_free()

	var mpath: String = entry.get("model_path", "")
	if mpath.is_empty() or not ResourceLoader.exists(mpath):
		return

	var scene: PackedScene = load(mpath)
	if not scene:
		return

	var model: Node3D = scene.instantiate()
	_model_holder.add_child(model)

	var sc: float = float(entry.get("model_scale", 1.0)) * 0.80
	model.scale = Vector3(sc, sc, sc)

	# If undiscovered (tier 0), make it a dark silhouette
	if tier == 0:
		var shadow_mat := StandardMaterial3D.new()
		shadow_mat.albedo_color = Color(0.02, 0.02, 0.05, 1.0)
		shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = shadow_mat
		return

	# Character Props (Adventurers)
	var show_nodes: Array = entry.get("show_nodes", [])
	if show_nodes.size() > 0:
		CharacterProps.apply(model, show_nodes)

	# Weapons attachments for Skeletons
	var skel := model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	if not skel:
		skel = model.find_child("Skeleton3D", true, false) as Skeleton3D

	if skel:
		var wpath: String = entry.get("weapon_path", "")
		if not wpath.is_empty() and ResourceLoader.exists(wpath):
			_attach_bone(skel, "hand.R", wpath)
		var opath: String = entry.get("offhand_path", "")
		if not opath.is_empty() and ResourceLoader.exists(opath):
			_attach_bone(skel, "hand.L", opath)

	# Tint wash
	var tint: Color = entry.get("tint_color", Color(0, 0, 0, 0))
	if tint.a > 0.05:
		var wash := StandardMaterial3D.new()
		wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wash.albedo_color = tint
		wash.cull_mode = BaseMaterial3D.CULL_BACK
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = wash

	# Animation Player
	var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		var anim_name: String = entry.get("anim_idle", "Idle")
		if anim.has_animation(anim_name):
			anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
			anim.play(anim_name)


func _attach_bone(skeleton: Skeleton3D, bone: String, path: String) -> void:
	if skeleton.find_bone(bone) < 0:
		return
	var holder := BoneAttachment3D.new()
	holder.bone_name = bone
	skeleton.add_child(holder)
	var sc: PackedScene = load(path)
	if sc:
		holder.add_child(sc.instantiate())


func _refresh_tab_display() -> void:
	if _current_tab == "achievements":
		_ach_view.visible = true
		_bestiary_view.visible = false
		_style_tab_btn(_tab_ach_btn, true)
		_style_tab_btn(_tab_bes_btn, false)
		_render_achievements_list()
	else:
		_ach_view.visible = false
		_bestiary_view.visible = true
		_style_tab_btn(_tab_ach_btn, false)
		_style_tab_btn(_tab_bes_btn, true)
		_render_bestiary_list()


func _style_tab_btn(btn: Button, active: bool) -> void:
	var sb := UiKit.panel_style(0.95 if active else 0.55)
	sb.set_corner_radius_all(8)
	if active:
		sb.border_color = Color(1.0, 0.84, 0.35, 1.0)
		sb.set_border_width_all(2)
		btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	else:
		sb.border_color = Color(0.4, 0.4, 0.45, 0.4)
		sb.set_border_width_all(1)
		btn.add_theme_color_override("font_color", Color(0.80, 0.80, 0.85))
	btn.add_theme_stylebox_override("normal", sb)
