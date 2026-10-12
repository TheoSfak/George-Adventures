class_name ActionSlot
extends Control
## One square of the action bar (or one entry of the skill book).
## Click or press its number key to use it, drag skills and potions between slots,
## right-click to empty a slot. Cooldowns sweep down over the icon.

const SIZE := 62.0

var player: Player
var slot_index := -1          # >= 0: a slot of the action bar; -1: a fixed entry (skill book)
var fixed_entry := ""         # the entry shown when slot_index == -1
var key_label := ""           # "1".."8"

var _style := StyleBoxFlat.new()


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style.set_corner_radius_all(9)
	_style.set_border_width_all(2)


func entry() -> String:
	if slot_index < 0:
		return fixed_entry
	if player == null or slot_index >= player.bar.size():
		return ""
	return player.bar[slot_index]


func _process(_delta: float) -> void:
	queue_redraw()


func _is_locked(info: Dictionary) -> bool:
	return player != null and not info.is_empty() and not info["item"] and not player.knows_skill(info["id"])


func _draw() -> void:
	var e := entry()
	var info := SkillData.info(e)
	var locked := _is_locked(info)
	var count := 0
	if not info.is_empty() and info["item"] and player != null:
		count = player.consumables.get(info["id"], 0)
	var empty_item: bool = not info.is_empty() and info["item"] and count <= 0

	_style.bg_color = Color(0.09, 0.07, 0.05, 0.92)
	_style.border_color = Color(0.72, 0.55, 0.25) if (not info.is_empty() and not locked) else Color(0.35, 0.30, 0.25)
	draw_style_box(_style, Rect2(Vector2.ZERO, size))
	if not info.is_empty():
		var tint: Color = info["color"]
		if locked or empty_item:
			tint = tint.darkened(0.55)
		Icons.draw(self, Rect2(Vector2(7, 7), size - Vector2(14, 14)), info["icon"], tint)
		# cooldown sweep
		if not info["item"] and player != null:
			var left := player.cooldown_left(info["id"])
			if left > 0.0:
				var total: float = player.cooldown_total(info["id"])
				var h := (size.y - 4.0) * clampf(left / total, 0.0, 1.0)
				draw_rect(Rect2(Vector2(2, 2), Vector2(size.x - 4.0, h)), Color(0, 0, 0, 0.62))
				_text(str(ceili(left)), size * 0.5 + Vector2(0, 8), 22, Color(1, 1, 1))
		elif info["item"] and player != null and player.potion_cooldown() > 0.0 and slot_index >= 0:
			draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0, 0, 0, 0.35))
		if locked:
			draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0, 0, 0, 0.55))
			if SkillData.is_talent_skill(info["id"]):
				_text(Strings.HERO_TAB_TALENTS, size * 0.5 + Vector2(0, 5), 13, Color(1, 0.85, 0.4))
			else:
				_text("%s %d" % [Strings.LEVEL_SHORT, info["level"]], size * 0.5 + Vector2(0, 6), 15, Color(1, 0.85, 0.4))
		if info["item"] and slot_index != -2:
			_text(str(count), Vector2(size.x - 8, size.y - 6), 17, Color(1, 1, 1) if count > 0 else Color(1, 0.4, 0.4), HORIZONTAL_ALIGNMENT_RIGHT)
	if key_label != "":
		_text(key_label, Vector2(7, 17), 15, Color(1, 0.92, 0.7), HORIZONTAL_ALIGNMENT_LEFT)


func _text(t: String, pos: Vector2, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var font := ThemeDB.fallback_font
	var w := 0.0
	var origin := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		w = font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		origin.x -= w / 2.0
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		w = font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		origin.x -= w
	draw_string_outline(font, origin, t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0.05, 0.03, 0.02))
	draw_string(font, origin, t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _get_tooltip(_at: Vector2) -> String:
	var info := SkillData.info(entry())
	if info.is_empty():
		return ""
	var t: String = "%s\n%s" % [info["name"], info["desc"]]
	if not info["item"]:
		var cd: int = int(player.cooldown_total(info["id"])) if player != null else int(info["cooldown"])
		if SkillData.is_talent_skill(info["id"]):
			t += "\n%s: %d δ  |  %s" % [Strings.COOLDOWN, cd, Strings.HERO_TAB_TALENTS]
		else:
			t += "\n%s: %d δ  |  %s %d" % [Strings.COOLDOWN, cd, Strings.LEVEL_SHORT, info["level"]]
	return t


func _gui_input(event: InputEvent) -> void:
	if slot_index < 0 or player == null or not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		Sfx.ui("ui_click")
		player.use_slot(slot_index)
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		player.clear_slot(slot_index)


func _get_drag_data(_at: Vector2) -> Variant:
	var e := entry()
	var info := SkillData.info(e)
	if e == "" or _is_locked(info):
		return null
	var preview := ActionSlot.new()
	preview.player = player
	preview.fixed_entry = e
	preview.size = size
	preview.modulate.a = 0.85
	set_drag_preview(preview)
	return {"entry": e, "from": slot_index}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return slot_index >= 0 and data is Dictionary and data.has("entry")


func _drop_data(_at: Vector2, data: Variant) -> void:
	if player:
		player.assign_slot(slot_index, data["entry"], data["from"])
