class_name TalentNode
extends Control
## One talent in the tree window: click to spend a point. Talents that unlock a skill can
## be dragged onto the action bar once learned. Hovering reports the node to the window.

signal hovered(id: String)

const SIZE := 64.0

var node_id := ""
var player: Player

var _style := StyleBoxFlat.new()


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style.set_corner_radius_all(10)
	_style.set_border_width_all(3)


func _process(_delta: float) -> void:
	queue_redraw()


func _rank() -> int:
	return int(player.talents.get(node_id, 0)) if player else 0


func _locked() -> bool:
	if player == null:
		return true
	var node: Dictionary = TalentData.NODES[node_id]
	return not TalentData.tier_open(player.talents, node["branch"], node["tier"])


func _can_learn() -> bool:
	return player != null and TalentData.block_reason(player.talents, node_id, player.talent_points_free()) == ""


func _draw() -> void:
	var node: Dictionary = TalentData.NODES[node_id]
	var branch: Dictionary = TalentData.BRANCHES[node["branch"]]
	var color: Color = branch["color"]
	var rank := _rank()
	var maxed := rank >= int(node["max"])
	var locked := _locked()
	var learnable := _can_learn()

	_style.bg_color = Color(0.09, 0.07, 0.05, 0.95) if rank == 0 else color.darkened(0.7)
	if maxed:
		_style.border_color = Color(1.0, 0.85, 0.3)
	elif learnable:
		var pulse := 0.65 + 0.35 * sin(Time.get_ticks_msec() / 220.0)
		_style.border_color = color.lerp(Color(1, 1, 1), pulse * 0.5)
	elif rank > 0:
		_style.border_color = color
	else:
		_style.border_color = Color(0.35, 0.30, 0.25)
	draw_style_box(_style, Rect2(Vector2.ZERO, size))

	var tint := color
	if locked or rank == 0:
		tint = color.darkened(0.55)
	Icons.draw(self, Rect2(Vector2(8, 6), size - Vector2(16, 18)), node["icon"], tint)
	if node.has("skill"):
		# a small gold diamond marks talents that give an active skill
		var c := Vector2(10, 10)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)]), Color(1.0, 0.85, 0.3))
	if locked:
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0, 0, 0, 0.45))
	_text("%d/%d" % [rank, int(node["max"])], Vector2(size.x - 6, size.y - 5), 14,
		Color(1, 0.9, 0.5) if rank > 0 else Color(0.7, 0.65, 0.55))


func _text(t: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := pos - Vector2(w, 0.0)
	draw_string_outline(font, origin, t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0.05, 0.03, 0.02))
	draw_string(font, origin, t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		hovered.emit(node_id)
	elif what == NOTIFICATION_MOUSE_EXIT:
		hovered.emit("")


func _gui_input(event: InputEvent) -> void:
	if player == null or not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var reason := TalentData.block_reason(player.talents, node_id, player.talent_points_free())
	if reason != "":
		player.message.emit(reason)
		return
	player.learn_talent(node_id)
	hovered.emit(node_id)   # refresh the info text


func _get_drag_data(_at: Vector2) -> Variant:
	var node: Dictionary = TalentData.NODES[node_id]
	if not node.has("skill") or _rank() <= 0:
		return null
	var preview := ActionSlot.new()
	preview.player = player
	preview.fixed_entry = node["skill"]
	preview.size = Vector2(ActionSlot.SIZE, ActionSlot.SIZE)
	preview.modulate.a = 0.85
	set_drag_preview(preview)
	return {"entry": node["skill"], "from": -1}
