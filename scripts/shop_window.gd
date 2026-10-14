class_name ShopWindow
extends PanelContainer
## The shop window (market and blacksmith). Two tabs: buy and sell. Opened by
## HUD.open_shop(shop_id) after the shopkeeper's greeting; closes with Esc, R or the button.
## What a shop sells and buys is defined in shop_data.gd.

signal closed

var _player: Player
var _shop_id := ""
var _tab := "buy"
var _open_time := 0.0
var _title: Label
var _gold: Label
var _tabs: HBoxContainer
var _list: VBoxContainer


func _ready() -> void:
	name = "ShopWindow"
	visible = false
	add_theme_stylebox_override("panel", UiKit.panel_style(0.96))
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var head := HBoxContainer.new()
	_title = UiKit.label("", 30, UiKit.GOLD_TEXT)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_gold = UiKit.label("", 22, UiKit.GOLD_TEXT)
	head.add_child(_gold)
	root.add_child(head)

	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	root.add_child(_tabs)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(820, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_child(UiKit.button(Strings.SHOP_CLOSE, close, 170))
	root.add_child(foot)


func is_open() -> bool:
	return visible


func open(shop_id: String, player: Player) -> void:
	if visible:
		return
	_shop_id = shop_id
	_player = player
	_tab = "buy"
	_open_time = Time.get_ticks_msec() / 1000.0
	player.busy = true
	visible = true
	Sfx.ui("window_open")
	_refresh()


func close() -> void:
	if not visible:
		return
	visible = false
	Sfx.ui("window_close")
	closed.emit()
	# Keep George still for a moment so the same key press does not trigger something else.
	await get_tree().create_timer(0.2).timeout
	if _player and not visible:
		_player.busy = false


func _input(event: InputEvent) -> void:
	if not visible or Time.get_ticks_msec() / 1000.0 - _open_time < 0.3:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close()
		get_viewport().set_input_as_handled()


# ----------------------------------------------------------------- building ----

func _refresh() -> void:
	var shop: Dictionary = ShopData.SHOPS[_shop_id]
	_title.text = shop["title"]
	_gold.text = "%s: %d" % [Strings.GOLD, _player.gold]
	for c in _tabs.get_children():
		c.queue_free()
	var kitchen: bool = shop.get("kind", "") == "kitchen"
	_tabs.add_child(UiKit.tab_button(Strings.KITCHEN_TAB_MEALS if kitchen else Strings.SHOP_BUY, _tab == "buy", _set_tab.bind("buy")))
	var stable: bool = shop.get("kind", "") == "stable"
	if not stable:
		_tabs.add_child(UiKit.tab_button(Strings.KITCHEN_TAB_COOK if kitchen else Strings.SHOP_SELL, _tab != "buy", _set_tab.bind("cook" if kitchen else "sell")))
	for c in _list.get_children():
		c.queue_free()
	if kitchen:
		_build_kitchen_rows()
	elif _tab == "buy" or stable:
		for entry in shop["stock"]:
			_list.add_child(_buy_row(entry))
	else:
		_build_sell_rows(shop)


func _set_tab(tab: String) -> void:
	_tab = tab
	_refresh()


## One list row: icon, texts and the buttons on the right.
func _row(icon: String, color: Color, title: String, detail: String, stats_bbcode: String, price_text: String, price_ok: bool, buttons: Array) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.row_style())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)
	h.add_child(UiKit.icon_box(icon, color, 52.0))

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(UiKit.label(title, 19))
	if detail != "":
		texts.add_child(UiKit.paragraph(detail, 14, 430.0))
	if stats_bbcode != "":
		var rt := RichTextLabel.new()
		rt.bbcode_enabled = true
		rt.fit_content = true
		rt.scroll_active = false
		rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rt.custom_minimum_size.x = 430.0
		rt.add_theme_font_size_override("normal_font_size", 14)
		rt.text = stats_bbcode
		texts.add_child(rt)
	h.add_child(texts)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.custom_minimum_size.x = 130.0
	if price_text != "":
		var p := UiKit.label(price_text, 20, UiKit.GOLD_TEXT if price_ok else UiKit.BAD)
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right.add_child(p)
	for b in buttons:
		right.add_child(b)
	h.add_child(right)
	return panel


func _buy_row(entry: Dictionary) -> Control:
	var id: String = entry["id"]
	if entry["type"] == "mount":
		var owned_horse: bool = _player.horse_owned
		var need_level: int = entry["level"]
		var price_horse: int = entry["price"]
		var bh := UiKit.button(Strings.SHOP_BUY_BUTTON, _buy.bind(entry), 120)
		if owned_horse:
			bh.text = Strings.SHOP_OWNED
			bh.disabled = true
		elif _player.level < need_level:
			bh.text = Strings.SHOP_LEVEL_NEEDED % need_level
			bh.disabled = true
		return _row("horseshoe", Color(0.85, 0.65, 0.4), Strings.SHOP_HORSE_TITLE, Strings.SHOP_HORSE_DESC,
			"[color=#c9b98a]%s[/color]" % Strings.SHOP_HORSE_OWNED if owned_horse else "",
			"" if owned_horse else Strings.SHOP_PRICE % price_horse, _player.gold >= price_horse, [bh])
	if entry["type"] == "item":
		var info: Dictionary = SkillData.ITEMS[id]
		var need: int = entry.get("level", 1)
		var price: int = entry["price"]
		var b := UiKit.button(Strings.SHOP_BUY_BUTTON, _buy.bind(entry), 120)
		if _player.level < need:
			b.text = Strings.SHOP_LEVEL_NEEDED % need
			b.disabled = true
		var have := Strings.SHOP_HAVE % int(_player.consumables.get(id, 0))
		return _row(info["icon"], info["color"], info["name"], info["desc"], "[color=#c9b98a]%s[/color]" % have,
			Strings.SHOP_PRICE % price, _player.gold >= price, [b])
	# equipment
	var g: Dictionary = ShopData.GEAR[id]
	var owned := _player.gear_owned.has(id)
	var b2 := UiKit.button(Strings.SHOP_BUY_BUTTON, _buy.bind(entry), 120)
	if owned:
		b2.text = Strings.GEAR_EQUIPPED if _player.equipped.get(g["slot"], "") == id else Strings.SHOP_OWNED
		b2.disabled = true
	elif _player.level < int(g["level"]):
		b2.text = Strings.SHOP_LEVEL_NEEDED % int(g["level"])
		b2.disabled = true
	var title: String = "%s  —  %s" % [g["name"], ShopData.SLOT_NAMES[g["slot"]]]
	return _row(ShopData.SLOT_ICONS[g["slot"]], ShopData.tier_color(id), title, g["desc"], _compare_bbcode(id),
		"" if owned else Strings.SHOP_PRICE % int(g["price"]), _player.gold >= int(g["price"]), [b2])


## The item's stats, coloured against what George wears in that slot (green better, red worse).
func _compare_bbcode(id: String) -> String:
	var g: Dictionary = ShopData.GEAR[id]
	var cur_id: String = _player.equipped.get(g["slot"], "")
	var cur: Dictionary = ShopData.GEAR[cur_id]["mods"] if cur_id != "" else {}
	var mods: Dictionary = g["mods"]
	var parts: Array[String] = []
	for key in Stats.NAMES:
		var nv := float(mods.get(key, 0.0))
		var ov := float(cur.get(key, 0.0)) if cur_id != id else nv
		if nv == 0.0 and ov == 0.0:
			continue
		var color := "#c9b98a"
		var text := Stats.line(key, nv)
		if nv > ov:
			color = "#8cf27f"
		elif nv < ov:
			color = "#ff7366"
			if nv == 0.0:
				text = Stats.line(key, nv - ov)
		parts.append("[color=%s]%s[/color]" % [color, text])
	return "   ".join(parts)


func _build_sell_rows(shop: Dictionary) -> void:
	var count := 0
	if shop["buys"] == "junk":
		for jid in ShopData.JUNK:
			var n := int(_player.junk.get(jid, 0))
			if n <= 0:
				continue
			var j: Dictionary = ShopData.JUNK[jid]
			var one := UiKit.button(Strings.SHOP_SELL_BUTTON, _sell_junk.bind(jid, 1), 120)
			var all := UiKit.button("%s (%d)" % [Strings.SHOP_SELL_BUTTON, n], _sell_junk.bind(jid, n), 120)
			var buttons := [one] if n == 1 else [one, all]
			_list.add_child(_row(j["icon"], j["color"], "%s  ×%d" % [j["name"], n], j["desc"], "",
				Strings.SHOP_PRICE % int(j["price"]), true, buttons))
			count += 1
	else:
		for id in _player.gear_owned:
			var g: Dictionary = ShopData.GEAR[id]
			var b := UiKit.button(Strings.SHOP_SELL_BUTTON, _sell_gear.bind(id), 120)
			if _player.equipped.get(g["slot"], "") == id:
				b.text = Strings.GEAR_EQUIPPED
				b.disabled = true
			_list.add_child(_row(ShopData.SLOT_ICONS[g["slot"]], ShopData.tier_color(id), g["name"], g["desc"], "",
				Strings.SHOP_PRICE % ShopData.gear_sell_price(id), true, [b]))
			count += 1
	if count == 0:
		_list.add_child(UiKit.paragraph(Strings.SHOP_NOTHING_TO_SELL, 18, 780.0))


# ------------------------------------------------------------------- kitchen ----

func _build_kitchen_rows() -> void:
	for meal_id in ShopData.MEALS:
		if ShopData.MEALS[meal_id]["tab"] == _tab:
			_list.add_child(_meal_row(meal_id))


func _meal_row(meal_id: String) -> Control:
	var meal: Dictionary = ShopData.MEALS[meal_id]
	var cost: Dictionary = meal["cost"]
	var ok := ShopData.can_prepare(meal_id, _player.gold, _player.junk)
	var b := UiKit.button(Strings.KITCHEN_EAT, _eat.bind(meal_id), 120)
	b.disabled = not ok
	var lines: Array[String] = [
		"[color=#8cf27f]%s[/color]" % Stats.describe(meal["mods"]),
		"[color=#c9b98a]%s[/color]" % (Strings.MEAL_DURATION % roundi(float(meal["duration"]) / 60.0)),
	]
	if cost.has("fish"):
		var have_all := true
		for rarity in cost["fish"]:
			if ShopData.fish_have(_player.junk, rarity) < int(cost["fish"][rarity]):
				have_all = false
		lines.append("[color=%s]%s[/color]" % ["#c9b98a" if have_all else "#ff7366", Strings.KITCHEN_NEEDS % ShopData.fish_need_text(meal_id, _player.junk)])
	var gold: int = cost["gold"]
	return _row("food", Color(1.0, 0.78, 0.40), meal["name"], meal["desc"], "\n".join(lines),
		Strings.SHOP_PRICE % gold, _player.gold >= gold, [b])


func _eat(meal_id: String) -> void:
	if _player.prepare_meal(meal_id):
		_refresh()


# ------------------------------------------------------------------- trading ----

func _buy(entry: Dictionary) -> void:
	var id: String = entry["id"]
	var need: int = int(entry.get("level", 1)) if entry["type"] != "gear" else int(ShopData.GEAR[id]["level"])
	if _player.level < need:
		_player.message.emit(Strings.SKILL_LOCKED % need)
		return
	if entry["type"] == "mount":
		if not MountRules.can_buy(_player.level, _player.gold, _player.horse_owned) or not _player.spend_gold(int(entry["price"])):
			return
		_player.horse_owned = true
		_player.message.emit(Strings.MOUNT_BOUGHT)
		Sfx.ui("buy")
		_refresh()
		return
	if entry["type"] == "item":
		if not _player.spend_gold(int(entry["price"])):
			return
		_player.consumables[id] = int(_player.consumables.get(id, 0)) + 1
		_player.inventory_changed.emit(_player.gold, _player.potions)
		_player.message.emit(Strings.SHOP_BOUGHT % SkillData.ITEMS[id]["name"])
	else:
		var g: Dictionary = ShopData.GEAR[id]
		if _player.gear_owned.has(id) or not _player.spend_gold(int(g["price"])):
			return
		_player.gear_owned.append(id)
		_player.message.emit(Strings.SHOP_BOUGHT % g["name"])
		var worn: String = _player.equipped.get(g["slot"], "")
		if worn == "" or int(ShopData.GEAR[worn]["tier"]) < int(g["tier"]):
			_player.equip(id)
		_player.gear_changed.emit()
	Sfx.ui("buy")
	_refresh()


func _sell_junk(jid: String, amount: int) -> void:
	var have := int(_player.junk.get(jid, 0))
	amount = mini(amount, have)
	if amount <= 0:
		return
	var total: int = int(ShopData.JUNK[jid]["price"]) * amount
	_player.junk[jid] = have - amount
	_player.gold += total
	_player.inventory_changed.emit(_player.gold, _player.potions)
	_player.message.emit(Strings.SHOP_SOLD % [ShopData.JUNK[jid]["name"], total])
	Sfx.ui("sell")
	_refresh()


func _sell_gear(id: String) -> void:
	var g: Dictionary = ShopData.GEAR[id]
	if _player.equipped.get(g["slot"], "") == id or not _player.gear_owned.has(id):
		return
	var total := ShopData.gear_sell_price(id)
	_player.gear_owned.erase(id)
	_player.gold += total
	_player.inventory_changed.emit(_player.gold, _player.potions)
	_player.message.emit(Strings.SHOP_SOLD % [g["name"], total])
	Sfx.ui("sell")
	_player.gear_changed.emit()
	_refresh()
