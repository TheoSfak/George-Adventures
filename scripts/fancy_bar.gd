class_name FancyBar
extends Control
## A modern capsule bar: dark glass track with a soft shadow, a glossy two-tone gradient
## fill with rounded ends, a "damage trail" that lags behind when the value drops, optional
## segment ticks and centred text. Used by the health, XP and invasion bars and the quest
## progress lines. Set `value` (0..1); the fill glides to it. The static `texture()` draws the
## same look into an image for the bars above enemies' heads.

var value := 1.0 : set = _set_value
var top_color := Color(1.0, 0.45, 0.42)       # fill, upper edge
var bottom_color := Color(0.72, 0.12, 0.14)   # fill, lower edge
var trail_color := Color(1.0, 1.0, 1.0, 0.5)
var text := ""
var text_size := 15
var text_color := Color(1, 1, 1)
var ticks := 0                                # thin dividers inside the fill (e.g. 4 = quarters)
var glide := true                             # animate changes (false = jump)

var _shown := 1.0
var _trail := 1.0
var _trail_wait := 0.0
var _track := StyleBoxFlat.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.bg_color = Color(0.03, 0.04, 0.07, 0.82)
	_track.border_color = Color(1, 1, 1, 0.16)
	_track.set_border_width_all(1)
	_track.shadow_color = Color(0, 0, 0, 0.5)
	_track.shadow_size = 5
	_track.shadow_offset = Vector2(0, 2)
	_track.anti_aliasing = true


func _set_value(v: float) -> void:
	v = clampf(v, 0.0, 1.0)
	if v < value:
		_trail_wait = 0.35                    # the trail waits a moment, then catches up
	value = v
	if not glide:
		_shown = v
		_trail = v
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var changed := false
	if not is_equal_approx(_shown, value):
		_shown = move_toward(_shown, value, delta * maxf(1.2, absf(value - _shown) * 9.0))
		changed = true
	if _trail > _shown:
		_trail_wait -= delta
		if _trail_wait <= 0.0:
			_trail = move_toward(_trail, _shown, delta * 0.6)
		changed = true
	elif _trail < _shown:
		_trail = _shown
		changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	var h := size.y
	var r := h / 2.0
	_track.set_corner_radius_all(int(r))
	draw_style_box(_track, Rect2(Vector2.ZERO, size))
	var pad := clampf(h * 0.13, 1.5, 3.0)
	var inner := Rect2(Vector2(pad, pad), size - Vector2(pad, pad) * 2.0)
	var ir := inner.size.y / 2.0
	if _trail > _shown + 0.002:
		_fill(inner, ir, _trail, trail_color, trail_color, false)
	if _shown > 0.002:
		_fill(inner, ir, _shown, top_color, bottom_color, true)
	if ticks > 1 and _shown > 0.0:
		for i in range(1, ticks):
			var x := inner.position.x + inner.size.x * float(i) / ticks
			if x < inner.position.x + inner.size.x * _shown - 2.0:
				draw_line(Vector2(x, inner.position.y + 2.0), Vector2(x, inner.end.y - 2.0), Color(0, 0, 0, 0.22), 1.0)
	if text != "":
		var font := ThemeDB.fallback_font
		var sz := text_size
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var origin := Vector2((size.x - w) / 2.0, size.y / 2.0 + sz * 0.36)
		draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 4, Color(0, 0, 0, 0.75))
		draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, text_color)


## The glossy fill: one 1-px stripe per row, shorter near the top and bottom (round ends),
## coloured from `top` to `bottom`, with a white gloss over the upper half.
func _fill(inner: Rect2, ir: float, fraction: float, top: Color, bottom: Color, gloss: bool) -> void:
	var width := maxf(inner.size.x * fraction, minf(inner.size.y, inner.size.x))
	if fraction <= 0.0:
		return
	var rows := maxi(2, int(ceil(inner.size.y)))
	var row_h := inner.size.y / rows
	for i in rows:
		var t := (float(i) + 0.5) / rows
		var dy := absf((float(i) + 0.5) * row_h - ir)
		var dx := ir - sqrt(maxf(ir * ir - dy * dy, 0.0))
		var c := top.lerp(bottom, smoothstep(0.0, 1.0, t))
		if gloss:
			if t < 0.5:
				c = c.lerp(Color(1, 1, 1, c.a), 0.30 * (1.0 - t / 0.5))
			elif t > 0.85:
				c = c.darkened(0.12)
		var x0 := inner.position.x + dx
		var x1 := inner.position.x + width - dx
		if x1 > x0:
			draw_rect(Rect2(x0, inner.position.y + i * row_h, x1 - x0, row_h + 0.5), c)


## An image of the bar for 3D labels: rounded, anti-aliased, with the same gradient.
static func texture(w: int, h: int, fraction: float, top: Color, bottom: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var half := Vector2(w, h) / 2.0
	var r := h / 2.0
	var inset := 2.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5) - half
			var q := p.abs() - (half - Vector2(r, r))
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r
			var a := clampf(0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var col := Color(0.04, 0.04, 0.06, 0.88)
			if d > -1.0:
				col = Color(1, 1, 1, 0.4)                       # thin light rim
			else:
				# inside the track: the fill, rounded the same way a little smaller
				var half2 := half - Vector2(inset, inset)
				var r2 := r - inset
				var q2 := p.abs() - (half2 - Vector2(r2, r2))
				var d2 := Vector2(maxf(q2.x, 0.0), maxf(q2.y, 0.0)).length() + minf(maxf(q2.x, q2.y), 0.0) - r2
				if d2 < 0.5 and (x + 0.5) <= fraction * w:
					var t := clampf((y + 0.5) / h, 0.0, 1.0)
					col = top.lerp(bottom, t)
					if t < 0.45:
						col = col.lerp(Color.WHITE, 0.3 * (1.0 - t / 0.45))
			col.a *= a
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
