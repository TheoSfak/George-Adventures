class_name Frontier
extends Node3D
## The Frontier beyond the northern mountains (story part 3): a mountain pass, the refugee camp
## and the Fortress of Shadow. It is built once, on the first visit, at a far-away origin like the
## catacombs (see catacombs.gd) but it is OUTDOORS: the sky, the sun and the clock keep running.
## Everything is data at the top of the file. Positions are metres relative to ORIGIN: x grows to
## the east, z to the south, so the fortress lies to the north at negative z.

const ORIGIN := Vector3(-6000.0, 0.0, 6000.0)
const VILLAGE_GATE := Vector3(70.0, 0.0, -208.0)      # where the sealed pass gate stands in Agios Vlasis
const BOUNDS := Rect2(-96.0, -214.0, 192.0, 372.0)    # x, z, width, depth of the walkable area
const ENTRY := Vector2(0.0, 118.0)                    # George appears here, facing north
const EXIT := Vector2(0.0, 128.0)                     # the arch that leads back to the village
const CAMP := Vector2(0.0, 0.0)
const CAMP_RADIUS := 30.0
const COURT := Vector2(0.0, -150.0)                   # centre of the fortress courtyard
const FORT := Rect2(-46.0, -186.0, 92.0, 72.0)        # outer walls of the fortress
const GATE_Z := -114.0                                # the fortress gate in the south wall
const GATE_WIDTH := 12.0
const WALL_HEIGHT := 9.0
const WALL_THICK := 3.0

# Where the three Symbols of Shadow (quest "Τα Σύμβολα της Σκιάς") lie
const SYMBOLS := [Vector2(-48.0, 96.0), Vector2(52.0, 58.0), Vector2(-40.0, 24.0)]

# [x, z, rotation in degrees, golden, gold_min, gold_max, potions]
const CHESTS := [
	[14.0, 9.0, 270, false, 40, 90, 1],         # the camp
	[-22.0, 66.0, 90, false, 40, 90, 1],        # the pass
	[24.0, -70.0, 270, true, 90, 160, 2],       # the road to the fortress
	[-36.0, -140.0, 90, true, 120, 200, 3],     # the courtyard
	[34.0, -176.0, 270, true, 180, 260, 3],     # behind the keep
]

# [kind, x, z]  (enemies.gd KINDS). Nothing stands inside the camp (CAMP_RADIUS).
const SPAWNS := [
	# the pass
	["shadow_knight", -14.0, 104.0], ["shadow_knight", 16.0, 94.0], ["soul_collector", -24.0, 88.0],
	["shadow_knight", 20.0, 74.0], ["soul_collector", 26.0, 66.0], ["shadow_knight", -22.0, 62.0],
	["shadow_knight", 12.0, 50.0], ["soul_collector", -16.0, 46.0],
	# the road between the camp and the fortress
	["shadow_knight", -18.0, -44.0], ["shadow_knight", 18.0, -58.0], ["soul_collector", -26.0, -72.0],
	["soul_collector", 24.0, -86.0], ["shadow_knight", 0.0, -100.0],
	# the courtyard
	["shadow_knight", -22.0, -126.0], ["shadow_knight", 22.0, -126.0], ["soul_collector", -28.0, -140.0],
	["soul_collector", 28.0, -140.0], ["shadow_knight", -20.0, -158.0], ["shadow_knight", 20.0, -158.0],
	["giant_skeleton", 0.0, -128.0],
	["malakar", 0.0, -156.0],
]

const G := "res://assets/graveyard/"
const I := "res://assets/items/"
const W := "res://assets/world/"
const C := "res://assets/characters/"

var exit_action := Callable()               # set by Interiors: leaves the Frontier

var _root: Node3D
var _rng := RandomNumberGenerator.new()
var _stone: StandardMaterial3D
var _gate: Node3D
var _gate_open := false
var _bosses := {}                           # boss kind -> Enemy


func _ready() -> void:
	add_to_group("frontier")


## World position of a local coordinate (x east, z south, h up).
static func wp(x: float, z: float, h: float = 0.0) -> Vector3:
	return ORIGIN + Vector3(x, h, z)


## Where George appears.
func spawn_point() -> Vector3:
	return wp(ENTRY.x, ENTRY.y, 0.05)


# --------------------------------------------------------------------- building ----

## Builds the whole region. Await it: the creatures need the physics server to know the colliders.
func build() -> void:
	_rng.seed = 7731
	_root = Node3D.new()
	_root.name = "Level"
	add_child(_root)
	_build_ground()
	_build_boundary()
	_build_exit()
	_build_pass()
	_build_camp()
	_build_fortress()
	_build_gate()
	_build_pickups()
	_build_nav()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_creatures()
	Quests.changed.connect(_on_quests_changed)
	_on_quests_changed()


## The walkable-ground grid the creatures use to get round rocks, trees and walls (see nav_grid.gd).
func _build_nav() -> void:
	var area := BOUNDS.grow(12.0)
	var grid := NavGrid.build([_root], Rect2(Vector2(ORIGIN.x + area.position.x, ORIGIN.z + area.position.y), area.size))
	grid.prepare(true)
	NavGrid.set_region("frontier", grid)


## Snow instead of meadow: the village ground shader with cold colours, a trampled camp,
## a dirt track up the pass and a cobbled road to the fortress.
func _build_ground() -> void:
	var terrain := Terrain.new()
	terrain.name = "Terrain"
	terrain.position = ORIGIN                  # its geometry is local, the shaders use world noise
	_root.add_child(terrain)
	terrain.setup(7731)
	terrain.set_world_offset(Vector2(ORIGIN.x, ORIGIN.z))     # the noise needs small numbers (see Terrain.set_world_offset)
	var mat: ShaderMaterial = terrain._ground_mat
	mat.set_shader_parameter("grass_light", Color(0.93, 0.95, 1.0))
	mat.set_shader_parameter("grass_mid", Color(0.80, 0.84, 0.92))
	mat.set_shader_parameter("grass_dark", Color(0.60, 0.66, 0.76))
	mat.set_shader_parameter("dry_grass", Color(0.55, 0.52, 0.50))
	terrain.build_ground(Vector2(150.0, 260.0))   # after the colours: the far plane copies them
	terrain.add_patch(CAMP, CAMP_RADIUS + 6.0, Color(0.52, 0.48, 0.44), false, Color(0.34, 0.31, 0.29))
	terrain.add_patch(COURT, 52.0, Color(0.34, 0.33, 0.37), true, Color(0.20, 0.19, 0.23))
	terrain.add_path([Vector2(0, 126), Vector2(10, 100), Vector2(-9, 72), Vector2(4, 44), Vector2(0, 28)], 6.0)
	terrain.add_path([Vector2(0, -28), Vector2(-6, -60), Vector2(5, -90), Vector2(0, -112)], 7.0, true)
	# one big invisible floor so George never falls
	var body := StaticBody3D.new()
	body.name = "GroundCollider"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BOUNDS.size.x + 80.0, 2.0, BOUNDS.size.y + 80.0)
	shape.shape = box
	body.add_child(shape)
	body.position = wp(BOUNDS.get_center().x, BOUNDS.get_center().y, -1.0)
	_root.add_child(body)


## Invisible rock walls keep George inside; a ring of real mountains stands behind them.
func _build_boundary() -> void:
	var rim := BOUNDS.grow(2.0)
	var c := rim.get_center()
	for s in [
		[Vector2(c.x, rim.position.y), Vector2(rim.size.x + 8.0, 4.0)],
		[Vector2(c.x, rim.end.y), Vector2(rim.size.x + 8.0, 4.0)],
		[Vector2(rim.position.x, c.y), Vector2(4.0, rim.size.y + 8.0)],
		[Vector2(rim.end.x, c.y), Vector2(4.0, rim.size.y + 8.0)],
	]:
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(s[1].x, 40.0, s[1].y)
		shape.shape = box
		wall.add_child(shape)
		wall.position = wp(s[0].x, s[0].y, 20.0)
		_root.add_child(wall)
	var models := ["mountain_A", "mountain_B", "mountain_C"]
	var step := 34.0
	var x := rim.position.x - 10.0
	while x <= rim.end.x + 10.0:
		_mountain(models, Vector2(x, rim.position.y - 14.0))
		_mountain(models, Vector2(x, rim.end.y + 14.0))
		x += step
	var z := rim.position.y
	while z <= rim.end.y:
		_mountain(models, Vector2(rim.position.x - 14.0, z))
		_mountain(models, Vector2(rim.end.x + 14.0, z))
		z += step


func _mountain(models: Array, at: Vector2) -> void:
	var model := (load(W + "decoration/nature/%s.gltf" % models[_rng.randi() % models.size()]) as PackedScene).instantiate() as Node3D
	model.position = wp(at.x + _rng.randf_range(-6.0, 6.0), at.y + _rng.randf_range(-6.0, 6.0))
	model.rotation_degrees.y = _rng.randi_range(0, 5) * 60.0
	model.scale = Vector3.ONE * _rng.randf_range(18.0, 24.0)
	_root.add_child(model)


## A stone arch at the south end of the pass: the way back to Agios Vlasis.
func _build_exit() -> void:
	var arch := (load(G + "arch_gate.gltf") as PackedScene).instantiate() as Node3D
	arch.position = wp(EXIT.x, EXIT.y + 3.0)
	arch.scale = Vector3.ONE * 3.0
	_root.add_child(arch)
	var spot := InteractSpot.make(Strings.PROMPT_FRONTIER_BACK, func(p: Player): exit_action.call(p), 3.6)
	spot.position = wp(EXIT.x, EXIT.y)
	_root.add_child(spot)


# ---------------------------------------------------------------------- helpers ----

func _box(pos: Vector3, size: Vector3, mat: Material, solid: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	_root.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var collider := BoxShape3D.new()
		collider.size = size
		shape.shape = collider
		body.add_child(shape)
		mi.add_child(body)
	return mi


func _prop(path: String, x: float, z: float, yaw_deg: float, scale_: float, lift: float = 0.0, solid: bool = false) -> Node3D:
	var model := (load(path) as PackedScene).instantiate() as Node3D
	model.position = wp(x, z, lift)
	model.rotation_degrees.y = yaw_deg
	model.scale = Vector3.ONE * scale_
	_root.add_child(model)
	if solid:
		Interiors.collider_for(model)
	return model


# ------------------------------------------------------------------- the pass ----

## True where nothing may stand: the tracks, the camp, the fortress with its road, the arch
## and the places the Symbols of Shadow lie.
func _blocked(p: Vector2) -> bool:
	if p.length() < CAMP_RADIUS + 8.0:
		return true
	if absf(p.x) < 14.0 and (p.y > 20.0 or (p.y < -20.0 and p.y > GATE_Z - 8.0)):
		return true
	if FORT.grow(12.0).has_point(p) or COURT.distance_to(p) < 60.0:
		return true
	if ENTRY.distance_to(p) < 14.0 or EXIT.distance_to(p) < 10.0:
		return true
	for s in SYMBOLS:
		if s.distance_to(p) < 7.0:
			return true
	return false


## Dead trees, boulders, three lantern posts and skull posts along the track.
func _build_pass() -> void:
	var rocks := ["A", "B", "C", "D", "E"]
	var trees := [G + "tree_dead_large.gltf", G + "tree_dead_medium.gltf", G + "tree_dead_small.gltf"]
	var placed := 0
	var tries := 0
	while placed < 150 and tries < 1500:
		tries += 1
		var p := Vector2(_rng.randf_range(BOUNDS.position.x + 6.0, BOUNDS.end.x - 6.0),
				_rng.randf_range(BOUNDS.position.y + 6.0, BOUNDS.end.y - 6.0))
		if _blocked(p):
			continue
		placed += 1
		if _rng.randf() < 0.7:
			_prop(trees[_rng.randi() % trees.size()], p.x, p.y, _rng.randf() * 360.0, _rng.randf_range(2.6, 3.4))
			_trunk(p, 0.9)
		else:
			var rock := _prop(W + "decoration/nature/rock_single_%s.gltf" % rocks[_rng.randi() % rocks.size()],
					p.x, p.y, _rng.randf() * 360.0, _rng.randf_range(7.0, 14.0))
			Interiors.collider_for(rock)
	for z in [100.0, 70.0, 42.0]:
		_lamp(8.0 if z != 70.0 else -8.0, z)
	for z in [110.0, 80.0, 52.0]:
		_prop(G + "post_skull.gltf", -12.0, z, 90.0, 1.6)
		_prop(G + "post_skull.gltf", 12.0, z + 6.0, 270.0, 1.6)


## A thin collider for the trunk of a tree.
func _trunk(p: Vector2, radius: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 6.0
	shape.shape = cyl
	body.add_child(shape)
	body.position = wp(p.x, p.y, 3.0)
	_root.add_child(body)


## A lantern post with a cold light that switches on after dusk (group night_lights).
func _lamp(x: float, z: float) -> void:
	_prop(G + "lantern_standing.gltf", x, z, 0.0, 2.4, 0.0, true)
	var light := OmniLight3D.new()
	light.position = wp(x, z, 2.4)
	light.light_color = Color(0.65, 0.75, 1.0)
	light.light_energy = 1.2
	light.omni_range = 11.0
	light.add_to_group("night_lights")
	_root.add_child(light)


## A fire that burns day and night: a torch model and a warm light.
func _fire(x: float, z: float, scale_: float, range_m: float, energy: float) -> void:
	_prop(I + "torch_lit.gltf.glb", x, z, 0.0, scale_)
	var light := OmniLight3D.new()
	light.position = wp(x, z, 2.6)
	light.light_color = Color(1.0, 0.62, 0.30)
	light.light_energy = energy
	light.omni_range = range_m
	_root.add_child(light)


# -------------------------------------------------------------------- the camp ----

func _build_camp() -> void:
	for i in 6:                                   # six tents in a ring, doors toward the fire
		var a := TAU * (float(i) + 0.5) / 6.0
		var p := CAMP + Vector2(cos(a), sin(a)) * 19.0
		var tent := _prop(W + "decoration/props/tent.gltf", p.x, p.y, rad_to_deg(atan2(-p.x, -p.y)), 10.0)
		Interiors.collider_for(tent)
	_fire(CAMP.x, CAMP.y, 3.2, 24.0, 3.0)         # the big fire in the middle
	for off in [Vector2(-10, -7), Vector2(10, -7), Vector2(-10, 10), Vector2(10, 10)]:
		_fire(off.x, off.y, 2.4, 9.0, 1.4)
	var P := W + "decoration/props/"
	_prop(P + "crate_A_big.gltf", 13.0, -3.0, 20.0, 7.0, 0.0, true)
	_prop(P + "barrel.gltf", 15.0, -1.0, 0.0, 7.0, 0.0, true)
	_prop(P + "sack.gltf", -13.0, -4.0, 40.0, 7.0)
	_prop(P + "weaponrack.gltf", -4.0, 13.0, 180.0, 7.0, 0.0, true)
	_prop(P + "wheelbarrow.gltf", 6.0, 13.0, 60.0, 7.0)


# ----------------------------------------------------------------- the fortress ----

func _stone_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Catacombs._brick_texture()
	m.albedo_color = Color(0.75, 0.72, 0.85)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * 0.25
	m.roughness = 0.95
	return m


## The scale that makes a model `width` metres wide (its longest horizontal side).
func _fit_scale(model: Node3D, width: float) -> float:
	var box := _aabb(model)
	return width / maxf(maxf(box.size.x, box.size.z), 0.01)


## Merged bounding box of all meshes of a model, in the model's own space.
func _aabb(model: Node3D) -> AABB:
	var have := false
	var box := AABB()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var t := Transform3D.IDENTITY
		var n: Node = mi
		while n != model and n != null:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		var a: AABB = t * mi.get_aabb()
		box = a if not have else box.merge(a)
		have = true
	return box


## A colour wash over every mesh of a model (the castle gets a dark violet tone).
func _tint(model: Node3D, color: Color) -> void:
	var wash := StandardMaterial3D.new()
	wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wash.albedo_color = color
	for node in model.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_overlay = wash


## One straight stone wall with battlements between two points (axis-aligned).
func _wall(a: Vector2, b: Vector2) -> void:
	var horizontal := absf(b.x - a.x) > absf(b.y - a.y)
	var length := absf(b.x - a.x) if horizontal else absf(b.y - a.y)
	var mid := (a + b) / 2.0
	var size := Vector3(length, WALL_HEIGHT, WALL_THICK) if horizontal else Vector3(WALL_THICK, WALL_HEIGHT, length)
	_box(wp(mid.x, mid.y, WALL_HEIGHT / 2.0), size, _stone, true)
	var count := maxi(int(length / 4.0), 1)
	for i in count:
		var p := a.lerp(b, (float(i) + 0.5) / float(count))
		var merlon := Vector3(1.8, 1.2, WALL_THICK + 0.2) if horizontal else Vector3(WALL_THICK + 0.2, 1.2, 1.8)
		_box(wp(p.x, p.y, WALL_HEIGHT + 0.6), merlon, _stone, false)


## A round tower with a dark cone roof.
func _tower(at: Vector2) -> void:
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 5.0
	cyl.bottom_radius = 5.4
	cyl.height = WALL_HEIGHT + 6.0
	body.mesh = cyl
	body.material_override = _stone
	body.position = wp(at.x, at.y, cyl.height / 2.0)
	_root.add_child(body)
	var collider := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var shape_cyl := CylinderShape3D.new()
	shape_cyl.radius = 5.4
	shape_cyl.height = cyl.height
	shape.shape = shape_cyl
	collider.add_child(shape)
	body.add_child(collider)
	var roof := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 6.6
	cone.height = 6.0
	roof.mesh = cone
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.16, 0.10, 0.24)
	roof_mat.roughness = 0.9
	roof.material_override = roof_mat
	roof.position = wp(at.x, at.y, cyl.height + 3.0)
	_root.add_child(roof)


func _build_fortress() -> void:
	_stone = _stone_material()
	var f := FORT
	var half_gap := GATE_WIDTH / 2.0
	_wall(Vector2(f.position.x, f.end.y), Vector2(-half_gap, f.end.y))      # south wall, left of the gate
	_wall(Vector2(half_gap, f.end.y), Vector2(f.end.x, f.end.y))            # south wall, right of the gate
	_wall(Vector2(f.position.x, f.position.y), Vector2(f.end.x, f.position.y))   # north wall
	_wall(Vector2(f.position.x, f.position.y), Vector2(f.position.x, f.end.y))   # west wall
	_wall(Vector2(f.end.x, f.position.y), Vector2(f.end.x, f.end.y))             # east wall
	for corner in [f.position, Vector2(f.end.x, f.position.y), Vector2(f.position.x, f.end.y), f.end]:
		_tower(corner)
	_tower(Vector2(-half_gap - 5.8, f.end.y))                               # the two gate towers
	_tower(Vector2(half_gap + 5.8, f.end.y))
	# the keep at the back of the courtyard: the red castle, darkened
	var keep := (load(W + "buildings/red/building_castle_red.gltf") as PackedScene).instantiate() as Node3D
	keep.scale = Vector3.ONE * _fit_scale(keep, 26.0)
	keep.position = wp(0.0, -172.0)
	_tint(keep, Color(0.10, 0.06, 0.18, 0.55))
	_root.add_child(keep)
	Interiors.collider_for(keep)
	# purple braziers along the courtyard
	for z in [-126.0, -146.0, -166.0]:
		for x in [-30.0, 30.0]:
			_brazier(x, z)
	# bones and skulls on the stones
	var bones := [G + "bone_A.gltf", G + "bone_B.gltf", G + "bone_C.gltf", G + "skull.gltf", G + "ribcage.gltf"]
	var yard := f.grow(-7.0)
	for i in 26:
		var p := Vector2(_rng.randf_range(yard.position.x, yard.end.x), _rng.randf_range(yard.position.y, yard.end.y))
		if absf(p.x) < 9.0 and p.y > -160.0:
			continue                                                  # keep the middle lane clear for the fights
		_prop(bones[_rng.randi() % bones.size()], p.x, p.y, _rng.randf() * 360.0, _rng.randf_range(1.2, 1.8))


func _brazier(x: float, z: float) -> void:
	_prop(I + "torch_lit.gltf.glb", x, z, 0.0, 3.2)
	var light := OmniLight3D.new()
	light.position = wp(x, z, 3.0)
	light.light_color = Color(0.75, 0.55, 1.0)
	light.light_energy = 1.6
	light.omni_range = 15.0
	_root.add_child(light)


## The sealed fortress gate: it dissolves when the quest "Τα Σύμβολα της Σκιάς" is ready.
func _build_gate() -> void:
	_gate = Node3D.new()
	_root.add_child(_gate)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(GATE_WIDTH, WALL_HEIGHT, 0.8)
	shape.shape = box
	body.add_child(shape)
	body.set_meta("nav_ignore", true)       # the gate dissolves later: the navigation grid must not remember it
	body.position = wp(0.0, GATE_Z, WALL_HEIGHT / 2.0)
	_gate.add_child(body)
	var barrier := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(GATE_WIDTH, WALL_HEIGHT, 0.4)
	barrier.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.3, 1.0, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.3, 1.0)
	mat.emission_energy_multiplier = 1.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	barrier.material_override = mat
	barrier.position = body.position
	barrier.add_to_group("frontier_gate")
	_gate.add_child(barrier)
	var light := OmniLight3D.new()
	light.light_color = Color(0.65, 0.35, 1.0)
	light.light_energy = 2.0
	light.omni_range = 14.0
	light.position = wp(0.0, GATE_Z + 2.0, 4.0)
	_gate.add_child(light)
	var label := Label3D.new()
	label.text = Strings.PROMPT_FORTRESS_GATE
	label.font_size = 52
	label.pixel_size = 0.0085
	label.outline_size = 16
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.85, 0.7, 1.0)
	label.no_depth_test = true
	label.position = wp(0.0, GATE_Z + 1.2, WALL_HEIGHT * 0.8)
	_gate.add_child(label)
	var spot := InteractSpot.make(Strings.PROMPT_FORTRESS_GATE, func(p: Player): p.message.emit(Strings.MSG_FORTRESS_SEALED), 5.0)
	spot.position = wp(0.0, GATE_Z + 3.0)
	_gate.add_child(spot)


func _on_quests_changed() -> void:
	if not _gate_open and Quests.state["f_symbols"] >= Quests.S.READY:
		_open_gate()
	_check_bosses()


func _open_gate() -> void:
	_gate_open = true
	if is_instance_valid(_gate):
		var player := get_tree().get_first_node_in_group("player") as Player
		if player:
			player.message.emit(Strings.MSG_FORTRESS_OPEN)
		Sfx.ui("quest_ready")
		var g := _gate
		_gate = null
		for child in g.get_children():
			if child is StaticBody3D or child is InteractSpot:
				child.queue_free()
			if child.is_in_group("frontier_gate"):
				child.remove_from_group("frontier_gate")
		var tween := create_tween()
		tween.tween_interval(0.6)
		tween.tween_callback(g.queue_free)


# ------------------------------------------------------- pickups, people, enemies ----

func _build_pickups() -> void:
	for c in CHESTS:
		var chest := Chest.new()
		chest.golden = c[3]
		chest.gold_min = c[4]
		chest.gold_max = c[5]
		chest.potions = c[6]
		chest.position = wp(c[0], c[1])
		chest.rotation_degrees.y = c[2]
		_root.add_child(chest)
		if SaveGame.opened_chests.has(SaveGame.key_for(chest.position)):
			chest.mark_opened()
	for s in SYMBOLS:
		var pos := wp(s.x, s.y)
		if SaveGame.collected_items.has("symbol@" + SaveGame.key_for(pos)):
			continue
		var item := QuestItem.new()
		item.item_id = "symbol"
		item.position = pos
		_root.add_child(item)
	# the two people of the refugee camp
	var ilarion := Npc.new()
	ilarion.npc_id = "ilarion"
	ilarion.rest_yaw = 0.8
	ilarion.position = wp(-5.0, 3.0, 0.05)
	_root.add_child(ilarion)
	var elpida := Npc.new()
	elpida.npc_id = "elpida"
	elpida.rest_yaw = -0.8
	elpida.position = wp(6.0, 3.0, 0.05)
	_root.add_child(elpida)


func _spawn_creatures() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null:
		push_warning("frontier.gd: no enemy spawner")
		return
	for s in SPAWNS:
		var enemy: Enemy = spawner.spawn_extra(s[0], wp(s[1], s[2], 0.05))
		if enemy and s[0] in _boss_kinds():
			_bosses[s[0]] = enemy


func _boss_kinds() -> Array:
	return ["giant_skeleton", "malakar"]


## A boss that was killed before his quest began comes back when the quest is taken.
func _check_bosses() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null:
		return
	for s in SPAWNS:
		var kind: String = s[0]
		if not kind in _boss_kinds():
			continue
		var quest: String = spawner.KINDS[kind]["quest"]
		if Quests.state[quest] != Quests.S.ACTIVE:
			continue
		var alive: bool = _bosses.has(kind) and is_instance_valid(_bosses[kind]) and not _bosses[kind].is_dead()
		var wanted := false
		for i in QuestData.QUESTS[quest]["objectives"].size():
			var o: Dictionary = QuestData.QUESTS[quest]["objectives"][i]
			if o["type"] == "kill" and o["target"] == kind and Quests.progress[quest][i] < o["count"]:
				wanted = true
		if wanted and not alive:
			var enemy: Enemy = spawner.spawn_extra(kind, wp(s[1], s[2], 0.05))
			if enemy:
				_bosses[kind] = enemy
