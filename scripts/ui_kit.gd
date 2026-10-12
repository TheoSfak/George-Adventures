class_name UiKit
## Small UI helpers shared by the HUD, the shop window and the hero window, so every
## panel has the same look (dark brown panel, gold border, cream text).

const CREAM := Color(1, 0.96, 0.85)
const GOLD_TEXT := Color(1, 0.84, 0.35)
const MUTED := Color(0.85, 0.82, 0.72)
const GOOD := Color(0.55, 0.95, 0.5)
const BAD := Color(1.0, 0.45, 0.4)
const BORDER := Color(0.72, 0.55, 0.25)


static func panel_style(bg_alpha: float = 0.88) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.06, 0.04, bg_alpha)
	sb.border_color = BORDER
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb


## A lighter box for one row of a list.
static func row_style(highlight: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.12, 0.08, 0.92) if not highlight else Color(0.24, 0.17, 0.09, 0.95)
	sb.border_color = Color(0.45, 0.34, 0.16)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(7)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func label(text: String, size: int, color: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.03))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A wrapped paragraph label of a fixed width.
static func paragraph(text: String, size: int, width: float, color: Color = MUTED) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width
	return l


static func button(text: String, callback: Callable, min_width: float = 110.0, font_size: int = 17) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(min_width, 34)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.5, 0.42))
	b.add_theme_stylebox_override("normal", _button_box(Color(0.30, 0.20, 0.09), BORDER))
	b.add_theme_stylebox_override("hover", _button_box(Color(0.42, 0.28, 0.11), Color(1.0, 0.80, 0.35)))
	b.add_theme_stylebox_override("pressed", _button_box(Color(0.22, 0.14, 0.06), BORDER))
	b.add_theme_stylebox_override("disabled", _button_box(Color(0.14, 0.11, 0.08), Color(0.30, 0.25, 0.18)))
	if callback.is_valid():
		b.pressed.connect(callback)
	return b


## A tab button: highlighted while `active`.
static func tab_button(text: String, active: bool, callback: Callable) -> Button:
	var b := button(text, callback, 130.0, 18)
	if active:
		b.add_theme_stylebox_override("normal", _button_box(Color(0.52, 0.36, 0.13), Color(1.0, 0.82, 0.38)))
		b.add_theme_stylebox_override("hover", _button_box(Color(0.58, 0.40, 0.15), Color(1.0, 0.86, 0.45)))
	return b


static func _button_box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	return sb


## A square icon (drawn in code, see icons.gd) on a dark tile.
static func icon_box(icon: String, color: Color, px: float = 48.0) -> Control:
	var box := IconBox.new()
	box.icon = icon
	box.color = color
	box.custom_minimum_size = Vector2(px, px)
	return box


class IconBox extends Control:
	var icon := ""
	var color := Color.WHITE
	var border := Color(0.72, 0.55, 0.25)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.09, 0.07, 0.05, 0.95)
		sb.border_color = border
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		Icons.draw(self, Rect2(Vector2(6, 6), size - Vector2(12, 12)), icon, color)
