class_name ArenaWindow
extends PanelContainer
## Interactive Gladiator Arena & Proving Grounds Window.
## Displays available trials on illuminated glass cards with requirements,
## wave rosters, arena champion info, rewards, and action triggers.

signal closed

const ArenaDataClass := preload("res://scripts/arena_data.gd")

var _player: Player
var _arena: Node
var _open_time := 0.0
var _title_label: Label
var _rank_label: Label
var _cards_container: HBoxContainer
var _scroll: ScrollContainer

func _ready() -> void:
	name = "ArenaWindow"
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
	_title_label = UiKit.label("⚔️ ΑΡΕΝΑ ΜΟΝΟΜΑΧΩΝ & ΔΟΚΙΜΑΣΙΕΣ ΗΡΩΩΝ", 26, UiKit.GOLD_TEXT)
	title_box.add_child(_title_label)

	_rank_label = UiKit.label("", 16, UiKit.CREAM)
	title_box.add_child(_rank_label)
	header.add_child(title_box)

	var close_btn := UiKit.button("✕", close, 45, 20)
	header.add_child(close_btn)

	# 2. Main Trials Cards Display (5 Column Horizontal Scroll)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(1040, 480)
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	_cards_container = HBoxContainer.new()
	_cards_container.add_theme_constant_override("separation", 14)
	_scroll.add_child(_cards_container)


func open(arena: Node, player: Player) -> void:
	_arena = arena
	_player = player
	_open_time = Time.get_ticks_msec() / 1000.0

	_refresh_ui()
	visible = true
	if _player != null:
		_player.busy = true


func close() -> void:
	visible = false
	if _player != null:
		_player.busy = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		# Ignore presses within 0.25s of opening
		if (Time.get_ticks_msec() / 1000.0) - _open_time > 0.25:
			get_viewport().set_input_as_handled()
			close()


func _refresh_ui() -> void:
	if _cards_container == null:
		return
	for child in _cards_container.get_children():
		child.queue_free()

	var completed: Array = _arena.get("completed_trials") if _arena != null else []

	# Update Rank Label
	var rank_name := "Νεοσύλλεκτος Μονομάχος"
	if completed.has("mythic"):
		rank_name = "👑 Αδιαμφισβήτητος Πρωταθλητής του Αγίου Βλάση"
	elif completed.has("heroic"):
		rank_name = "⚔️ Ηρωικός Μονομάχος των Συνόρων"
	elif completed.has("gold"):
		rank_name = "🛡️ Χρυσός Μονομάχος των Ορκ"
	elif completed.has("silver"):
		rank_name = "🗡️ Ασημένιος Μονομάχος των Κουρσάρων"
	elif completed.has("bronze"):
		rank_name = "🎖️ Χάλκινος Μονομάχος"

	_rank_label.text = "Τρέχων Τίτλος: %s  |  Χρυσός: %d" % [rank_name, _player.gold if _player else 0]

	# Build Card for each trial
	for trial in ArenaDataClass.TRIALS:
		var card := _create_trial_card(trial, completed)
		_cards_container.add_child(card)


func _create_trial_card(trial: Dictionary, completed: Array) -> PanelContainer:
	var trial_id: String = trial["id"]
	var is_cleared: bool = completed.has(trial_id)
	var is_unlocked: bool = ArenaDataClass.is_unlocked(trial_id, completed)
	var tier_col: Color = trial["tier_color"]

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(245, 450)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.12, 0.15, 0.95) if is_unlocked else Color(0.08, 0.08, 0.10, 0.90)
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_color = tier_col if is_unlocked else Color(0.25, 0.25, 0.28)
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.content_margin_left = 12
	card_style.content_margin_right = 12
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# Tier Badge & Status
	var top_row := HBoxContainer.new()
	var badge := UiKit.label(trial["title"], 17, tier_col if is_unlocked else Color(0.5, 0.5, 0.5))
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(badge)

	if is_cleared:
		var check := UiKit.label("✔ ΝΙΚΗ", 14, Color(0.4, 0.95, 0.4))
		top_row.add_child(check)
	elif not is_unlocked:
		var lock := UiKit.label("🔒", 14, Color(0.6, 0.6, 0.6))
		top_row.add_child(lock)
	vbox.add_child(top_row)

	var sub := UiKit.label(trial["subtitle"], 12, Color(0.8, 0.8, 0.85))
	vbox.add_child(sub)

	# Level & Fee
	var info_lbl := UiKit.label("Επίπεδο: %d+  |  Είσοδος: %d 💰" % [trial["rec_level"], trial["fee"]], 13, UiKit.GOLD_TEXT)
	vbox.add_child(info_lbl)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	# Waves breakdown
	var waves_lbl := UiKit.label("3 Κύματα Μονομάχων:", 13, UiKit.CREAM)
	vbox.add_child(waves_lbl)

	var waves: Array = trial["waves"]
	for w_idx in waves.size():
		var w_dict: Dictionary = waves[w_idx]
		var w_text: String = w_dict["name"]
		var wl := UiKit.label("• %s" % w_text, 11, Color(0.75, 0.78, 0.82))
		vbox.add_child(wl)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Rewards summary
	var rew_hdr := UiKit.label("Έπαθλα Νίκης:", 13, Color(1.0, 0.85, 0.35))
	vbox.add_child(rew_hdr)

	var rew: Dictionary = trial["reward"]
	var r_text := "+%d 💰 | +%d XP" % [rew["gold"], rew["xp"]]
	var rl := UiKit.label(r_text, 12, Color(0.9, 0.9, 0.95))
	vbox.add_child(rl)

	if rew.has("gear"):
		var gear_name: String = ShopData.GEAR[rew["gear"]]["name"]
		var gl := UiKit.label("🎁 %s" % gear_name, 11, Color(1.0, 0.45, 0.15))
		vbox.add_child(gl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Action Button
	var btn_text := "Έναρξη (%d 💰)" % int(trial["fee"])
	if is_cleared:
		btn_text = "Επανάληψη (%d 💰)" % int(trial["fee"])
	elif not is_unlocked:
		btn_text = "Κλειδωμένη 🔒"

	var action_btn := UiKit.button(btn_text, func():
		_on_trial_selected(trial_id)
	, 36, 14)

	action_btn.disabled = not is_unlocked
	vbox.add_child(action_btn)

	return card


func _on_trial_selected(trial_id: String) -> void:
	if _arena == null or _player == null:
		return
	var res: bool = _arena.start_trial(trial_id, _player)
	if res:
		close()
