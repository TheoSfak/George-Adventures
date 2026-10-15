class_name ActionSlot
extends Control
## One square of the action bar (or one entry of the skill book).
## Click or press its number key to use it, drag skills and potions between slots,
## right-click to empty a slot. Cooldowns sweep down over the icon.

const SIZE := 62.0

var player: Player
var slot_index := -1          # >= 0: a slot of the action bar; -1: a fixed entry (skill book)
var fixed_entry := ""         # the entry shown when slot_index == -1
var key_label := ""           # "1".."9", "0", "-", "="

var _style := StyleBoxFlat.new()
var _gloss := StyleBoxFlat.new()
var _shade_style := StyleBoxFlat.new()
var _badge := StyleBoxFlat.new()
var _hover := false


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style.set_corner_radius_all(14)
	_style.set_border_width_all(1)
	_style.border_width_top = 2
	_style.anti_aliasing = true
	_style.shadow_color = Color(0, 0, 0, 0.5)
	_style.shadow_size = 5
	_style.shadow_offset = Vector2(0, 3)
	_gloss.corner_radius_top_left = 13
	_gloss.corner_radius_top_right = 13
	_gloss.bg_color = Color(1, 1, 1, 0.08)
	_gloss.anti_aliasing = true
	_shade_style.anti_aliasing = true
	_badge.set_corner_radius_all(7)
	_badge.bg_color = Color(0, 0, 0, 0.55)
	_badge.anti_aliasing = true
	mouse_entered.connect(func(): _hover = true)
	mouse_exited.connect(func(): _hover = false)


## A rounded dark veil over (part of) the slot: cooldown sweep, locked, out of potions.
func _shade(rect: Rect2, alpha: float) -> void:
	_shade_style.bg_color = Color(0, 0, 0, alpha)
	_shade_style.set_corner_radius_all(int(minf(12.0, rect.size.y / 2.0)))
	draw_style_box(_shade_style, rect)


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

	var usable := not info.is_empty() and not locked
	_style.bg_color = Color(0.09, 0.10, 0.15, 0.94) if not _hover else Color(0.15, 0.16, 0.23, 0.96)
	_style.border_color = Color(1.0, 0.82, 0.40, 0.85) if usable else Color(1, 1, 1, 0.14)
	if _hover and usable:
		_style.border_color = Color(1.0, 0.92, 0.6, 1.0)
	draw_style_box(_style, Rect2(Vector2.ZERO, size))
	draw_style_box(_gloss, Rect2(Vector2(2, 2), Vector2(size.x - 4.0, size.y * 0.45)))      # light from above
	if not info.is_empty():
		var tint: Color = info["color"]
		if locked or empty_item:
			tint = tint.darkened(0.55)
		var pad := 7.0 * size.x / SIZE
		Icons.draw(self, Rect2(Vector2(pad, pad), size - Vector2(pad, pad) * 2.0), info["icon"], tint)
		# cooldown sweep
		if not info["item"] and player != null:
			var left := player.cooldown_left(info["id"])
			if left > 0.0:
				var total: float = player.cooldown_total(info["id"])
				var h := (size.y - 4.0) * clampf(left / total, 0.0, 1.0)
				_shade(Rect2(Vector2(2, 2), Vector2(size.x - 4.0, h)), 0.66)
				_text(str(ceili(left)), size * 0.5 + Vector2(0, 8), 22, Color(1, 1, 1))
		elif info["item"] and player != null and player.potion_cooldown() > 0.0 and slot_index >= 0:
			_shade(Rect2(Vector2(2, 2), size - Vector2(4, 4)), 0.35)
		if locked:
			_shade(Rect2(Vector2(2, 2), size - Vector2(4, 4)), 0.58)
			if SkillData.is_talent_skill(info["id"]):
				_text(Strings.HERO_TAB_TALENTS, size * 0.5 + Vector2(0, 5), 13, Color(1, 0.85, 0.4))
			else:
				_text("%s %d" % [Strings.LEVEL_SHORT, info["level"]], size * 0.5 + Vector2(0, 6), 15, Color(1, 0.85, 0.4))
		if info["item"] and slot_index != -2:
			_text(str(count), Vector2(size.x - 8, size.y - 6), 17, Color(1, 1, 1) if count > 0 else Color(1, 0.4, 0.4), HORIZONTAL_ALIGNMENT_RIGHT)
	if key_label != "":
		var k := size.x / SIZE
		draw_style_box(_badge, Rect2(Vector2(4, 4) * k, Vector2(18, 17) * k))
		_text(key_label, Vector2(13, 17) * k, 13, Color(1, 0.92, 0.7))


func _text(t: String, pos: Vector2, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	font_size = maxi(9, roundi(font_size * size.x / SIZE))      # compact slots (the action bar) use smaller text
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
