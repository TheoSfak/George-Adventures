class_name HeroWindow
extends PanelContainer
## George's window with three tabs: Ικανότητες (P), Ταλέντα (T), Εξοπλισμός (I).
## Skills can be dragged from here onto the action bar; talents are clicked to learn.

const TABS: Array[String] = ["skills", "talents", "gear"]

var player: Player
var _tab := "skills"
var _tab_row: HBoxContainer
var _content: VBoxContainer
var _info: RichTextLabel
var _hover_id := ""


func _ready() -> void:
	name = "SkillBook"   # the old name, kept for the test drivers
	visible = false
	add_theme_stylebox_override("panel", UiKit.panel_style(0.92))
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	offset_left = 28.0
	offset_top = 118.0
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 8)
	root.add_child(_tab_row)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	root.add_child(_content)
	if player:
		player.talents_changed.connect(_refresh_if_open)
		player.gear_changed.connect(_refresh_if_open)
		player.inventory_changed.connect(func(_g, _p): _refresh_if_open())
		player.leveled_up.connect(func(_l): _refresh_if_open())


func is_open() -> bool:
	return visible


## Opens the window on a tab; pressing the same tab's key again closes it.
func toggle(tab: String) -> void:
	if visible and _tab == tab:
		visible = false
		Sfx.ui("window_close")
		return
	_tab = tab
	if not visible:
		Sfx.ui("window_open")
	visible = true
	_refresh()


func _refresh_if_open() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	for c in _tab_row.get_children():
		c.queue_free()
	var names := {"skills": Strings.HERO_TAB_SKILLS, "talents": Strings.HERO_TAB_TALENTS, "gear": Strings.HERO_TAB_GEAR}
	for t in TABS:
		_tab_row.add_child(UiKit.tab_button(names[t], _tab == t, _switch.bind(t)))
	var j_btn := UiKit.button("🏆 Επιτεύγματα [J]", func():
		visible = false
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("open_journal"):
			hud.open_journal("achievements")
	, 32.0, 13)
	_tab_row.add_child(j_btn)
	for c in _content.get_children():
		c.queue_free()
	_info = null
	match _tab:
		"skills":
			_build_skills()
		"talents":
			_build_talents()
		"gear":
			_build_gear()


func _switch(tab: String) -> void:
	_tab = tab
	_refresh()


# ------------------------------------------------------------------- skills ----

func _build_skills() -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	box.add_child(UiKit.paragraph(Strings.SKILLBOOK_HINT, 14, 450.0, Color(0.8, 0.75, 0.6)))
	for id in SkillData.SKILLS:
		box.add_child(_skill_row(id, SkillData.SKILLS[id]))
	box.add_child(UiKit.label(Strings.SKILLBOOK_ITEMS, 20, UiKit.GOLD_TEXT))
	for id in SkillData.ITEMS:
		box.add_child(_skill_row("item:" + id, SkillData.ITEMS[id]))


func _skill_row(entry: String, def: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slot := ActionSlot.new()
	slot.player = player
	slot.fixed_entry = entry
	row.add_child(slot)
	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title: String = def["name"]
	if def.has("cooldown"):
		if SkillData.is_talent_skill(entry):
			title += "   (%s, %s %d δ)" % [Strings.HERO_TAB_TALENTS, Strings.COOLDOWN, int(player.cooldown_total(entry))]
		else:
			title += "   (%s %d, %s %d δ)" % [Strings.LEVEL_SHORT, def["level"], Strings.COOLDOWN, int(player.cooldown_total(entry))]
	text.add_child(UiKit.label(title, 18))
	text.add_child(UiKit.paragraph(def["desc"], 14, 380.0))
	row.add_child(text)
	return row


# ------------------------------------------------------------------ talents ----

func _build_talents() -> void:
	var free := player.talent_points_free()
	_content.add_child(UiKit.label(Strings.TALENT_POINTS % free, 22, UiKit.GOLD_TEXT if free > 0 else UiKit.MUTED))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 26)
	_content.add_child(columns)
	for branch_id in TalentData.BRANCH_ORDER:
		columns.add_child(_branch_column(branch_id))
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = false
	_info.scroll_active = false
	_info.custom_minimum_size = Vector2(700, 92)
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info.add_theme_font_size_override("normal_font_size", 16)
	_info.add_theme_font_size_override("bold_font_size", 19)
	_content.add_child(_info)
	_content.add_child(UiKit.paragraph(Strings.TALENT_HINT, 13, 700.0, Color(0.8, 0.75, 0.6)))
	_content.add_child(UiKit.paragraph(Strings.TALENT_RESPEC_HINT % player.respec_cost(), 13, 700.0, Color(0.8, 0.75, 0.6)))
	_show_node_info(_hover_id)


func _branch_column(branch_id: String) -> Control:
	var branch: Dictionary = TalentData.BRANCHES[branch_id]
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(UiKit.icon_box(branch["icon"], branch["color"], 34.0))
	var names := VBoxContainer.new()
	names.add_child(UiKit.label(branch["name"], 20, branch["color"]))
	names.add_child(UiKit.label("%s  (%d)" % [branch["desc"], TalentData.points_in_branch(player.talents, branch_id)], 12, UiKit.MUTED))
	head.add_child(names)
	col.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	col.add_child(grid)
	var ids: Array[String] = []
	for id in TalentData.NODES:
		if TalentData.NODES[id]["branch"] == branch_id:
			ids.append(id)
	ids.sort_custom(func(a, b): return TalentData.NODES[a]["tier"] * 3 + TalentData.NODES[a]["col"] < TalentData.NODES[b]["tier"] * 3 + TalentData.NODES[b]["col"])
	for id in ids:
		var tn := TalentNode.new()
		tn.node_id = id
		tn.player = player
		tn.hovered.connect(_show_node_info)
		grid.add_child(tn)
	return col


func _show_node_info(id: String) -> void:
	_hover_id = id
	if _info == null:
		return
	if id == "":
		_info.text = ""
		return
	var node: Dictionary = TalentData.NODES[id]
	var branch: Dictionary = TalentData.BRANCHES[node["branch"]]
	var rank := int(player.talents.get(id, 0))
	var t := "[b][color=#%s]%s[/color][/b]   [color=#c9b98a]%s[/color]\n" % [(branch["color"] as Color).to_html(false), node["name"], Strings.TALENT_RANK % [rank, int(node["max"])]]
	t += "%s\n" % node["desc"]
	if node.has("mods"):
		t += "[color=#8cf27f]%s[/color]\n" % (Strings.TALENT_PER_RANK % Stats.describe(node["mods"]))
	if node.has("skill"):
		var sk: Dictionary = SkillData.SKILLS[node["skill"]]
		t += "[color=#ffd966]%s[/color]\n%s\n" % [Strings.TALENT_SKILL % int(player.cooldown_total(node["skill"])), sk["desc"]]
	var reason := TalentData.block_reason(player.talents, id, player.talent_points_free())
	if reason != "":
		t += "[color=#ff7366]%s[/color]" % reason
	_info.text = t


# --------------------------------------------------------------------- gear ----

func _build_gear() -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 26)
	_content.add_child(cols)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	for slot in ShopData.SLOTS:
		left.add_child(_slot_row(slot))
	left.add_child(UiKit.label(Strings.GEAR_OWNED, 20, UiKit.GOLD_TEXT))
	var spare := 0
	for id in player.gear_owned:
		if player.equipped.get(ShopData.GEAR[id]["slot"], "") == id:
			continue
		left.add_child(_gear_row(id))
		spare += 1
	if spare == 0:
		left.add_child(UiKit.paragraph(Strings.GEAR_NONE, 14, 430.0))
	cols.add_child(left)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.custom_minimum_size.x = 230.0
	right.add_child(UiKit.label(Strings.STATS_HEADER, 22, UiKit.GOLD_TEXT))
	right.add_child(UiKit.label("%s: %d" % [Strings.STAT_DAMAGE, roundi(player.sword_damage)], 18))
	right.add_child(UiKit.label("%s: %d" % [Strings.STAT_HEALTH, roundi(player.max_health)], 18))
	for key in Stats.NAMES:
		if key == "hp_add" or key == "damage_add":
			continue
		var v := player.stats.total(key)
		if v != 0.0:
			right.add_child(UiKit.label(Stats.line(key, v), 15, UiKit.GOOD))
	right.add_child(UiKit.label("%s: %d" % [Strings.GOLD, player.gold], 18, UiKit.GOLD_TEXT))
	right.add_child(UiKit.label(Strings.FISH_JOURNAL % [player.fish_seen.size(), ShopData.fish_ids().size()], 16, UiKit.MUTED))
	cols.add_child(right)


func _slot_row(slot: String) -> Control:
	var id: String = player.equipped.get(slot, "")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var color: Color = ShopData.tier_color(id) if id != "" else Color(0.55, 0.52, 0.48)
	h.add_child(UiKit.icon_box(ShopData.SLOT_ICONS[slot], color, 54.0))
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var up_lvl: int = int(player.gear_upgrades.get(slot, 0))
	var up_tag: String = " (+%d)" % up_lvl if up_lvl > 0 else ""
	texts.add_child(UiKit.label("%s:  %s%s" % [ShopData.SLOT_NAMES[slot], ShopData.GEAR[id]["name"] if id != "" else Strings.GEAR_EMPTY, up_tag], 18))
	if id != "":
		texts.add_child(UiKit.paragraph(Stats.describe(ShopData.GEAR[id]["mods"]), 14, 300.0, UiKit.GOOD))
	h.add_child(texts)
	if id != "":
		h.add_child(UiKit.button(Strings.GEAR_TAKE_OFF, player.unequip.bind(slot), 90))
	return h


func _gear_row(id: String) -> Control:
	var g: Dictionary = ShopData.GEAR[id]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.add_child(UiKit.icon_box(ShopData.SLOT_ICONS[g["slot"]], ShopData.tier_color(id), 46.0))
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(UiKit.label(g["name"], 17))
	texts.add_child(UiKit.paragraph(Stats.describe(g["mods"]), 13, 300.0, UiKit.GOOD))
	h.add_child(texts)
	var b := UiKit.button(Strings.GEAR_WEAR, player.equip.bind(id), 90)
	if player.level < int(g["level"]):
		b.text = Strings.SHOP_LEVEL_NEEDED % int(g["level"])
		b.disabled = true
	h.add_child(b)
	return h
