class_name UiKit
## Small UI helpers shared by the HUD, the menus, the shop window and the hero window, so every
## panel has the same modern look: dark glass with rounded corners and a soft shadow, a thin light
## rim, warm gold accents, a clean system font (Segoe UI) and soft text shadows.

const CREAM := Color(0.97, 0.95, 0.90)
const GOLD_TEXT := Color(1.0, 0.82, 0.38)
const MUTED := Color(0.78, 0.78, 0.80)
const GOOD := Color(0.50, 0.93, 0.55)
const BAD := Color(1.0, 0.45, 0.42)
const BORDER := Color(0.92, 0.72, 0.34)           # the gold accent (borders of buttons, highlights)
const GLASS := Color(0.050, 0.060, 0.090)         # panel background (blue-black)
const RIM := Color(1.0, 1.0, 1.0, 0.14)           # thin light edge of panels

static var _font: Font


## The UI font: Segoe UI semibold on Windows (clean and has Greek), the engine default elsewhere.
static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Segoe UI Semibold", "Segoe UI", "Inter", "Roboto", "Noto Sans", "Arial"])
		f.font_weight = 600
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_font = f
	return _font


## Makes the UI font the default of every Control and of code-drawn text. Call once at start-up.
static func install_font() -> void:
	var f := font()
	var theme := ThemeDB.get_default_theme()
	theme.default_font = f
	ThemeDB.fallback_font = f
	var tt := StyleBoxFlat.new()
	tt.bg_color = Color(0.06, 0.07, 0.11, 0.94)
	tt.border_color = Color(0.88, 0.72, 0.35, 0.75)
	tt.set_border_width_all(1)
	tt.border_width_top = 2
	tt.set_corner_radius_all(8)
	tt.shadow_color = Color(0, 0, 0, 0.6)
	tt.shadow_size = 8
	tt.shadow_offset = Vector2(0, 3)
	tt.content_margin_left = 12
	tt.content_margin_right = 12
	tt.content_margin_top = 8
	tt.content_margin_bottom = 8
	theme.set_stylebox("panel", "TooltipPanel", tt)
	theme.set_color("font_color", "TooltipLabel", CREAM)
	theme.set_color("font_shadow_color", "TooltipLabel", Color(0, 0, 0, 0.6))
	theme.set_constant("shadow_offset_y", "TooltipLabel", 1)


## A dark glass panel with rounded corners, a light rim and a soft drop shadow.
static func panel_style(bg_alpha: float = 0.84) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(GLASS.r, GLASS.g, GLASS.b, bg_alpha)
	sb.border_color = RIM
	sb.set_border_width_all(1)
	sb.border_width_top = 2                       # a brighter top edge: the light comes from above
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 5)
	sb.anti_aliasing = true
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb


## A smaller capsule (messages, buffs, prompts, the clock): fully rounded, tight margins.
static func pill_style(accent: Color = Color(0, 0, 0, 0), alpha: float = 0.80) -> StyleBoxFlat:
	var sb := panel_style(alpha)
	sb.set_corner_radius_all(22)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	if accent.a > 0.0:
		sb.border_color = accent
		sb.set_border_width_all(2)
	return sb


## A lighter box for one row of a list.
static func row_style(highlight: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.055) if not highlight else Color(1.0, 0.85, 0.45, 0.13)
	sb.border_color = Color(1, 1, 1, 0.09) if not highlight else Color(1.0, 0.82, 0.38, 0.45)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(11)
	sb.anti_aliasing = true
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	return sb


static func label(text: String, size: int, color: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.7))
	l.add_theme_constant_override("outline_size", maxi(3, size / 8))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
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
	b.custom_minimum_size = Vector2(min_width, 36)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", GOLD_TEXT)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.52))
	b.add_theme_stylebox_override("normal", _button_box(Color(0.17, 0.19, 0.27, 0.96), Color(1, 1, 1, 0.20), 3))
	b.add_theme_stylebox_override("hover", _button_box(Color(0.24, 0.26, 0.36, 0.98), BORDER, 3))
	b.add_theme_stylebox_override("pressed", _button_box(Color(0.12, 0.13, 0.19, 0.98), BORDER, 1))
	b.add_theme_stylebox_override("disabled", _button_box(Color(0.10, 0.11, 0.15, 0.85), Color(1, 1, 1, 0.07), 1))
	if callback.is_valid():
		b.pressed.connect(callback)
	return b


## A tab button: highlighted (gold) while `active`.
static func tab_button(text: String, active: bool, callback: Callable) -> Button:
	var b := button(text, callback, 130.0, 18)
	if active:
		b.add_theme_stylebox_override("normal", _button_box(Color(0.55, 0.40, 0.14, 0.98), Color(1.0, 0.85, 0.45), 3))
		b.add_theme_stylebox_override("hover", _button_box(Color(0.62, 0.45, 0.16, 0.98), Color(1.0, 0.89, 0.52), 3))
		b.add_theme_color_override("font_color", Color(1, 1, 1))
	return b


## A key button with a raised edge (the dark lip under it is a hard shadow), so it looks pressable.
static func _button_box(bg: Color, border: Color, lip: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.set_corner_radius_all(12)
	sb.anti_aliasing = true
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = lip
	sb.shadow_offset = Vector2(0, lip)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4 + (lip - 1)
	return sb


## A small rounded "key cap" with a letter in it ([R], [M]...).
static func key_cap(key: String, size: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.94, 0.97)
	sb.set_corner_radius_all(7)
	sb.anti_aliasing = true
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = key
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.12, 0.13, 0.18))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


## A square icon (drawn in code, see icons.gd) on a dark tile.
static func icon_box(icon: String, color: Color, px: float = 48.0) -> Control:
	var box := IconBox.new()
	box.icon = icon
	box.color = color
	box.custom_minimum_size = Vector2(px, px)
	return box


## An icon without a tile, for stat lines (coin, potion...).
static func glyph(icon: String, color: Color, px: float = 22.0) -> Control:
	var g := GlyphIcon.new()
	g.icon = icon
	g.color = color
	g.custom_minimum_size = Vector2(px, px)
	return g


class IconBox extends Control:
	var icon := ""
	var color := Color.WHITE
	var border := Color(1, 1, 1, 0.22)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.08, 0.12, 0.96)
		sb.border_color = border
		sb.set_border_width_all(1)
		sb.border_width_top = 2
		sb.set_corner_radius_all(12)
		sb.anti_aliasing = true
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 4
		sb.shadow_offset = Vector2(0, 2)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		Icons.draw(self, Rect2(Vector2(6, 6), size - Vector2(12, 12)), icon, color)


class GlyphIcon extends Control:
	var icon := ""
	var color := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		Icons.draw(self, Rect2(Vector2.ZERO, size), icon, color)


## The round level badge of the hero card: a gold ring around a dark disc with the level number.
class LevelBadge extends Control:
	var level := 1

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 3.0
		draw_circle(c + Vector2(0, 3), r + 1.0, Color(0, 0, 0, 0.5))                      # drop shadow
		draw_circle(c, r, Color(0.62, 0.40, 0.08))                                        # ring, shaded side
		draw_circle(c + Vector2(0, -1.2), r - 0.8, Color(1.0, 0.84, 0.40))                # ring, lit side
		draw_circle(c, r - 5.0, Color(0.06, 0.07, 0.11))                                  # dark face
		draw_arc(c, r - 6.5, deg_to_rad(200), deg_to_rad(340), 24, Color(1, 1, 1, 0.22), 2.0, true)   # gloss
		var font := ThemeDB.fallback_font
		var num := str(level)
		var fs := 28 if level < 100 else 22
		var w := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(font, Vector2(c.x - w / 2.0, c.y + fs * 0.42 + 4), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.7))
		draw_string(font, Vector2(c.x - w / 2.0, c.y + fs * 0.42 + 4), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.8))
		var tag := Strings.LEVEL_SHORT
		var tw := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, Vector2(c.x - tw / 2.0, c.y - r + 22), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.82, 0.38))
