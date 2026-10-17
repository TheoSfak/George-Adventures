class_name Icons
## Draws the small skill and potion icons with plain shapes (no image files needed).
## Use inside any Control's _draw(): Icons.draw(self, Rect2(...), "sword", color).


static func draw(ci: CanvasItem, rect: Rect2, icon: String, color: Color) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y) * 0.5
	match icon:
		"sword":
			_sword(ci, c, s, color)
		"shield":
			_shield(ci, c, s, color)
		"whirl":
			_whirl(ci, c, s, color)
		"cross":
			_cross(ci, c, s, color)
		"arrow":
			_arrow(ci, c, s, color)
		"potion":
			_potion(ci, c, s, color)
		"shout":
			_shout(ci, c, s, color)
		"tower":
			_tower(ci, c, s, color)
		"claw":
			_claw(ci, c, s, color)
		"bolt":
			_bolt(ci, c, s, color)
		"flame":
			_flame(ci, c, s, color)
		"ring":
			_ring(ci, c, s, color)
		"armor":
			_armor(ci, c, s, color)
		"heart":
			_heart(ci, c, s, color)
		"star":
			_star(ci, c, s, color)
		"eye":
			_eye(ci, c, s, color)
		"fang":
			_fang(ci, c, s, color)
		"bone":
			_bone(ci, c, s, color)
		"coin":
			_coin(ci, c, s, color)
		"sun":
			_sun(ci, c, s, color)
		"moon":
			_moon(ci, c, s, color)
		"fish":
			_fish(ci, c, s, color)
		"food":
			_food(ci, c, s, color)
		"horseshoe":
			_horseshoe(ci, c, s, color)
		"cloud":
			_cloud(ci, c, s, color)
		"rain":
			_rain(ci, c, s, color)
		"storm":
			_storm(ci, c, s, color)
		"bow":
			_bow(ci, c, s, color)
		"crossbow":
			_crossbow(ci, c, s, color)
		"bow_power":
			_bow_power(ci, c, s, color)
		"bow_volley":
			_bow_volley(ci, c, s, color)
		"bow_fire":
			_bow_fire(ci, c, s, color)


static func _fish(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.52, 0.0), Vector2(-0.88, -0.34), Vector2(-0.88, 0.34)], color.darkened(0.2))                  # tail
	_poly(ci, c, s, [Vector2(-0.58, 0.0), Vector2(-0.30, -0.36), Vector2(0.18, -0.42), Vector2(0.62, -0.08),
			Vector2(0.62, 0.08), Vector2(0.18, 0.42), Vector2(-0.30, 0.36)], color)                                            # body
	_poly(ci, c, s, [Vector2(-0.10, -0.38), Vector2(0.12, -0.62), Vector2(0.24, -0.38)], color.darkened(0.2))                 # fin
	ci.draw_circle(c + Vector2(0.38, -0.06) * s, 0.09 * s, Color(1, 1, 1))
	ci.draw_circle(c + Vector2(0.40, -0.06) * s, 0.04 * s, Color(0.08, 0.08, 0.1))


static func _food(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.62, 0.0), Vector2(0.62, 0.0), Vector2(0.48, 0.34), Vector2(0.20, 0.56),
			Vector2(-0.20, 0.56), Vector2(-0.48, 0.34)], color)                                                                 # the bowl
	_rect(ci, c, s, -0.66, -0.06, 1.32, 0.10, color.lightened(0.25))                                                          # its rim
	for x in [-0.28, 0.0, 0.28]:                                                                                              # steam
		ci.draw_line(c + Vector2(x, -0.12) * s, c + Vector2(x + 0.07, -0.55) * s, Color(1, 1, 1, 0.65), maxf(1.5, 0.06 * s))


## A horseshoe: an open arc (gap at the top) with a few nail dots.
static func _horseshoe(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_arc(c + Vector2(0.0, s * 0.05), s * 0.58, deg_to_rad(-65.0), deg_to_rad(245.0), 28, color, maxf(s * 0.26, 2.0))
	for a in [-35.0, 0.0, 35.0, 145.0, 180.0, 215.0]:
		var d := Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * s * 0.58
		ci.draw_circle(c + Vector2(0.0, s * 0.05) + d, maxf(s * 0.06, 1.0), Color(0.1, 0.07, 0.03))


static func _cloud(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_circle(c + Vector2(-0.34, 0.10) * s, 0.30 * s, color)
	ci.draw_circle(c + Vector2(0.02, -0.10) * s, 0.40 * s, color)
	ci.draw_circle(c + Vector2(0.38, 0.12) * s, 0.28 * s, color)
	_rect(ci, c, s, -0.34, 0.10, 0.72, 0.30, color)


static func _rain(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_cloud(ci, c + Vector2(0.0, -0.24) * s, s * 0.9, Color(0.80, 0.85, 0.92))
	for x in [-0.30, 0.0, 0.30]:
		ci.draw_line(c + Vector2(x, 0.34) * s, c + Vector2(x - 0.08, 0.76) * s, color, maxf(1.5, 0.08 * s))


static func _storm(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_cloud(ci, c + Vector2(0.0, -0.24) * s, s * 0.9, Color(0.58, 0.62, 0.72))
	_bolt(ci, c + Vector2(0.0, 0.34) * s, s * 0.55, color)


static func _poly(ci: CanvasItem, c: Vector2, s: float, pts: Array, color: Color) -> void:
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + (p as Vector2) * s)
	ci.draw_colored_polygon(out, color)


static func _rect(ci: CanvasItem, c: Vector2, s: float, x: float, y: float, w: float, h: float, color: Color) -> void:
	ci.draw_rect(Rect2(c + Vector2(x, y) * s, Vector2(w, h) * s), color)


static func _sword(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_set_transform(c, PI / 4.0, Vector2.ONE)
	var o := Vector2.ZERO
	_poly(ci, o, s, [Vector2(-0.10, 0.25), Vector2(0.10, 0.25), Vector2(0.10, -0.55), Vector2(0, -0.86), Vector2(-0.10, -0.55)], Color(0.88, 0.90, 0.95))
	_poly(ci, o, s, [Vector2(0, 0.25), Vector2(0.10, 0.25), Vector2(0.10, -0.55), Vector2(0, -0.86)], Color(0.62, 0.66, 0.74))
	_rect(ci, o, s, -0.30, 0.25, 0.60, 0.10, color)
	_rect(ci, o, s, -0.055, 0.35, 0.11, 0.28, Color(0.45, 0.28, 0.14))
	ci.draw_circle(Vector2(0, 0.67) * s, 0.08 * s, color)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _shield(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.58, -0.62), Vector2(0.58, -0.62), Vector2(0.58, 0.0), Vector2(0, 0.80), Vector2(-0.58, 0.0)], color.darkened(0.35))
	_poly(ci, c, s, [Vector2(-0.46, -0.52), Vector2(0.46, -0.52), Vector2(0.46, -0.04), Vector2(0, 0.64), Vector2(-0.46, -0.04)], color)
	_rect(ci, c, s, -0.07, -0.42, 0.14, 0.78, Color(1, 1, 1, 0.9))
	_rect(ci, c, s, -0.30, -0.18, 0.60, 0.14, Color(1, 1, 1, 0.9))


static func _whirl(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	for i in 3:
		var a0 := TAU * float(i) / 3.0
		var a1 := a0 + 1.9
		ci.draw_arc(c, 0.58 * s, a0, a1, 20, color, 0.15 * s, true)
		var tip := c + Vector2(cos(a1), sin(a1)) * 0.58 * s
		var tangent := Vector2(-sin(a1), cos(a1))
		var radial := Vector2(cos(a1), sin(a1))
		ci.draw_colored_polygon(PackedVector2Array([tip + tangent * 0.26 * s, tip + radial * 0.2 * s, tip - radial * 0.2 * s]), color)


static func _cross(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_circle(c, 0.78 * s, Color(color.r, color.g, color.b, 0.28))
	_rect(ci, c, s, -0.15, -0.55, 0.30, 1.10, color)
	_rect(ci, c, s, -0.55, -0.15, 1.10, 0.30, color)
	ci.draw_circle(c, 0.12 * s, Color(1, 1, 1, 0.9))


static func _arrow(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.45, -0.17), Vector2(0.12, -0.17), Vector2(0.12, -0.46), Vector2(0.80, 0.0), Vector2(0.12, 0.46), Vector2(0.12, 0.17), Vector2(-0.45, 0.17)], color)
	for k in 3:
		_rect(ci, c, s, -0.85 + 0.06 * float(k), -0.42 + 0.34 * float(k), 0.30, 0.08, Color(1, 1, 1, 0.7))


static func _potion(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_circle(c + Vector2(0, 0.22) * s, 0.46 * s, color)
	_rect(ci, c, s, -0.15, -0.46, 0.30, 0.46, color.lerp(Color(1, 1, 1), 0.45))
	_rect(ci, c, s, -0.19, -0.64, 0.38, 0.20, Color(0.55, 0.36, 0.20))
	ci.draw_circle(c + Vector2(-0.16, 0.08) * s, 0.10 * s, Color(1, 1, 1, 0.65))


static func _shout(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.70, -0.16), Vector2(-0.38, -0.16), Vector2(-0.02, -0.46), Vector2(-0.02, 0.46), Vector2(-0.38, 0.16), Vector2(-0.70, 0.16)], color)
	for k in 3:
		var r := (0.34 + 0.22 * float(k)) * s
		ci.draw_arc(c + Vector2(-0.02, 0.0) * s, r, -0.7, 0.7, 12, Color(color.r, color.g, color.b, 1.0 - 0.25 * float(k)), 0.1 * s, true)


static func _tower(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_rect(ci, c, s, -0.50, -0.20, 1.00, 0.86, color.darkened(0.25))
	_rect(ci, c, s, -0.50, -0.58, 0.26, 0.38, color)
	_rect(ci, c, s, -0.13, -0.58, 0.26, 0.38, color)
	_rect(ci, c, s, 0.24, -0.58, 0.26, 0.38, color)
	_rect(ci, c, s, -0.50, -0.24, 1.00, 0.10, color)
	_poly(ci, c, s, [Vector2(-0.16, 0.66), Vector2(-0.16, 0.22), Vector2(0.0, 0.08), Vector2(0.16, 0.22), Vector2(0.16, 0.66)], Color(0.08, 0.06, 0.05))


static func _claw(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	for k in 3:
		var x := -0.42 + 0.42 * float(k)
		_poly(ci, c, s, [Vector2(x - 0.12, -0.70), Vector2(x + 0.04, -0.70), Vector2(x + 0.22, 0.70), Vector2(x + 0.10, 0.70)], color.lerp(Color(1, 1, 1), 0.1 * float(k)))


static func _bolt(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(0.12, -0.80), Vector2(-0.42, 0.10), Vector2(-0.04, 0.10), Vector2(-0.16, 0.80), Vector2(0.44, -0.18), Vector2(0.04, -0.18)], color)


static func _flame(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(0.0, -0.82), Vector2(0.30, -0.30), Vector2(0.52, 0.10), Vector2(0.40, 0.55), Vector2(0.0, 0.80), Vector2(-0.40, 0.55), Vector2(-0.52, 0.10), Vector2(-0.22, -0.20), Vector2(-0.14, -0.50)], color)
	_poly(ci, c, s, [Vector2(0.0, -0.20), Vector2(0.20, 0.20), Vector2(0.22, 0.50), Vector2(0.0, 0.66), Vector2(-0.22, 0.50), Vector2(-0.20, 0.20)], Color(1, 1, 0.85, 0.9))


static func _ring(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_circle(c, 0.78 * s, Color(color.r, color.g, color.b, 0.22))
	ci.draw_arc(c, 0.72 * s, 0.0, TAU, 28, color, 0.12 * s, true)
	ci.draw_arc(c, 0.42 * s, 0.0, TAU, 20, color, 0.10 * s, true)
	ci.draw_circle(c, 0.12 * s, Color(1, 1, 1, 0.9))


static func _armor(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.80, -0.55), Vector2(-0.42, -0.70), Vector2(-0.16, -0.58), Vector2(0.16, -0.58), Vector2(0.42, -0.70), Vector2(0.80, -0.55), Vector2(0.66, -0.08), Vector2(0.46, -0.08), Vector2(0.46, 0.72), Vector2(-0.46, 0.72), Vector2(-0.46, -0.08), Vector2(-0.66, -0.08)], color)
	_rect(ci, c, s, -0.06, -0.50, 0.12, 1.10, color.darkened(0.35))
	_rect(ci, c, s, -0.46, 0.20, 0.92, 0.09, color.darkened(0.35))


static func _heart(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_circle(c + Vector2(-0.27, -0.20) * s, 0.33 * s, color)
	ci.draw_circle(c + Vector2(0.27, -0.20) * s, 0.33 * s, color)
	_poly(ci, c, s, [Vector2(-0.58, -0.08), Vector2(0.58, -0.08), Vector2(0.0, 0.70)], color)
	ci.draw_circle(c + Vector2(-0.34, -0.30) * s, 0.09 * s, Color(1, 1, 1, 0.55))


static func _star(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var pts: Array = []
	for i in 10:
		var a := -PI / 2.0 + TAU * float(i) / 10.0
		var r := 0.78 if i % 2 == 0 else 0.34
		pts.append(Vector2(cos(a), sin(a)) * r)
	_poly(ci, c, s, pts, color)


static func _eye(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.80, 0.0), Vector2(-0.40, -0.34), Vector2(0.0, -0.46), Vector2(0.40, -0.34), Vector2(0.80, 0.0), Vector2(0.40, 0.34), Vector2(0.0, 0.46), Vector2(-0.40, 0.34)], Color(0.95, 0.93, 0.88))
	ci.draw_circle(c, 0.27 * s, color)
	ci.draw_circle(c, 0.11 * s, Color(0.05, 0.03, 0.02))


static func _fang(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.55, -0.60), Vector2(-0.10, -0.60), Vector2(-0.30, 0.70)], color)
	_poly(ci, c, s, [Vector2(0.10, -0.60), Vector2(0.55, -0.60), Vector2(0.30, 0.70)], color)
	_rect(ci, c, s, -0.62, -0.70, 1.24, 0.16, color.darkened(0.3))


static func _bone(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_set_transform(c, PI / 4.0, Vector2.ONE)
	var o := Vector2.ZERO
	_rect(ci, o, s, -0.52, -0.09, 1.04, 0.18, color)
	for sx in [-1.0, 1.0]:
		ci.draw_circle(Vector2(0.54 * sx, -0.12) * s, 0.15 * s, color)
		ci.draw_circle(Vector2(0.54 * sx, 0.12) * s, 0.15 * s, color)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _coin(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_circle(c, 0.66 * s, color.darkened(0.3))
	ci.draw_circle(c, 0.54 * s, color)
	ci.draw_arc(c, 0.34 * s, 0.0, TAU, 20, color.darkened(0.3), 0.08 * s, true)


static func _sun(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_circle(c, 0.38 * s, color)
	for i in 8:
		var a := TAU * float(i) / 8.0
		ci.draw_line(c + Vector2(cos(a), sin(a)) * 0.55 * s, c + Vector2(cos(a), sin(a)) * 0.9 * s, color, maxf(1.5, 0.12 * s))


static func _moon(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	# a crescent: a disc with a darker disc bitten out of it
	ci.draw_circle(c, 0.72 * s, color)
	ci.draw_circle(c + Vector2(0.36, -0.2) * s, 0.62 * s, Color(0.06, 0.05, 0.1, 1.0))


static func _bow(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	# Curved bow stave (left arc)
	ci.draw_arc(c + Vector2(0.35, 0.0) * s, 0.75 * s, deg_to_rad(115.0), deg_to_rad(245.0), 24, color, maxf(2.0, 0.12 * s))
	# Bowstring (vertical chord)
	var top := c + Vector2(-0.05, -0.68) * s
	var btm := c + Vector2(-0.05, 0.68) * s
	ci.draw_line(top, btm, Color(1, 1, 1, 0.75), maxf(1.0, 0.05 * s))
	# Arrow shaft & head
	ci.draw_line(c + Vector2(-0.45, 0.0) * s, c + Vector2(0.55, 0.0) * s, color.lightened(0.3), maxf(1.5, 0.07 * s))
	_poly(ci, c, s, [Vector2(0.55, 0.0), Vector2(0.35, -0.16), Vector2(0.35, 0.16)], color.lightened(0.5))


static func _crossbow(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	# Stock (body)
	_rect(ci, c, s, -0.10, -0.65, 0.20, 1.30, color.darkened(0.2))
	# Crossbow arms / lathe
	ci.draw_arc(c + Vector2(0.0, 0.10) * s, 0.72 * s, deg_to_rad(-160.0), deg_to_rad(-20.0), 20, color, maxf(2.5, 0.14 * s))
	# String
	ci.draw_line(c + Vector2(-0.68, -0.15) * s, c + Vector2(0.0, 0.18) * s, Color(1, 1, 1, 0.8), maxf(1.0, 0.05 * s))
	ci.draw_line(c + Vector2(0.68, -0.15) * s, c + Vector2(0.0, 0.18) * s, Color(1, 1, 1, 0.8), maxf(1.0, 0.05 * s))
	# Bolt head
	_poly(ci, c, s, [Vector2(0.0, -0.75), Vector2(-0.16, -0.45), Vector2(0.16, -0.45)], color.lightened(0.4))


static func _bow_power(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_bow(ci, c, s, color)
	# Heavy kinetic aura streaks
	ci.draw_line(c + Vector2(-0.7, -0.3) * s, c + Vector2(0.7, -0.3) * s, Color(1, 0.85, 0.3, 0.7), 0.06 * s)
	ci.draw_line(c + Vector2(-0.7, 0.3) * s, c + Vector2(0.7, 0.3) * s, Color(1, 0.85, 0.3, 0.7), 0.06 * s)
	ci.draw_circle(c + Vector2(0.55, 0.0) * s, 0.18 * s, Color(1, 0.9, 0.4, 0.85))


static func _bow_volley(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	# 3 fan-out arrows
	for angle_deg in [-25.0, 0.0, 25.0]:
		var rad := deg_to_rad(angle_deg)
		var dir := Vector2(cos(rad), sin(rad))
		var norm := Vector2(-sin(rad), cos(rad))
		ci.draw_line(c - dir * 0.4 * s, c + dir * 0.55 * s, color, maxf(1.5, 0.07 * s))
		_poly(ci, c, s, [
			dir * 0.65,
			dir * 0.42 + norm * 0.14,
			dir * 0.42 - norm * 0.14
		], color.lightened(0.3))


static func _bow_fire(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_bow(ci, c, s, color)
	# Fiery aura & flame petals around arrowhead
	var tip := c + Vector2(0.55, 0.0) * s
	ci.draw_circle(tip, 0.22 * s, Color(1.0, 0.45, 0.1, 0.8))
	ci.draw_circle(tip + Vector2(0.08, -0.05) * s, 0.14 * s, Color(1.0, 0.85, 0.2, 0.9))

