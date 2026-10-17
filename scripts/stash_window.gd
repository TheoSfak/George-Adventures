class_name StashWindow
extends PanelContainer
## Interactive Personal Storage Stash Window for George's Cottage.
## Allows storing and retrieving weapons, armors, shields, fish, crafting materials, and potions.

signal closed

var _player: Player
var _open_time := 0.0
var _tab := "gear" # "gear", "junk", "consumables"

var _tab_gear_btn: Button
var _tab_junk_btn: Button
var _tab_cons_btn: Button

var _bag_list: VBoxContainer
var _stash_list: VBoxContainer
var _gold_label: Label

func _ready() -> void:
	name = "StashWindow"
	visible = false
	add_theme_stylebox_override("panel", UiKit.panel_style(0.96))
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	# 1. Header
	var header := HBoxContainer.new()
	var title := UiKit.label("📦 ΠΡΟΣΩΠΙΚΟ ΜΠΑΟΥΛΟ ΑΠΟΘΗΚΕΥΣΗΣ", 26, UiKit.GOLD_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_gold_label = UiKit.label("", 18, UiKit.CREAM)
	header.add_child(_gold_label)

	var close_x := UiKit.button("✕", close, 45, 20)
	header.add_child(close_x)
	root.add_child(header)

	# 2. Category Tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	root.add_child(tabs)

	_tab_gear_btn = UiKit.button("⚔️ Όπλα & Πανοπλίες", func(): _set_tab("gear"), 200, 15)
	tabs.add_child(_tab_gear_btn)

	_tab_junk_btn = UiKit.button("🐟 Ψάρια & Υλικά", func(): _set_tab("junk"), 190, 15)
	tabs.add_child(_tab_junk_btn)

	_tab_cons_btn = UiKit.button("🧪 Φίλτρα & Ελιξίρια", func(): _set_tab("consumables"), 190, 15)
	tabs.add_child(_tab_cons_btn)

	# 3. Two-Column Storage Columns
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.custom_minimum_size = Vector2(960, 440)
	root.add_child(cols)

	# Left Column: Bag / Inventory
	var bag_col := VBoxContainer.new()
	bag_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(bag_col)

	var bag_head := UiKit.label("🎒 Σάκος Γιώργου (Τσάντα)", 18, UiKit.CREAM)
	bag_col.add_child(bag_head)

	var bag_scroll := ScrollContainer.new()
	bag_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_col.add_child(bag_scroll)

	_bag_list = VBoxContainer.new()
	_bag_list.add_theme_constant_override("separation", 6)
	_bag_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.add_child(_bag_list)

	# Divider separator
	var sep := VSeparator.new()
	cols.add_child(sep)

	# Right Column: Stash Chest Storage
	var stash_col := VBoxContainer.new()
	stash_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(stash_col)

	var stash_head := UiKit.label("📦 Μπαούλο Καλύβας (Αποθήκη)", 18, UiKit.GOLD_TEXT)
	stash_col.add_child(stash_head)

	var stash_scroll := ScrollContainer.new()
	stash_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stash_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stash_col.add_child(stash_scroll)

	_stash_list = VBoxContainer.new()
	_stash_list.add_theme_constant_override("separation", 6)
	_stash_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stash_scroll.add_child(_stash_list)

	# 4. Footer
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	var close_btn := UiKit.button("Κλείσιμο [Esc / R]", close, 180, 16)
	foot.add_child(close_btn)
	root.add_child(foot)


func open(player: Player) -> void:
	_player = player
	_open_time = Time.get_ticks_msec() / 1000.0
	visible = true
	if _player != null and not _player.stash_changed.is_connected(_refresh_ui):
		_player.stash_changed.connect(_refresh_ui)
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


func _set_tab(t: String) -> void:
	_tab = t
	_refresh_ui()
	Sfx.ui("click")


func _refresh_ui() -> void:
	if _player == null:
		return

	_gold_label.text = "💰 %d Χρυσός" % _player.gold

	# Clear previous lists
	for c in _bag_list.get_children():
		c.queue_free()
	for c in _stash_list.get_children():
		c.queue_free()

	match _tab:
		"gear":
			_render_gear_tab()
		"junk":
			_render_junk_tab()
		"consumables":
			_render_consumables_tab()


func _render_gear_tab() -> void:
	# 1. Player Bag Gear
	var bag_gear: Array[String] = _player.gear_owned
	if bag_gear.is_empty():
		_bag_list.add_child(UiKit.label("Δεν υπάρχουν αποθηκεύσιμα όπλα/πανοπλίες.", 14, UiKit.MUTED))
	else:
		for gid in bag_gear:
			var is_equipped: bool = (_player.equipped.get("weapon") == gid or _player.equipped.get("armor") == gid or _player.equipped.get("shield") == gid)
			var row := _build_item_row(gid, "gear", false, is_equipped)
			_bag_list.add_child(row)

	# 2. Stash Stored Gear
	var stash_gear: Array = _player.stash.get("gear", [])
	if stash_gear.is_empty():
		_stash_list.add_child(UiKit.label("Το μπαούλο δεν περιέχει όπλα ή πανοπλίες.", 14, UiKit.MUTED))
	else:
		for gid in stash_gear:
			var row := _build_item_row(String(gid), "gear", true, false)
			_stash_list.add_child(row)


func _render_junk_tab() -> void:
	# 1. Player Bag Junk & Fish
	var bag_junk: Dictionary = _player.junk
	if bag_junk.is_empty():
		_bag_list.add_child(UiKit.label("Δεν έχεις ψάρια ή υλικά στον σάκο σου.", 14, UiKit.MUTED))
	else:
		for jid in bag_junk:
			var count: int = int(bag_junk[jid])
			if count > 0:
				var row := _build_item_row(jid, "junk", false, false, count)
				_bag_list.add_child(row)

	# 2. Stash Stored Junk & Fish
	var stash_junk: Dictionary = _player.stash.get("junk", {})
	if stash_junk.is_empty():
		_stash_list.add_child(UiKit.label("Το μπαούλο δεν περιέχει ψάρια ή υλικά.", 14, UiKit.MUTED))
	else:
		for jid in stash_junk:
			var count: int = int(stash_junk[jid])
			if count > 0:
				var row := _build_item_row(jid, "junk", true, false, count)
				_stash_list.add_child(row)


func _render_consumables_tab() -> void:
	# 1. Player Bag Potions
	var bag_cons: Dictionary = _player.consumables
	var has_any := false
	for cid in bag_cons:
		var count: int = int(bag_cons[cid])
		if count > 0:
			has_any = true
			var row := _build_item_row(cid, "consumable", false, false, count)
			_bag_list.add_child(row)
	if not has_any:
		_bag_list.add_child(UiKit.label("Δεν έχεις φίλτρα στον σάκο σου.", 14, UiKit.MUTED))

	# 2. Stash Stored Potions
	var stash_cons: Dictionary = _player.stash.get("consumables", {})
	var stash_any := false
	for cid in stash_cons:
		var count: int = int(stash_cons[cid])
		if count > 0:
			stash_any = true
			var row := _build_item_row(cid, "consumable", true, false, count)
			_stash_list.add_child(row)
	if not stash_any:
		_stash_list.add_child(UiKit.label("Το μπαούλο δεν περιέχει φίλτρα.", 14, UiKit.MUTED))


func _build_item_row(id: String, type: String, in_stash: bool, is_equipped: bool, count: int = 1) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.add_theme_stylebox_override("panel", UiKit.row_style(in_stash))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	row_panel.add_child(h)

	var display_name := _get_item_name(id, type)
	var lbl_text := display_name
	if count > 1:
		lbl_text += " (x%d)" % count
	if is_equipped:
		lbl_text += " [ΕΞΟΠΛΙΣΜΕΝΟ]"

	var col: Color = Color(0.6, 0.9, 0.6) if in_stash else (UiKit.MUTED if is_equipped else UiKit.CREAM)
	var name_lbl := UiKit.label(lbl_text, 14, col)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name_lbl)

	# Action Button
	var btn: Button
	if in_stash:
		btn = UiKit.button("⬅ Ανάληψη", func(): _on_withdraw(id, type, count), 110, 13)
	else:
		btn = UiKit.button("Αποθήκευση ➔", func(): _on_deposit(id, type, count), 125, 13)
		if is_equipped:
			btn.disabled = true

	h.add_child(btn)
	return row_panel


func _get_item_name(id: String, type: String) -> String:
	match type:
		"gear":
			var g: Dictionary = ShopData.GEAR.get(id, {})
			return String(g.get("name", id))
		"junk":
			var j: Dictionary = ShopData.JUNK.get(id, {})
			return String(j.get("name", id))
		"consumable":
			match id:
				"health", "potion": return "Φίλτρο Ζωής"
				_: return id
	return id


func _on_deposit(id: String, type: String, count: int) -> void:
	if _player == null:
		return
	var move_qty := 1 if count == 1 else mini(count, 5) # move up to 5 at a time
	match type:
		"gear":
			_player.deposit_gear(id)
		"junk":
			_player.deposit_junk(id, move_qty)
		"consumable":
			_player.deposit_consumable(id, move_qty)
	Sfx.ui("equip")


func _on_withdraw(id: String, type: String, count: int) -> void:
	if _player == null:
		return
	var move_qty := 1 if count == 1 else mini(count, 5)
	match type:
		"gear":
			_player.withdraw_gear(id)
		"junk":
			_player.withdraw_junk(id, move_qty)
		"consumable":
			_player.withdraw_consumable(id, move_qty)
	Sfx.ui("equip")
