class_name TreeMeshes
extends RefCounted
## Procedural low-poly geometry for the Great Tree area (scripts/great_tree.gd): islands, the tree, umbrella
## trees, bridges, the stone causeway, balloons and small props. Everything is flat-shaded with one colour
## per vertex (draw it with material()) and is built around the local origin; nothing here touches the
## scene tree, so it can be tested without a world.

# --- palette (sRGB, KayKit-like)
const MOSS_A := Color(0.38, 0.58, 0.22)
const MOSS_B := Color(0.46, 0.66, 0.26)
const MOSS_DRIP := Color(0.34, 0.54, 0.20)
const GRASS_DARK := Color(0.28, 0.46, 0.18)
const ROCK_A := Color(0.52, 0.45, 0.35)
const ROCK_B := Color(0.45, 0.39, 0.31)
const ROCK_C := Color(0.34, 0.30, 0.26)
const STONE_A := Color(0.68, 0.64, 0.57)
const STONE_B := Color(0.58, 0.54, 0.48)
const STONE_C := Color(0.50, 0.47, 0.42)
const WOOD_A := Color(0.58, 0.42, 0.27)
const WOOD_B := Color(0.50, 0.36, 0.23)
const WOOD_DARK := Color(0.36, 0.26, 0.17)
const ROPE := Color(0.66, 0.56, 0.36)
const BARK_A := Color(0.43, 0.31, 0.21)
const BARK_B := Color(0.37, 0.27, 0.18)
const BARK_C := Color(0.30, 0.22, 0.16)
const LEAF_LIGHT := Color(0.52, 0.76, 0.26)
const LEAF_MID := Color(0.34, 0.62, 0.21)
const LEAF_DARK := Color(0.22, 0.45, 0.17)
const LANTERN := Color(1.0, 0.86, 0.5)
const PAD := Color(0.24, 0.58, 0.26)
const FLOWER_COLORS: Array[Color] = [
	Color(1.0, 0.62, 0.74), Color(1.0, 0.85, 0.30), Color(0.97, 0.97, 0.92), Color(1.0, 0.58, 0.24), Color(0.52, 0.64, 1.0),
]
const BRIDGE_WIDTH := 2.2

static var _material: StandardMaterial3D


## The one material every mesh of this file uses (vertex colours are the albedo).
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.95
	return _material


## A growing list of flat-shaded triangles with one colour per vertex.
class Soup:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()

	## One triangle. `inside` is any point inside the solid: the triangle is turned so that it faces away
	## from it (Godot's front faces are clockwise seen from outside) and gets that outward flat normal.
	func tri(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color, inside: Vector3) -> void:
		var cr := (b - a).cross(c - a)
		if cr.length_squared() < 0.0000001:
			return
		var outward := (a + b + c) / 3.0 - inside
		var n := cr.normalized()
		if cr.dot(outward) > 0.0:
			# counter-clockwise seen from outside: swap two vertices to make it clockwise
			var tv := b
			b = c
			c = tv
			var tc := cb
			cb = cc
			cc = tc
		else:
			n = -n
		verts.push_back(a)
		verts.push_back(b)
		verts.push_back(c)
		norms.push_back(n)
		norms.push_back(n)
		norms.push_back(n)
		cols.push_back(ca)
		cols.push_back(cb)
		cols.push_back(cc)

	## A quad as two triangles; a, b, c, d go around its border.
	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color, cc: Color, cd: Color, inside: Vector3) -> void:
		tri(a, b, c, ca, cb, cc, inside)
		tri(a, c, d, ca, cc, cd, inside)

	## An oriented box: `ax` (length), `ay` (up) and `az` (width) are unit axes, `size` = (length, height, width).
	func box(center: Vector3, ax: Vector3, ay: Vector3, az: Vector3, size: Vector3, color: Color, top_color: Color = Color(0, 0, 0, 0)) -> void:
		var tc := color if top_color.a == 0.0 else top_color
		var hx := ax * size.x * 0.5
		var hy := ay * size.y * 0.5
		var hz := az * size.z * 0.5
		var c000 := center - hx - hy - hz
		var c100 := center + hx - hy - hz
		var c010 := center - hx + hy - hz
		var c110 := center + hx + hy - hz
		var c001 := center - hx - hy + hz
		var c101 := center + hx - hy + hz
		var c011 := center - hx + hy + hz
		var c111 := center + hx + hy + hz
		quad(c010, c110, c111, c011, tc, tc, tc, tc, center)
		quad(c000, c100, c101, c001, color, color, color, color, center)
		quad(c100, c110, c111, c101, color, color, color, color, center)
		quad(c000, c010, c011, c001, color, color, color, color, center)
		quad(c001, c101, c111, c011, color, color, color, color, center)
		quad(c000, c100, c110, c010, color, color, color, color, center)

	## A thin square beam from `a` to `b` (ropes, posts, vines, rails).
	func strut(a: Vector3, b: Vector3, thickness: float, color: Color) -> void:
		var d := b - a
		var length := d.length()
		if length < 0.001:
			return
		var ax := d / length
		var ref := Vector3.UP if absf(ax.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var az := ax.cross(ref).normalized()
		var ay := az.cross(ax).normalized()
		box((a + b) * 0.5, ax, ay, az, Vector3(length, thickness, thickness), color)

	func build() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		if verts.is_empty():
			return mesh
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_COLOR] = cols
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh


# ----------------------------------------------------------------------- lathe ----

## Revolves `profile` around the Y axis into `soup`, moved and turned by `xform`.
## profile: Array of [radius, y, Color]; a first or last radius of 0 closes that end to a point.
## `outline` (Callable angle -> factor) wobbles every ring the same way (an island rim), `wobble` adds a
## little random radius jitter per vertex, `stripes` (colours by segment) paints vertical stripes (the
## ring colour then only gives the brightness), `drip_ring` / `drip_color` streak one ring with moss.
static func lathe_into(soup: Soup, xform: Transform3D, profile: Array, segments: int, seed_value: int, wobble := 0.0,
		outline := Callable(), stripes: Array = [], drip_ring := -1, drip_color := Color.WHITE) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rings := profile.size()
	var y_mid := 0.0
	for p in profile:
		y_mid += float(p[1])
	y_mid /= float(maxi(rings, 1))
	var inside := xform * Vector3(0.0, y_mid, 0.0)
	var pts: Array = []
	var cols: Array = []
	for i in rings:
		var r0: float = float(profile[i][0])
		var y: float = float(profile[i][1])
		var base: Color = profile[i][2]
		var row := PackedVector3Array()
		var crow := PackedColorArray()
		for s in segments:
			var ang := TAU * float(s) / float(segments)
			var r := r0
			if r0 > 0.0:
				if outline.is_valid():
					r *= float(outline.call(ang))
				if wobble > 0.0:
					r *= 1.0 + rng.randf_range(-wobble, wobble)
			row.append(xform * Vector3(cos(ang) * r, y, sin(ang) * r))
			var c := base
			if not stripes.is_empty():
				var st: Color = stripes[s % stripes.size()]
				c = Color(st.r * base.r, st.g * base.r, st.b * base.r, 1.0)
			var jitter := 1.0 + rng.randf_range(-0.05, 0.05)
			c = Color(c.r * jitter, c.g * jitter, c.b * jitter, 1.0)
			if i == drip_ring and rng.randf() < 0.3:
				c = drip_color
			crow.append(c)
		pts.append(row)
		cols.append(crow)
	for i in rings - 1:
		for s in segments:
			var s1 := (s + 1) % segments
			soup.quad(pts[i][s], pts[i][s1], pts[i + 1][s1], pts[i + 1][s],
					cols[i][s], cols[i][s1], cols[i + 1][s1], cols[i + 1][s], inside)


static func lathe(profile: Array, segments: int, seed_value: int, wobble := 0.0, outline := Callable(), stripes: Array = [],
		drip_ring := -1, drip_color := Color.WHITE) -> ArrayMesh:
	var s := Soup.new()
	lathe_into(s, Transform3D.IDENTITY, profile, segments, seed_value, wobble, outline, stripes, drip_ring, drip_color)
	return s.build()


## A basis whose Y axis points along `dir` (to lay a cone on its side).
static func _basis_with_y(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


# --------------------------------------------------------------------- islands ----

## A rock island: a flat mossy top at `top_y` (walkable), a rim of grass and a cliff of rock bands that
## goes down to y -1.6 (below the lake surface). Local origin = the centre of the island.
static func island(radius: float, top_y: float, seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU
	var p3 := rng.randf() * TAU
	var outline := func(a: float) -> float:
		return 1.0 + 0.06 * sin(a * 3.0 + p1) + 0.04 * sin(a * 5.0 + p2) + 0.02 * sin(a * 9.0 + p3)
	var low := -1.6
	var y_lip := top_y - 0.35
	var profile := [
		[0.0, top_y, MOSS_A],
		[0.55 * radius, top_y, MOSS_B],
		[0.92 * radius, top_y - 0.05, MOSS_A],
		[1.03 * radius, y_lip, GRASS_DARK],
		[1.07 * radius, lerpf(y_lip, low, 0.33), ROCK_A],
		[0.97 * radius, lerpf(y_lip, low, 0.66), ROCK_B],
		[0.80 * radius, low, ROCK_C],
	]
	return lathe(profile, 32, seed_value + 1, 0.035, outline, [], 4, MOSS_DRIP)


# ------------------------------------------------------------------------ trees ----

static func _root_profile(length: float, radius: float) -> Array:
	return [[radius, 0.0, BARK_B], [radius * 0.62, length * 0.5, BARK_A], [radius * 0.18, length, BARK_B], [0.0, length * 1.03, BARK_B]]


static func _blob_profile(radius: float, light: Color, mid: Color, dark: Color) -> Array:
	return [
		[0.0, -radius * 0.85, dark],
		[radius * 0.62, -radius * 0.68, dark],
		[radius * 0.98, -radius * 0.15, mid],
		[radius * 0.92, radius * 0.4, mid],
		[radius * 0.55, radius * 0.82, light],
		[0.0, radius * 0.95, light],
	]


## The great tree: trunk with root flares, three limbs, a canopy of overlapping leaf blobs and hanging
## vines, about 22 m of trunk and a canopy up to y 33. Local origin = the foot of the trunk.
static func great_tree(seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var height := 22.0
	var br := 3.0
	var trunk := [
		[br * 1.55, 0.0, BARK_C], [br * 1.15, height * 0.07, BARK_B], [br * 0.95, height * 0.2, BARK_A], [br * 1.0, height * 0.35, BARK_B],
		[br * 0.9, height * 0.55, BARK_A], [br * 0.8, height * 0.78, BARK_B], [br * 0.7, height, BARK_A],
	]
	lathe_into(s, Transform3D.IDENTITY, trunk, 14, seed_value, 0.07)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3 + rng.randf_range(-0.2, 0.2)
		var dir := Vector3(cos(a) * 0.85, -0.52, sin(a) * 0.85)
		var start := Vector3(cos(a) * 2.4, 2.6, sin(a) * 2.4)
		lathe_into(s, Transform3D(_basis_with_y(dir), start), _root_profile(6.5, 1.0), 8, seed_value + i, 0.05)
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.8
		var dir := Vector3(cos(a) * 0.7, 0.7, sin(a) * 0.7)
		var start := Vector3(cos(a) * 1.8, 17.0, sin(a) * 1.8)
		lathe_into(s, Transform3D(_basis_with_y(dir), start), _root_profile(9.0, 0.8), 8, seed_value + 10 + i, 0.05)
	var blobs := [
		[Vector3(0, 27.5, 0), 9.5], [Vector3(7.5, 25.5, 3.0), 7.0], [Vector3(-6.5, 26.0, 5.5), 7.2], [Vector3(-3.0, 25.2, -8.0), 7.5],
		[Vector3(6.0, 26.5, -6.5), 7.0], [Vector3(11.5, 22.5, 2.0), 5.2], [Vector3(-11.0, 23.0, -1.0), 5.5], [Vector3(2.5, 22.0, 11.5), 5.0],
		[Vector3(-1.5, 23.0, -12.0), 5.3], [Vector3(0, 31.0, 0), 6.0],
	]
	for i in blobs.size():
		var light := LEAF_LIGHT.lerp(LEAF_MID, float(i % 3) * 0.35)
		var mid := LEAF_MID.lerp(LEAF_LIGHT, float(i % 2) * 0.25)
		var xf := Transform3D(Basis.from_scale(Vector3(1.0, 0.78, 1.0)), blobs[i][0])
		lathe_into(s, xf, _blob_profile(float(blobs[i][1]), light, mid, LEAF_DARK), 10, seed_value + 20 + i, 0.12)
	for i in 14:
		var a := TAU * float(i) / 14.0 + rng.randf_range(-0.2, 0.2)
		var r := rng.randf_range(6.0, 13.0)
		var top := Vector3(cos(a) * r, 21.5, sin(a) * r)
		var drop := rng.randf_range(3.0, 5.0)
		s.strut(top, top + Vector3(rng.randf_range(-0.3, 0.3), -drop, rng.randf_range(-0.3, 0.3)), 0.09, LEAF_MID)
	return s.build()


## A slim tree with a flat umbrella canopy (the mushroom-like trees of the picture).
static func umbrella_tree(height: float, canopy_radius: float, seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var trunk := [[0.5, 0.0, BARK_C], [0.34, height * 0.5, BARK_A], [0.26, height, BARK_B]]
	lathe_into(s, Transform3D.IDENTITY, trunk, 8, seed_value, 0.05)
	var r := canopy_radius
	var canopy := [
		[0.0, -0.10 * r, LEAF_DARK], [0.55 * r, -0.22 * r, LEAF_DARK], [r, -0.05 * r, LEAF_MID],
		[0.8 * r, 0.18 * r, LEAF_LIGHT], [0.35 * r, 0.30 * r, LEAF_LIGHT], [0.0, 0.32 * r, LEAF_LIGHT],
	]
	lathe_into(s, Transform3D(Basis.IDENTITY, Vector3(0.0, height, 0.0)), canopy, 12, seed_value + 1, 0.08)
	return s.build()


# ------------------------------------------------------------------- bridges ----

## Number of planks segments of a bridge (about 0.55 m each).
static func bridge_steps(a: Vector3, b: Vector3) -> int:
	return maxi(int(Vector2(b.x - a.x, b.z - a.z).length() / 0.55), 4)


## The centre line of a bridge deck from `a` to `b` with a shallow sag (1.5% of the length, at most 0.5 m).
static func bridge_line(a: Vector3, b: Vector3, steps: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var length := Vector2(b.x - a.x, b.z - a.z).length()
	var sag := minf(0.015 * length, 0.5)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var p := a.lerp(b, t)
		p.y -= sag * 4.0 * t * (1.0 - t)
		out.append(p)
	return out


## Steepest slope (rise over run) along a polyline.
static func max_slope(line: Array[Vector3]) -> float:
	var worst := 0.0
	for i in line.size() - 1:
		var d: Vector3 = line[i + 1] - line[i]
		var h := Vector2(d.x, d.z).length()
		if h > 0.0001:
			worst = maxf(worst, absf(d.y) / h)
	return worst


## The frame of a deck segment: forward, up, sideways.
static func _frame(p0: Vector3, p1: Vector3) -> Array:
	var ax := (p1 - p0).normalized()
	var az := ax.cross(Vector3.UP).normalized()
	var ay := az.cross(ax).normalized()
	return [ax, ay, az]


## A plank bridge with stringers, two rope rails and posts, all in one mesh. Its deck top follows bridge_line.
static func bridge(a: Vector3, b: Vector3) -> ArrayMesh:
	var s := Soup.new()
	var steps := bridge_steps(a, b)
	var line := bridge_line(a, b, steps)
	var half := BRIDGE_WIDTH * 0.5
	for i in steps:
		var p0: Vector3 = line[i]
		var p1: Vector3 = line[i + 1]
		var f := _frame(p0, p1)
		var ax: Vector3 = f[0]
		var ay: Vector3 = f[1]
		var az: Vector3 = f[2]
		var mid := (p0 + p1) * 0.5
		var seg := p0.distance_to(p1)
		s.box(mid - ay * 0.1, ax, ay, az, Vector3(seg * 0.92, 0.2, BRIDGE_WIDTH), WOOD_A if i % 2 == 0 else WOOD_B)
		for side in [-1.0, 1.0]:
			var lat: Vector3 = az * (half - 0.05) * float(side)
			s.box(mid - ay * 0.28 + lat * 0.92, ax, ay, az, Vector3(seg * 1.02, 0.16, 0.2), WOOD_DARK)
			s.strut(p0 + lat + ay * 0.55, p1 + lat + ay * 0.55, 0.07, ROPE)
			s.strut(p0 + lat + ay * 1.05, p1 + lat + ay * 1.05, 0.07, ROPE)
			if i % 4 == 0:
				s.strut(p0 + lat - ay * 0.15, p0 + lat + ay * 1.2, 0.14, WOOD_DARK)
	var last: Vector3 = line[steps]
	var lf := _frame(line[steps - 1], last)
	for side in [-1.0, 1.0]:
		var lat: Vector3 = (lf[2] as Vector3) * (half - 0.05) * float(side)
		s.strut(last + lat - (lf[1] as Vector3) * 0.15, last + lat + (lf[1] as Vector3) * 1.2, 0.14, WOOD_DARK)
	return s.build()


## What the bridge collides with: a continuous deck slab and two invisible rail walls 1.1 m high.
static func bridge_collision(a: Vector3, b: Vector3) -> ArrayMesh:
	var s := Soup.new()
	var steps := bridge_steps(a, b)
	var line := bridge_line(a, b, steps)
	var half := BRIDGE_WIDTH * 0.5
	for i in steps:
		var p0: Vector3 = line[i]
		var p1: Vector3 = line[i + 1]
		var f := _frame(p0, p1)
		var ax: Vector3 = f[0]
		var ay: Vector3 = f[1]
		var az: Vector3 = f[2]
		var mid := (p0 + p1) * 0.5
		var seg := p0.distance_to(p1)
		s.box(mid - ay * 0.15, ax, ay, az, Vector3(seg * 1.05, 0.3, BRIDGE_WIDTH), WOOD_A)
		for side in [-1.0, 1.0]:
			s.box(mid + az * half * float(side) + ay * 0.55, ax, ay, az, Vector3(seg * 1.05, 1.1, 0.12), WOOD_A)
	return s.build()


# ----------------------------------------------------------------------- ramp ----

## The centre line of the stone causeway: an arc around `center` that climbs from y0 to y1.
static func ramp_line(center: Vector2, radius: float, a0_deg: float, a1_deg: float, y0: float, y1: float, steps: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in steps + 1:
		var t := float(i) / float(steps)
		var ang := deg_to_rad(lerpf(a0_deg, a1_deg, t))
		out.append(Vector3(center.x + cos(ang) * radius, lerpf(y0, y1, t), center.y + sin(ang) * radius))
	return out


## The stone causeway: a banded deck, a rock skirt below it and low parapets on both sides.
static func ramp(line: Array[Vector3], width: float) -> ArrayMesh:
	var s := Soup.new()
	for i in line.size() - 1:
		var f := _frame(line[i], line[i + 1])
		var ax: Vector3 = f[0]
		var ay: Vector3 = f[1]
		var az: Vector3 = f[2]
		var mid := (line[i] + line[i + 1]) * 0.5
		var seg := line[i].distance_to(line[i + 1])
		s.box(mid - ay * 0.2, ax, ay, az, Vector3(seg * 1.03, 0.4, width), STONE_A if i % 2 == 0 else STONE_B)
		s.box(mid - ay * 1.1, ax, ay, az, Vector3(seg * 1.03, 1.4, width * 0.86), ROCK_B)
		for side in [-1.0, 1.0]:
			s.box(mid + az * (width * 0.5 - 0.15) * float(side) + ay * 0.3, ax, ay, az, Vector3(seg * 1.03, 0.6, 0.3), STONE_C)
	return s.build()


static func ramp_collision(line: Array[Vector3], width: float) -> ArrayMesh:
	var s := Soup.new()
	for i in line.size() - 1:
		var f := _frame(line[i], line[i + 1])
		var ax: Vector3 = f[0]
		var ay: Vector3 = f[1]
		var az: Vector3 = f[2]
		var mid := (line[i] + line[i + 1]) * 0.5
		var seg := line[i].distance_to(line[i + 1])
		s.box(mid - ay * 0.2, ax, ay, az, Vector3(seg * 1.05, 0.4, width), STONE_A)
		for side in [-1.0, 1.0]:
			s.box(mid + az * (width * 0.5 - 0.05) * float(side) + ay * 0.55, ax, ay, az, Vector3(seg * 1.05, 1.1, 0.12), STONE_A)
	return s.build()


## A stone pillar under the causeway: from y -1.6 (below the lake bed) up to `top_y`.
static func pillar(top_y: float, seed_value: int) -> ArrayMesh:
	var mid := (top_y - 1.6) * 0.5
	var profile := [[1.0, -1.6, ROCK_C], [0.8, mid, ROCK_B], [0.85, top_y, ROCK_A]]
	return lathe(profile, 8, seed_value, 0.06)


# -------------------------------------------------------------------- balloon ----

## A hot-air balloon with stripes, rope lines and a wicker basket. Local origin = the bottom of the basket;
## the envelope is above it (y about 4 to 17).
static func balloon(stripes: Array, seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var g := func(v: float) -> Color:
		return Color(v, v, v)
	var envelope := [
		[0.0, -5.6, g.call(0.55)], [1.5, -4.9, g.call(0.70)], [3.4, -3.0, g.call(0.90)], [4.6, 0.0, g.call(1.0)],
		[4.3, 2.8, g.call(1.0)], [3.0, 5.0, g.call(0.95)], [1.2, 6.4, g.call(0.90)], [0.0, 6.9, g.call(0.85)],
	]
	lathe_into(s, Transform3D(Basis.IDENTITY, Vector3(0.0, 9.8, 0.0)), envelope, 12, seed_value, 0.0, Callable(), stripes)
	s.box(Vector3(0.0, 0.55, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(1.5, 1.1, 1.5), WOOD_B, WOOD_A)
	s.box(Vector3(0.0, 1.12, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(1.7, 0.12, 1.7), WOOD_DARK)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			s.strut(Vector3(0.65 * float(sx), 1.1, 0.65 * float(sz)), Vector3(1.4 * float(sx), 4.5, 1.4 * float(sz)), 0.06, ROPE)
	return s.build()


# ---------------------------------------------------------------------- props ----

## A wooden bench, 1.8 m long, facing +Z.
static func bench() -> ArrayMesh:
	var s := Soup.new()
	s.box(Vector3(0.0, 0.45, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(1.8, 0.1, 0.5), WOOD_A)
	s.box(Vector3(0.0, 0.85, -0.22), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(1.8, 0.4, 0.08), WOOD_B)
	for sx in [-0.75, 0.75]:
		s.box(Vector3(float(sx), 0.22, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(0.1, 0.44, 0.44), WOOD_DARK)
	return s.build()


## Posts of the lanterns at `points` (each point is the foot of a post).
static func lanterns_posts(points: Array[Vector3]) -> ArrayMesh:
	var s := Soup.new()
	for p in points:
		s.strut(p, p + Vector3(0.0, 2.0, 0.0), 0.14, WOOD_DARK)
		s.box(p + Vector3(0.0, 2.0, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(0.5, 0.08, 0.5), WOOD_DARK)
	return s.build()


## The glowing heads of those lanterns (drawn with an emissive material).
static func lanterns_heads(points: Array[Vector3]) -> ArrayMesh:
	var s := Soup.new()
	for p in points:
		s.box(p + Vector3(0.0, 2.3, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(0.34, 0.46, 0.34), LANTERN)
	return s.build()


## Little flowers (a stem and a five-sided head) at `points`.
static func flowers(points: Array[Vector3], seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for p in points:
		var color: Color = FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()]
		s.strut(p, p + Vector3(0.0, 0.45, 0.0), 0.05, LEAF_MID)
		var head := [[0.0, 0.0, color], [0.2, 0.05, color], [0.16, 0.17, color.lightened(0.15)], [0.0, 0.2, color.lightened(0.15)]]
		lathe_into(s, Transform3D(Basis.IDENTITY, p + Vector3(0.0, 0.45, 0.0)), head, 5, rng.randi())
	return s.build()


## Flat lily pads (a few with a pink flower) lying on the water at `points`.
static func lily_pads(points: Array[Vector3], seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for p in points:
		var r := rng.randf_range(0.5, 0.8)
		var pad := [[0.0, 0.0, PAD], [r, 0.0, PAD], [r, -0.03, PAD.darkened(0.3)]]
		lathe_into(s, Transform3D(Basis.IDENTITY, p), pad, 8, rng.randi(), 0.05)
		if rng.randf() < 0.4:
			var f := [[0.0, 0.0, Color(1.0, 0.7, 0.8)], [0.18, 0.05, Color(1.0, 0.7, 0.8)], [0.0, 0.2, Color(1.0, 0.85, 0.9)]]
			lathe_into(s, Transform3D(Basis.IDENTITY, p + Vector3(0.0, 0.02, 0.0)), f, 5, rng.randi())
	return s.build()


## A ring of radial deck planks around the trunk (its top is 0.03 m above the origin plane).
static func deck_ring(inner: float, outer: float, count: int) -> ArrayMesh:
	var s := Soup.new()
	var length := outer - inner
	for i in count:
		var a := TAU * float(i) / float(count)
		var radial := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-sin(a), 0.0, cos(a))
		var width := TAU * (inner + outer) * 0.5 / float(count) * 0.9
		s.box(radial * (inner + length * 0.5) + Vector3(0.0, -0.01, 0.0), radial, Vector3.UP, side, Vector3(length, 0.08, width), WOOD_A if i % 2 == 0 else WOOD_B)
	return s.build()
