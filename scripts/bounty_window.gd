class_name BountyWindow
extends PanelContainer
## Interactive Village Bounty Board & Hunting Contracts Window.
## Displays available contracts on parchment-styled cards, progress on active hunts,
## Hunter Rank progress, and allows claiming bounties.

signal closed

const BountyDataClass := preload("res://scripts/bounty_data.gd")

var _player: Player
var _manager: Node
var _open_time := 0.0
var _title_label: Label
var _rank_label: Label
var _cards_container: HBoxContainer
var _empty_label: Label

func _ready() -> void:
	name = "BountyWindow"
	visible = false
	add_theme_stylebox_override("panel", UiKit.panel_style(0.96))
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	# 1. Top Header Area
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label = UiKit.label("📜 ΠΙΝΑΚΑΣ ΕΠΙΚΗΡΥΞΕΩΝ & ΣΥΜΒΟΛΑΙΑ", 26, UiKit.GOLD_TEXT)
	title_box.add_child(_title_label)

	_rank_label = UiKit.label("", 16, UiKit.CREAM)
	title_box.add_child(_rank_label)
	header.add_child(title_box)

	var close_btn := UiKit.button("✕", close, 45, 20)
	header.add_child(close_btn)

	# 2. Main Contracts Cards Display (3 Column Cards)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(980, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var center_box := CenterContainer.new()
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center_box)

	_cards_container = HBoxContainer.new()
	_cards_container.add_theme_constant_override("separation", 16)
	center_box.add_child(_cards_container)

	_empty_label = UiKit.label("Δεν υπάρχουν διαθέσιμα συμβόλαια αυτή τη στιγμή.", 18, UiKit.MUTED)
	_empty_label.visible = false
	center_box.add_child(_empty_label)

	# 3. Bottom Action Footer
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	foot.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(foot)

	var refresh_btn := UiKit.button("🔄 Ανανέωση Πίνακα", _on_refresh_pressed, 200, 16)
	foot.add_child(refresh_btn)

	var close_foot_btn := UiKit.button("Κλείσιμο [Esc / R]", close, 180, 16)
	foot.add_child(close_foot_btn)


func _get_manager() -> Node:
	if _manager != null:
		return _manager
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		_manager = tree.get_first_node_in_group("bounty_manager")
	return _manager


func open(player: Player) -> void:
	_player = player
	_open_time = Time.get_ticks_msec() / 1000.0
	visible = true
	var mgr := _get_manager()
	if mgr != null and not mgr.bounties_updated.is_connected(_refresh_ui):
		mgr.bounties_updated.connect(_refresh_ui)
	_refresh_ui()
	Sfx.ui("window_open")


func close() -> void:
	if not visible:
		return
	visible = false
	Sfx.ui("window_close")
	closed.emit()


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		if Time.get_ticks_msec() / 1000.0 - _open_time > 0.25:
			close()
			get_viewport().set_input_as_handled()


func _refresh_ui() -> void:
	var mgr := _get_manager()
	if mgr == null:
		return

	# Update hunter rank header
	var rank_info: Dictionary = BountyDataClass.get_hunter_rank(mgr.get("completed_count"))
	_rank_label.text = "Βαθμός Κυνηγού: %s %s   |   Ολοκληρωμένα Συμβόλαια: %d" % [
		rank_info["badge"], rank_info["title"], int(mgr.get("completed_count"))
	]

	# Clear previous cards
	for child in _cards_container.get_children():
		child.queue_free()

	# Combine active contracts and available board contracts
	var displayed_bounties: Array[Dictionary] = []
	for a in mgr.active_bounties:
		var copy := (a as Dictionary).duplicate(true)
		copy["_is_active"] = true
		displayed_bounties.append(copy)

	for b in mgr.available_bounties:
		var copy := (b as Dictionary).duplicate(true)
		copy["_is_active"] = false
		displayed_bounties.append(copy)

	if displayed_bounties.is_empty():
		_empty_label.visible = true
		_cards_container.visible = false
		return

	_empty_label.visible = false
	_cards_container.visible = true

	for contract in displayed_bounties:
		var card := _build_contract_card(contract)
		_cards_container.add_child(card)


func _build_contract_card(c: Dictionary) -> Control:
	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(305, 400)

	var tier_key: String = c.get("tier", "bronze")
	var tier_info: Dictionary = BountyDataClass.TIERS.get(tier_key, BountyDataClass.TIERS["bronze"])
	var tier_color: Color = tier_info["color"]
	var is_active: bool = bool(c.get("_is_active", false))
	var is_ready: bool = bool(c.get("ready", false))

	# Styled parchment / dark glass box with tier border
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.13, 0.94) if not is_ready else Color(0.12, 0.16, 0.10, 0.96)
	sb.border_color = tier_color if not is_ready else Color(0.4, 0.9, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.shadow_size = 10
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	card_panel.add_theme_stylebox_override("panel", sb)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card_panel.add_child(v)

	# Tier badge top row
	var badge_row := HBoxContainer.new()
	var tier_lbl := UiKit.label("[%s]" % tier_info["tag"], 13, tier_color)
	badge_row.add_child(tier_lbl)

	if is_active:
		var active_badge := UiKit.label("• ΣΕ ΕΞΕΛΙΞΗ", 12, Color(0.4, 0.8, 1.0))
		active_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		active_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge_row.add_child(active_badge)
	v.add_child(badge_row)

	# Contract Title
	var title_lbl := Label.new()
	title_lbl.text = String(c.get("title", ""))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", UiKit.GOLD_TEXT)
	title_lbl.custom_minimum_size.y = 48
	v.add_child(title_lbl)

	# Narrative Description
	var desc_lbl := Label.new()
	desc_lbl.text = String(c.get("desc", ""))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", UiKit.MUTED)
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc_lbl)

	# Objective & Progress Area
	var prog_box := VBoxContainer.new()
	prog_box.add_theme_constant_override("separation", 4)
	v.add_child(prog_box)

	var target_name: String = c.get("target_name", "Στόχος")
	var count: int = int(c.get("count", 1))
	var cur: int = int(c.get("progress", 0)) if is_active else 0

	var prog_text := "🎯 %s: %d / %d" % [target_name, cur, count] if is_active else "🎯 Στόχος: %d %s" % [count, target_name]
	var prog_col := Color(0.4, 0.9, 0.4) if is_ready else (Color(1.0, 0.85, 0.4) if is_active else UiKit.CREAM)
	var prog_lbl := UiKit.label(prog_text, 14, prog_col)
	prog_box.add_child(prog_lbl)

	# Rewards box
	var rew_panel := PanelContainer.new()
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = Color(1, 1, 1, 0.05)
	rsb.set_corner_radius_all(8)
	rsb.content_margin_left = 10
	rsb.content_margin_right = 10
	rsb.content_margin_top = 6
	rsb.content_margin_bottom = 6
	rew_panel.add_theme_stylebox_override("panel", rsb)

	var rew_v := VBoxContainer.new()
	rew_v.add_theme_constant_override("separation", 2)
	rew_panel.add_child(rew_v)

	var gold_val: int = int(c.get("reward_gold", 0))
	var xp_val: int = int(c.get("reward_xp", 0))
	var rew_str := "Αμοιβή: 💰 %d Χρυσός   ✨ +%d XP" % [gold_val, xp_val]
	rew_v.add_child(UiKit.label(rew_str, 13, UiKit.CREAM))

	var items: Dictionary = c.get("reward_items", {})
	if not items.is_empty():
		var item_parts: Array[String] = []
		for i_id in items:
			var qty: int = int(items[i_id])
			var iname := _item_display_name(i_id)
			item_parts.append("%dx %s" % [qty, iname])
		rew_v.add_child(UiKit.label("Υλικά: " + ", ".join(item_parts), 12, Color(0.7, 0.85, 1.0)))

	v.add_child(rew_panel)

	# Action Button
	var bounty_id: String = c.get("id", "")
	var btn: Button
	if is_ready:
		btn = UiKit.button("🏆 Είσπραξη Αμοιβής!", func(): _on_claim_pressed(bounty_id), 260, 16)
		btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	elif is_active:
		btn = UiKit.button("⏳ Σε Εξέλιξη (%d/%d)" % [cur, count], func(): pass, 260, 15)
		btn.disabled = true
	else:
		btn = UiKit.button("⚔️ Ανάληψη Συμβολαίου", func(): _on_accept_pressed(bounty_id), 260, 15)

	v.add_child(btn)
	return card_panel


func _item_display_name(id: String) -> String:
	match id:
		"bone_shard": return "Θραύσμα Οστού"
		"iron_scrap": return "Σίδερο"
		"lava_ember": return "Κάρβουνο Λάβας"
		"potion": return "Φίλτρο Υγείας"
		_: return id


func _on_accept_pressed(bounty_id: String) -> void:
	var mgr := _get_manager()
	if mgr != null:
		mgr.accept_bounty(bounty_id)
		Sfx.ui("quest_new")


func _on_claim_pressed(bounty_id: String) -> void:
	var mgr := _get_manager()
	if mgr != null and _player != null:
		mgr.claim_bounty(bounty_id, _player)


func _on_refresh_pressed() -> void:
	var mgr := _get_manager()
	if mgr != null:
		mgr.refresh_board_contracts()
		Sfx.ui("window_open")
