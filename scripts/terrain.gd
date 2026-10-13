class_name Terrain
extends Node3D
## Makes the ground beautiful: a rolling meadow shader instead of flat tiles, cobbled
## and dirt paths, thousands of swaying grass tufts and wild flowers, fenced vegetable
## gardens with a scarecrow, flower beds and a pond. Built by village.gd.
## Everything is procedural - no textures.

const SH := "res://shaders/"
const CHUNK := 48.0          # plants are grouped in square chunks so far ones can be hidden
const PATH_CELL := 4.0
const PATH_Y := 0.07

const FLOWER_COLORS: Array[Color] = [
	Color(0.98, 0.97, 0.92), Color(1.0, 0.82, 0.15), Color(0.95, 0.42, 0.62), Color(0.64, 0.36, 0.86),
	Color(0.90, 0.18, 0.15), Color(0.36, 0.52, 0.96), Color(1.0, 0.56, 0.16),
]
const GRASS_COLORS: Array[Color] = [
	Color(0.27, 0.56, 0.15), Color(0.36, 0.67, 0.20), Color(0.21, 0.46, 0.14), Color(0.52, 0.70, 0.24),
	Color(0.32, 0.60, 0.18), Color(0.60, 0.68, 0.28),
]

var rng := RandomNumberGenerator.new()
var _ground_mat: ShaderMaterial
var _path_dirt: ShaderMaterial
var _path_cobble: ShaderMaterial
var _plant_mat: ShaderMaterial
var _water_mat: ShaderMaterial
var world_offset := Vector2.ZERO  # see set_world_offset()
var _patch_shader: Shader
var _path_cells := {}            # Vector2i -> Array[Vector3(x, z, half width)]
var _edge_paths: Array = []      # [[Vector2 samples...], half width] for flower borders
var _batches := {}               # key -> {"mesh": Mesh, "far": float, "items": Array}
var _meshes := {}


func setup(seed_value: int) -> void:
	rng.seed = seed_value
	_ground_mat = _shader_mat("ground")
	_path_dirt = _shader_mat("path")
	_path_cobble = _shader_mat("path")
	_path_cobble.set_shader_parameter("cobble", true)
	_path_cobble.set_shader_parameter("base_color", Color(0.62, 0.58, 0.50))
	_path_cobble.set_shader_parameter("edge_color", Color(0.30, 0.27, 0.22))
	_plant_mat = _shader_mat("plant")
	_water_mat = _shader_mat("water")
	_patch_shader = load(SH + "patch.gdshader") as Shader


## For a Terrain far from the origin (the Frontier at x = -6000): the shaders' noise loses its
## precision at thousands of metres and turns into hard squares, so they subtract this offset
## (the Terrain node's own position) from the world position. Call after setup(), before building.
func set_world_offset(offset: Vector2) -> void:
	world_offset = offset
	for m in [_ground_mat, _path_dirt, _path_cobble]:
		m.set_shader_parameter("world_offset", offset)


func _shader_mat(shader_name: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SH + shader_name + ".gdshader") as Shader
	return m


# ------------------------------------------------------------------ ground ----

func build_ground(half_extent: Vector2) -> void:
	var inner := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = half_extent * 2.0
	inner.mesh = pm
	inner.material_override = _ground_mat
	inner.name = "Meadow"
	add_child(inner)
	# A huge, slightly darker plane so the world fades into the distance instead of the sky.
	var far_mat := _ground_mat.duplicate() as ShaderMaterial
	far_mat.set_shader_parameter("darken", 0.82)
	var far := MeshInstance3D.new()
	var fm := PlaneMesh.new()
	fm.size = Vector2(7000.0, 7000.0)
	far.mesh = fm
	far.material_override = far_mat
	far.position.y = -0.06
	far.name = "FarGround"
	add_child(far)


## A round patch of coloured ground (village square, camp, quarry...).
func add_patch(center: Vector2, radius: float, color: Color, cobble := false, edge := Color(0.35, 0.30, 0.20)) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 2.0)
	mi.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = _patch_shader
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("edge_color", edge)
	mat.set_shader_parameter("cobble", cobble)
	mat.set_shader_parameter("world_offset", world_offset)
	mi.material_override = mat
	mi.position = Vector3(center.x, 0.04, center.y)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


# ------------------------------------------------------------------- paths ----

## points: Array of Vector2 (world x, z). The path is smoothed through them.
## flowers: grow flower borders along both edges.
func add_path(points: Array, width: float, cobble := false, flowers := false) -> void:
	var pts := _smooth(points, 2.0)
	var n := pts.size()
	if n < 2:
		return
	var half := width * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lefts: Array[Vector3] = []
	var rights: Array[Vector3] = []
	var dists: Array[float] = []
	var d := 0.0
	for i in n:
		var p: Vector2 = pts[i]
		var dir: Vector2 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		lefts.append(Vector3(p.x + nrm.x * half, PATH_Y, p.y + nrm.y * half))
		rights.append(Vector3(p.x - nrm.x * half, PATH_Y, p.y - nrm.y * half))
		if i > 0:
			d += p.distance_to(pts[i - 1])
		dists.append(d)
		var cell := Vector2i(floori(p.x / PATH_CELL), floori(p.y / PATH_CELL))
		if not _path_cells.has(cell):
			_path_cells[cell] = []
		_path_cells[cell].append(Vector3(p.x, p.y, half))
	for i in n - 1:
		var uv_a := dists[i] / width
		var uv_b := dists[i + 1] / width
		for v in [[lefts[i], Vector2(0, uv_a)], [rights[i], Vector2(1, uv_a)], [lefts[i + 1], Vector2(0, uv_b)],
				[rights[i], Vector2(1, uv_a)], [rights[i + 1], Vector2(1, uv_b)], [lefts[i + 1], Vector2(0, uv_b)]]:
			st.set_normal(Vector3.UP)
			st.set_uv(v[1])
			st.add_vertex(v[0])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _path_cobble if cobble else _path_dirt
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	if flowers:
		_edge_paths.append([pts, half])


func near_path(p: Vector2, margin: float) -> bool:
	var c := Vector2i(floori(p.x / PATH_CELL), floori(p.y / PATH_CELL))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var cell := Vector2i(c.x + dx, c.y + dz)
			if not _path_cells.has(cell):
				continue
			for s in _path_cells[cell]:
				if Vector2(s.x, s.y).distance_to(p) < s.z + margin:
					return true
	return false


## Catmull-Rom spline through the points, sampled about every `step` metres.
func _smooth(points: Array, step: float) -> Array:
	var out := []
	var n := points.size()
	for i in n - 1:
		var p0: Vector2 = points[maxi(i - 1, 0)]
		var p1: Vector2 = points[i]
		var p2: Vector2 = points[i + 1]
		var p3: Vector2 = points[mini(i + 2, n - 1)]
		var steps := maxi(2, ceili(p1.distance_to(p2) / step))
		for s in steps:
			var t := float(s) / float(steps)
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(points[n - 1])
	return out


# ------------------------------------------------------------------ plants ----

func _grass_mesh() -> ArrayMesh:
	if _meshes.has("grass"):
		return _meshes["grass"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blades := 11
	for i in blades:
		var a := TAU * float(i) / float(blades) + float(i) * 0.7
		var dir := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-dir.z, 0, dir.x)
		var h := 0.34 + 0.06 * float(i % 4)
		var base := dir * 0.05
		var tip := dir * (0.05 + 0.16 + 0.03 * float(i % 3)) + Vector3(0, h, 0)
		var w := 0.038
		for v in [base - side * w, base + side * w, tip]:
			st.set_color(Color(1, 1, 1, 0.5))
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	_meshes["grass"] = st.commit()
	return _meshes["grass"]


## Wild flower: green stem and leaves, coloured petals, yellow (or custom) centre.
func _flower_mesh(key: String, height: float, head_r: float, center: Color) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var green := Color(0.16, 0.42, 0.11, 0.0)
	var sw := height * 0.03
	for a in [0.0, PI / 2.0]:
		var side := Vector3(cos(a), 0, sin(a)) * sw
		var top := Vector3(0, height, 0)
		for v in [-side, side, top + side * 0.5, -side, top + side * 0.5, top - side * 0.5]:
			st.set_color(green)
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	for k in 2:
		var ang := PI * float(k)
		var dir := Vector3(cos(ang), 0, sin(ang))
		var side := Vector3(-dir.z, 0, dir.x) * height * 0.07
		var y0 := height * 0.25
		for v in [dir * 0.0 + Vector3(0, y0, 0), dir * height * 0.32 + Vector3(0, y0 + height * 0.18, 0) + side, dir * height * 0.32 + Vector3(0, y0 + height * 0.18, 0) - side]:
			st.set_color(green)
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var petals := 6
	var top_c := Vector3(0, height, 0)
	for i in petals:
		var a0 := TAU * float(i) / float(petals)
		var a1 := TAU * float(i + 1) / float(petals)
		for v in [top_c + Vector3(0, head_r * 0.35, 0), top_c + Vector3(cos(a0), -0.12, sin(a0)) * head_r, top_c + Vector3(cos(a1), -0.12, sin(a1)) * head_r]:
			st.set_color(Color(1, 1, 1, 1.0))
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var cr := head_r * 0.42
	for i in 5:
		var a0 := TAU * float(i) / 5.0
		var a1 := TAU * float(i + 1) / 5.0
		for v in [top_c + Vector3(0, head_r * 0.5, 0), top_c + Vector3(cos(a0), 0.25, sin(a0)) * cr, top_c + Vector3(cos(a1), 0.25, sin(a1)) * cr]:
			st.set_color(Color(center.r, center.g, center.b, 0.0))
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	_meshes[key] = st.commit()
	return _meshes[key]


func _cabbage_mesh() -> Mesh:
	if _meshes.has("cabbage"):
		return _meshes["cabbage"]
	var sm := SphereMesh.new()
	sm.radius = 0.32
	sm.height = 0.46
	sm.radial_segments = 8
	sm.rings = 4
	_meshes["cabbage"] = sm
	return sm


func _batch_for(mesh_key: String, mesh: Mesh, p: Vector3, far_distance: float) -> Dictionary:
	var key := "%s|%d|%d" % [mesh_key, floori(p.x / CHUNK), floori(p.z / CHUNK)]
	if not _batches.has(key):
		_batches[key] = {"mesh": mesh, "far": far_distance, "items": []}
	return _batches[key]


func add_plant(mesh_key: String, mesh: Mesh, xform: Transform3D, color: Color, far_distance: float) -> void:
	_batch_for(mesh_key, mesh, xform.origin, far_distance)["items"].append([xform, color])


func add_grass(p: Vector2, scale: float, color: Color) -> void:
	var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale), Vector3(p.x, 0.0, p.y))
	add_plant("grass", _grass_mesh(), t, color, 110.0)


func add_flower(p: Vector2, scale: float, color: Color) -> void:
	var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale), Vector3(p.x, 0.0, p.y))
	add_plant("flower", _flower_mesh("flower", 0.5, 0.15, Color(1.0, 0.82, 0.18)), t, color, 170.0)


## Creates the MultiMeshInstance3D nodes. Call once after everything has been added.
func flush_plants() -> void:
	for key in _batches:
		var b: Dictionary = _batches[key]
		var items: Array = b["items"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = b["mesh"]
		mm.instance_count = items.size()
		for i in items.size():
			mm.set_instance_transform(i, items[i][0])
			mm.set_instance_custom_data(i, items[i][1])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = _plant_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = b["far"]
		mi.visibility_range_end_margin = 20.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		mi.name = key.replace("|", "_")
		add_child(mi)
	_batches.clear()


## Grass everywhere plus wild flower meadows. blocked(Vector2) -> bool keeps them off
## buildings, camps, props and so on; paths are avoided automatically.
func scatter_meadow(reach: float, blocked: Callable) -> void:
	# grass tufts, clumped by a loose noise so there are lush spots and thin spots
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.02
	for i in 42000:
		var p := _random_in_disc(reach)
		if blocked.call(p) or near_path(p, 0.3):
			continue
		var lush := noise.get_noise_2d(p.x, p.y) * 0.5 + 0.5
		if rng.randf() > 0.25 + lush * 0.9:
			continue
		add_grass(p, rng.randf_range(0.5, 1.05), GRASS_COLORS[rng.randi() % GRASS_COLORS.size()].lerp(Color(0.35, 0.65, 0.2), rng.randf() * 0.4))
	# flower patches
	var made := 0
	var tries := 0
	while made < 150 and tries < 1200:
		tries += 1
		var c := _random_in_disc(reach)
		if blocked.call(c) or near_path(c, 1.0):
			continue
		made += 1
		var colors := [FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()], FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()]]
		for k in rng.randi_range(14, 42):
			var p := c + Vector2(rng.randfn(0.0, 3.2), rng.randfn(0.0, 3.2))
			if blocked.call(p) or near_path(p, 0.5):
				continue
			add_flower(p, rng.randf_range(0.6, 1.0), colors[rng.randi() % 2] if rng.randf() < 0.85 else FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()])
			add_grass(p + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4)), rng.randf_range(0.6, 0.95), GRASS_COLORS[rng.randi() % 3])
	# a few lone flowers
	for i in 1400:
		var p := _random_in_disc(reach)
		if blocked.call(p) or near_path(p, 0.5):
			continue
		add_flower(p, rng.randf_range(0.55, 0.95), FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()])


## Flower borders along the paths that asked for them.
func scatter_path_flowers(blocked: Callable) -> void:
	for entry in _edge_paths:
		var pts: Array = entry[0]
		var half: float = entry[1]
		for i in range(0, pts.size(), 1):
			var p: Vector2 = pts[i]
			var dir: Vector2 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
			var nrm := Vector2(-dir.y, dir.x)
			for side in [-1.0, 1.0]:
				if rng.randf() < 0.75:
					var q: Vector2 = p + nrm * side * (half + rng.randf_range(0.5, 2.2)) + dir * rng.randf_range(-0.8, 0.8)
					if blocked.call(q):
						continue
					add_flower(q, rng.randf_range(0.65, 1.05), FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()])
					if rng.randf() < 0.6:
						add_grass(q + Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5)), rng.randf_range(0.6, 1.0), GRASS_COLORS[rng.randi() % GRASS_COLORS.size()])


## A ring of flowers (the bed around the well).
func add_flower_ring(center: Vector2, r_in: float, r_out: float, count: int) -> void:
	for i in count:
		var a := rng.randf() * TAU
		var r := rng.randf_range(r_in, r_out)
		var p := center + Vector2(cos(a), sin(a)) * r
		add_flower(p, rng.randf_range(0.75, 1.2), FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()])
		if rng.randf() < 0.5:
			add_grass(p + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4)), 0.8, GRASS_COLORS[1])


func _random_in_disc(reach: float) -> Vector2:
	var a := rng.randf() * TAU
	var r := sqrt(rng.randf()) * reach
	return Vector2(cos(a), sin(a)) * r


# ----------------------------------------------------------------- gardens ----

## A fenced vegetable garden. center/heading are in the world; the gate is on the +Z side.
func add_garden(center: Vector2, heading_deg: float, size: Vector2) -> void:
	var root := Node3D.new()
	root.position = Vector3(center.x, 0.0, center.y)
	root.rotation_degrees.y = heading_deg
	root.name = "Garden"
	add_child(root)
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(heading_deg)), Vector3(center.x, 0.0, center.y))

	var soil_mat := StandardMaterial3D.new()
	soil_mat.albedo_color = Color(0.36, 0.25, 0.15)
	soil_mat.roughness = 1.0
	var ridge_mat := StandardMaterial3D.new()
	ridge_mat.albedo_color = Color(0.27, 0.18, 0.10)
	ridge_mat.roughness = 1.0
	_box(root, Vector3(0, 0.04, 0), Vector3(size.x, 0.08, size.y), soil_mat)

	var rows := 4
	var row_z := -size.y / 2.0 + 1.3
	var row_gap := (size.y - 2.6) / float(rows - 1)
	for r in rows:
		var z := row_z + row_gap * r
		_box(root, Vector3(0, 0.1, z), Vector3(size.x - 1.2, 0.12, 0.75), ridge_mat)
		var x := -size.x / 2.0 + 1.0
		while x < size.x / 2.0 - 0.8:
			var lp := Vector3(x, 0.12, z)
			var wp := xf * lp
			match r:
				0:  # cabbages
					var c := Color(0.30, 0.62, 0.22).lerp(Color(0.55, 0.75, 0.35), rng.randf())
					add_plant("cabbage", _cabbage_mesh(), Transform3D(Basis(Vector3.UP, rng.randf() * TAU), wp + Vector3(0, 0.12, 0)), c, 120.0)
				1:  # carrot / leek tops
					var c := Color(0.22, 0.55, 0.16)
					add_plant("grass", _grass_mesh(), Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * 1.3), wp), c, 120.0)
				2:  # sunflowers
					var sc := rng.randf_range(0.9, 1.15)
					add_plant("sunflower", _flower_mesh("sunflower", 1.5, 0.30, Color(0.30, 0.17, 0.07)), Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), wp), Color(1.0, 0.80, 0.10), 140.0)
				_:  # marigolds
					add_plant("flower", _flower_mesh("flower", 0.5, 0.15, Color(1.0, 0.82, 0.18)), Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * 1.3), wp), Color(1.0, 0.55, 0.12), 140.0)
			x += 1.0

	_fence_rect(root, size + Vector2(1.2, 1.2), 2.4)
	_scarecrow(root, Vector3(-size.x / 2.0 + 0.2, 0.0, size.y / 2.0 - 0.6))


func _fence_rect(parent: Node3D, size: Vector2, gate_width: float) -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.52, 0.36, 0.20)
	wood.roughness = 0.9
	var hx := size.x / 2.0
	var hz := size.y / 2.0
	var sides := [
		[Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), false],
		[Vector3(hx, 0, -hz), Vector3(hx, 0, hz), false],
		[Vector3(hx, 0, hz), Vector3(-hx, 0, hz), true],
		[Vector3(-hx, 0, hz), Vector3(-hx, 0, -hz), false],
	]
	for s in sides:
		var a: Vector3 = s[0]
		var b: Vector3 = s[1]
		var len := a.distance_to(b)
		var dir := (b - a) / len
		var segments := [[0.0, len]]
		if s[2]:
			var mid := len / 2.0
			segments = [[0.0, mid - gate_width / 2.0], [mid + gate_width / 2.0, len]]
		for seg in segments:
			var s0: float = seg[0]
			var s1: float = seg[1]
			var seg_len := s1 - s0
			var posts := maxi(2, int(seg_len / 2.0) + 1)
			for i in posts:
				var t := s0 + seg_len * float(i) / float(posts - 1)
				_box(parent, a + dir * t + Vector3(0, 0.7, 0), Vector3(0.22, 1.4, 0.22), wood)
			var yaw := atan2(-dir.z, dir.x)
			var mid_p := a + dir * (s0 + seg_len / 2.0)
			for h in [0.5, 1.05]:
				var rail := _box(parent, mid_p + Vector3(0, h, 0), Vector3(seg_len, 0.1, 0.07), wood)
				rail.rotation.y = yaw
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(seg_len, 1.4, 0.3)
			shape.shape = bs
			body.add_child(shape)
			body.position = mid_p + Vector3(0, 0.7, 0)
			body.rotation.y = yaw
			parent.add_child(body)


func _scarecrow(parent: Node3D, pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rng.randf_range(-40.0, 40.0)
	parent.add_child(root)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.31, 0.17)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.74, 0.32, 0.24)
	var straw := StandardMaterial3D.new()
	straw.albedo_color = Color(0.92, 0.80, 0.38)
	var hat := StandardMaterial3D.new()
	hat.albedo_color = Color(0.40, 0.28, 0.15)
	_box(root, Vector3(0, 1.3, 0), Vector3(0.14, 2.6, 0.14), wood)
	_box(root, Vector3(0, 1.9, 0), Vector3(2.0, 0.12, 0.12), wood)
	_box(root, Vector3(0, 1.55, 0), Vector3(0.75, 0.9, 0.3), cloth)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.56
	head.mesh = sm
	head.material_override = straw
	head.position = Vector3(0, 2.4, 0)
	root.add_child(head)
	var brim := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.4
	cm.bottom_radius = 0.4
	cm.height = 0.05
	brim.mesh = cm
	brim.material_override = hat
	brim.position = Vector3(0, 2.62, 0)
	root.add_child(brim)
	var crown := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.17
	cc.bottom_radius = 0.24
	cc.height = 0.3
	crown.mesh = cc
	crown.material_override = hat
	crown.position = Vector3(0, 2.77, 0)
	root.add_child(crown)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.5, 2.6, 0.5)
	shape.shape = bs
	shape.position.y = 1.3
	body.add_child(shape)
	root.add_child(body)


func _box(parent: Node, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


# -------------------------------------------------------------------- pond ----

func add_pond(center: Vector2, radius: float) -> void:
	add_patch(center, radius * 1.45, Color(0.38, 0.30, 0.20), false, Color(0.30, 0.25, 0.16))
	var water := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.05
	cm.radial_segments = 48
	water.mesh = cm
	water.material_override = _water_mat
	water.position = Vector3(center.x, 0.06, center.y)
	water.scale = Vector3(1.0, 1.0, 0.72)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	# reeds around the shore and a few lily pads
	for i in 46:
		var a := rng.randf() * TAU
		var r := radius * rng.randf_range(0.98, 1.22)
		var p := center + Vector2(cos(a) * r, sin(a) * r * 0.72)
		var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(2.0, 3.2)), Vector3(p.x, 0.0, p.y))
		add_plant("grass", _grass_mesh(), t, Color(0.20, 0.45, 0.16).lerp(Color(0.5, 0.65, 0.2), rng.randf() * 0.5), 140.0)
	for i in 14:
		var a := rng.randf() * TAU
		var r := radius * sqrt(rng.randf()) * 0.85
		var p := Vector3(center.x + cos(a) * r, 0.1, center.y + sin(a) * r * 0.72)
		var pad := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		pc.top_radius = 0.55
		pc.bottom_radius = 0.55
		pc.height = 0.03
		pad.mesh = pc
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.20, 0.52, 0.22)
		pad.material_override = pm
		pad.position = p
		add_child(pad)
		if rng.randf() < 0.5:
			add_flower(Vector2(p.x, p.z), 0.5, Color(1.0, 0.75, 0.85))
