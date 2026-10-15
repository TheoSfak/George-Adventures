class_name AshValley
extends Node3D
## The Ash Valley beyond the south-eastern mountains (story part 4): a burning valley with the
## Shelter (a camp that is not burning yet), a river of lava with a stone bridge, and the Temple of
## the Flame where the Keeper (Πυρφόρος) waits. Built once, on the first visit, at a far-away origin
## like the Frontier (see frontier.gd) and OUTDOORS: the sky, the sun and the clock keep running.
## Everything is data at the top of the file. Positions are metres relative to ORIGIN: x grows to the
## east, z to the south, so the temple lies to the north at negative z.

const ORIGIN := Vector3(6000.0, 0.0, -6000.0)
const VILLAGE_GATE := Vector3(178.0, 0.0, 64.0)       # where the sealed Ash Gate stands in Agios Vlasis
const BOUNDS := Rect2(-90.0, -210.0, 180.0, 350.0)    # x, z, width, depth of the walkable area
const ENTRY := Vector2(0.0, 116.0)                    # George appears here, facing north
const EXIT := Vector2(0.0, 128.0)                     # the arch that leads back to the village
const CAMP := Vector2(0.0, 30.0)
const CAMP_RADIUS := 28.0
const STREAM_Z := -60.0                               # the river of lava winds around this line
const STREAM_WIDTH := 14.0
const STREAM_WAVE := 6.0
const BRIDGE_HALF := 6.5                              # the bridge (and the gap in the lava walls) spans x = -6.5 to 6.5
const TEMPLE := Rect2(-40.0, -200.0, 80.0, 70.0)      # outer walls of the temple
const GATE_Z := -130.0                                # the temple gate in the south wall
const GATE_WIDTH := 12.0
const WALL_HEIGHT := 8.0
const WALL_THICK := 3.0
const FLAME := Vector2(0.0, -192.0)                   # the Flame of the Keeper at the back of the temple

# Where the three Shards of the Flame (quest "Τα Θραύσματα της Φλόγας") lie
const SHARDS := [Vector2(-56.0, 76.0), Vector2(54.0, -24.0), Vector2(-48.0, -98.0)]
# Where the four Crystals of Lava (quest "Οι Κρύσταλλοι της Λάβας") lie along the banks
const CRYSTALS := [Vector2(-28.0, -52.0), Vector2(26.0, -50.0), Vector2(-12.0, -70.0), Vector2(32.0, -68.0)]

# [x, z, rotation in degrees, golden, gold_min, gold_max, potions]
const CHESTS := [
	[14.0, 40.0, 270, false, 60, 120, 1],         # the Shelter
	[-50.0, 22.0, 90, false, 60, 120, 1],         # west of the camp
	[46.0, -96.0, 270, true, 140, 260, 2],        # beyond the lava river
	[-34.0, -184.0, 90, true, 220, 340, 3],       # inside the temple
]

# [kind, x, z]  (enemies.gd KINDS). Nothing stands inside the camp (CAMP_RADIUS).
const SPAWNS := [
	# the ash road
	["ember_skeleton", -14.0, 104.0], ["ember_skeleton", 16.0, 96.0], ["ash_caster", -30.0, 98.0],
	["ember_skeleton", -24.0, 86.0], ["ember_skeleton", 22.0, 80.0], ["ash_caster", 30.0, 90.0],
	["ember_skeleton", -8.0, 70.0], ["ember_skeleton", 30.0, 68.0],
	# between the camp and the lava river
	["ember_skeleton", -22.0, -12.0], ["ember_skeleton", 24.0, -18.0], ["ash_caster", -10.0, -40.0],
	["ember_skeleton", -34.0, -34.0], ["ember_skeleton", 36.0, -38.0], ["ash_caster", 0.0, -28.0],
	# beyond the river
	["ember_skeleton", -24.0, -80.0], ["ember_skeleton", 26.0, -86.0], ["ash_caster", -16.0, -92.0],
	["ember_skeleton", 0.0, -98.0], ["ash_caster", 18.0, -104.0], ["ember_skeleton", -36.0, -108.0],
	["ember_skeleton", 38.0, -112.0], ["ash_caster", -30.0, -122.0], ["ash_caster", 32.0, -124.0],
	["magma_golem", -46.0, -84.0], ["magma_golem", 48.0, -100.0], ["magma_golem", -14.0, -114.0],
	["ash_lord", 52.0, -82.0],
	# the temple
	["ember_skeleton", -20.0, -146.0], ["ember_skeleton", 20.0, -146.0], ["ash_caster", -30.0, -160.0],
	["ash_caster", 30.0, -160.0], ["ember_skeleton", -20.0, -180.0], ["ember_skeleton", 20.0, -180.0],
	["pyrforos", 0.0, -166.0],
]

const G := "res://assets/graveyard/"
const I := "res://assets/items/"
const W := "res://assets/world/"

var exit_action := Callable()               # set by Interiors: leaves the valley

var _root: Node3D
var _rng := RandomNumberGenerator.new()
var _stone: StandardMaterial3D
var _lava: ShaderMaterial
var _wash: StandardMaterial3D               # one dark red wash for mountains and rocks
var _terrain: Terrain
var _gate: Node3D
var _gate_open := false
var _bosses := {}                           # boss kind -> Enemy
var _flickers: Array = []                   # [OmniLight3D, base energy, phase] of the fires that breathe
var _embers: GPUParticles3D
var _player: Player
var _time := 0.0


func _ready() -> void:
	add_to_group("ashvalley")


## World position of a local coordinate (x east, z south, h up).
static func wp(x: float, z: float, h: float = 0.0) -> Vector3:
	return ORIGIN + Vector3(x, h, z)


## The middle line of the lava river at a given x.
static func stream_z(x: float) -> float:
	return STREAM_Z + STREAM_WAVE * sin(x * 0.045)


## Where George appears.
func spawn_point() -> Vector3:
	return wp(ENTRY.x, ENTRY.y, 0.05)


func _process(delta: float) -> void:
	_time += delta
	for f in _flickers:
		var light: OmniLight3D = f[0]
		if is_instance_valid(light):
			light.light_energy = float(f[1]) * (1.0 + 0.12 * sin(_time * 7.0 + float(f[2])) + 0.07 * sin(_time * 13.0 + float(f[2]) * 2.0))
	if _embers != null:
		if _player == null:
			_player = get_tree().get_first_node_in_group("player") as Player
		if _player != null:
			_embers.global_position = _player.global_position + Vector3(0.0, 3.0, 0.0)


# --------------------------------------------------------------------- building ----

## Builds the whole region. Await it: the creatures need the physics server to know the colliders.
func build() -> void:
	_rng.seed = 4417
	_root = Node3D.new()
	_root.name = "Level"
	add_child(_root)
	_wash = StandardMaterial3D.new()
	_wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_wash.albedo_color = Color(0.14, 0.05, 0.03, 0.72)
	_lava = ShaderMaterial.new()
	_lava.shader = load("res://shaders/lava.gdshader") as Shader
	_lava.set_shader_parameter("world_offset", Vector2(ORIGIN.x, ORIGIN.z))
	_stone = _stone_material()
	_build_ground()
	_build_boundary()
	_build_exit()
	_build_lava()
	_build_valley()
	_build_camp()
	_build_temple()
	_build_gate()
	_build_pickups()
	_build_nav()
	_build_embers()
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
	NavGrid.set_region("ashvalley", grid)


## Ash instead of meadow: the village ground shader with grey and ember colours, a trampled camp,
## a dirt track up the road and a cobbled one to the temple.
func _build_ground() -> void:
	var terrain := Terrain.new()
	_terrain = terrain
	terrain.name = "Terrain"
	terrain.position = ORIGIN                  # its geometry is local, the shaders use world noise
	_root.add_child(terrain)
	terrain.setup(4417)
	terrain.set_world_offset(Vector2(ORIGIN.x, ORIGIN.z))     # the noise needs small numbers (see Terrain.set_world_offset)
	var mat: ShaderMaterial = terrain._ground_mat
	mat.set_shader_parameter("grass_light", Color(0.44, 0.38, 0.34))
	mat.set_shader_parameter("grass_mid", Color(0.31, 0.26, 0.23))
	mat.set_shader_parameter("grass_dark", Color(0.17, 0.13, 0.12))
	mat.set_shader_parameter("dry_grass", Color(0.42, 0.22, 0.10))
	terrain._path_dirt.set_shader_parameter("base_color", Color(0.27, 0.23, 0.21))      # ash tracks, not sand
	terrain._path_dirt.set_shader_parameter("edge_color", Color(0.14, 0.11, 0.10))
	terrain._path_cobble.set_shader_parameter("base_color", Color(0.33, 0.28, 0.27))
	terrain._path_cobble.set_shader_parameter("edge_color", Color(0.14, 0.11, 0.10))
	terrain.build_ground(Vector2(140.0, 250.0))   # after the colours: the far plane copies them
	terrain.add_patch(CAMP, CAMP_RADIUS + 6.0, Color(0.34, 0.29, 0.25), false, Color(0.20, 0.16, 0.14))
	terrain.add_patch(Vector2(0.0, -165.0), 50.0, Color(0.24, 0.20, 0.20), true, Color(0.12, 0.09, 0.09))
	terrain.add_path([Vector2(0, 126), Vector2(8, 100), Vector2(-8, 72), Vector2(0, 58)], 6.0)
	terrain.add_path([Vector2(0, 2), Vector2(-6, -20), Vector2(4, -44)], 6.0)
	terrain.add_path([Vector2(0, -76), Vector2(-5, -100), Vector2(3, -126)], 7.0, true)
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


## Invisible rock walls keep George inside; a ring of dark red mountains stands behind them.
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
	_wash_over(model)
	_root.add_child(model)


## A stone arch at the south end of the road: the way back to Agios Vlasis.
func _build_exit() -> void:
	var arch := (load(G + "arch_gate.gltf") as PackedScene).instantiate() as Node3D
	arch.position = wp(EXIT.x, EXIT.y + 3.0)
	arch.scale = Vector3.ONE * 3.0
	_root.add_child(arch)
	var spot := InteractSpot.make(Strings.PROMPT_ASH_BACK, func(p: Player): exit_action.call(p), 3.6)
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


## A dark red wash over every mesh of a model (mountains and rocks look scorched).
func _wash_over(model: Node3D) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_overlay = _wash


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


## A light that breathes a little (fires, braziers).
func _fire_light(x: float, z: float, h: float, color: Color, energy: float, range_m: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = wp(x, z, h)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	_root.add_child(light)
	_flickers.append([light, energy, _rng.randf() * TAU])
	return light


## A fire that burns day and night: a torch model and a warm light.
func _fire(x: float, z: float, scale_: float, range_m: float, energy: float) -> void:
	_prop(I + "torch_lit.gltf.glb", x, z, 0.0, scale_)
	_fire_light(x, z, 2.6, Color(1.0, 0.62, 0.30), energy, range_m)


## A lantern post with a warm light that switches on after dusk (group night_lights).
func _lamp(x: float, z: float) -> void:
	_prop(G + "lantern_standing.gltf", x, z, 0.0, 2.4, 0.0, true)
	var light := OmniLight3D.new()
	light.position = wp(x, z, 2.4)
	light.light_color = Color(1.0, 0.68, 0.38)
	light.light_energy = 1.3
	light.omni_range = 11.0
	light.add_to_group("night_lights")
	_root.add_child(light)


# ------------------------------------------------------------ lava and the valley ----

## The river of lava: a chain of flat boxes with the flowing lava material, a dark rim under
## them, invisible walls along it (except at the bridge) and a stone bridge at x = 0.
func _build_lava() -> void:
	var step := 6.5
	var x := -91.0
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.07, 0.04, 0.035)
	rim_mat.roughness = 1.0
	while x < 91.0 - 0.01:
		var a := Vector2(x, stream_z(x))
		var b := Vector2(x + step, stream_z(x + step))
		var mid := (a + b) * 0.5
		var length := a.distance_to(b)
		var yaw := -atan2(b.y - a.y, b.x - a.x)
		var lava := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(length + 0.8, 0.1, STREAM_WIDTH)
		lava.mesh = mesh
		lava.material_override = _lava
		lava.position = wp(mid.x, mid.y, 0.1)
		lava.rotation.y = yaw
		lava.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_root.add_child(lava)
		var rim := MeshInstance3D.new()
		var rim_mesh := BoxMesh.new()
		rim_mesh.size = Vector3(length + 0.8, 0.1, STREAM_WIDTH + 3.0)
		rim.mesh = rim_mesh
		rim.material_override = rim_mat
		rim.position = wp(mid.x, mid.y, 0.07)
		rim.rotation.y = yaw
		_root.add_child(rim)
		if absf(mid.x) > BRIDGE_HALF - 0.1:
			var wall := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(length + 0.4, 4.0, STREAM_WIDTH)
			shape.shape = box
			wall.add_child(shape)
			wall.position = wp(mid.x, mid.y, 2.0)
			wall.rotation.y = yaw
			_root.add_child(wall)
		x += step
	for lx in [-72.0, -36.0, 0.0, 36.0, 72.0]:
		_fire_light(lx, stream_z(lx), 1.6, Color(1.0, 0.45, 0.12), 2.3, 24.0)
	_build_bridge()


## The stone bridge: a flat deck a hair above the lava with posts and low walls along its sides.
func _build_bridge() -> void:
	var zc := stream_z(0.0)
	var deck := _box(wp(0.0, zc, 0.1), Vector3(BRIDGE_HALF * 2.0, 0.16, STREAM_WIDTH + 8.0), _stone, false)
	deck.name = "Bridge"
	for side in [-1.0, 1.0]:
		var edge: float = side * (BRIDGE_HALF - 0.5)
		for dz in [-10.0, -3.5, 3.5, 10.0]:
			var post := _box(wp(edge, zc + dz, 0.9), Vector3(0.9, 1.8, 0.9), _stone, true)
			post.name = "BridgePost"
		_box(wp(edge, zc, 0.45), Vector3(0.5, 0.9, STREAM_WIDTH + 8.0), _stone, true)


## True where nothing may stand: the tracks, the camp, the river, the temple with its road, the arch
## and the places of the shards, the chests and the creatures.
func _blocked(p: Vector2) -> bool:
	if (p - CAMP).length() < CAMP_RADIUS + 6.0:
		return true
	if absf(p.x) < 12.0 and (p.y > 50.0 or (p.y < 0.0 and p.y > GATE_Z - 8.0)):
		return true
	if absf(p.y - stream_z(p.x)) < STREAM_WIDTH * 0.5 + 6.0:
		return true
	if TEMPLE.grow(14.0).has_point(p):
		return true
	if ENTRY.distance_to(p) < 14.0 or EXIT.distance_to(p) < 10.0:
		return true
	for s in SHARDS:
		if s.distance_to(p) < 7.0:
			return true
	for c in CHESTS:
		if Vector2(c[0], c[1]).distance_to(p) < 6.0:
			return true
	for s in SPAWNS:
		if Vector2(s[1], s[2]).distance_to(p) < (9.0 if s[0] == "magma_golem" else 5.0):
			return true
	return false


## Dead trees, scorched boulders, lantern posts and skull posts along the road, glowing cracks in the ground.
func _build_valley() -> void:
	var rocks := ["A", "B", "C", "D", "E"]
	var trees := [G + "tree_dead_large.gltf", G + "tree_dead_medium.gltf", G + "tree_dead_small.gltf"]
	var placed := 0
	var tries := 0
	while placed < 140 and tries < 1500:
		tries += 1
		var p := Vector2(_rng.randf_range(BOUNDS.position.x + 6.0, BOUNDS.end.x - 6.0),
				_rng.randf_range(BOUNDS.position.y + 6.0, BOUNDS.end.y - 6.0))
		if _blocked(p):
			continue
		placed += 1
		if _rng.randf() < 0.65:
			var tree := _prop(trees[_rng.randi() % trees.size()], p.x, p.y, _rng.randf() * 360.0, _rng.randf_range(2.6, 3.4))
			_wash_over(tree)
			_trunk(p, 0.9)
		else:
			var rock := _prop(W + "decoration/nature/rock_single_%s.gltf" % rocks[_rng.randi() % rocks.size()],
					p.x, p.y, _rng.randf() * 360.0, _rng.randf_range(7.0, 14.0))
			_wash_over(rock)
			Interiors.collider_for(rock)
	for z in [100.0, 76.0]:
		_lamp(8.0 if z != 76.0 else -8.0, z)
	for z in [-34.0, -84.0, -110.0]:
		_lamp(9.0 if z != -84.0 else -9.0, z)
	for z in [108.0, 84.0, 62.0]:
		_prop(G + "post_skull.gltf", -12.0, z, 90.0, 1.6)
		_prop(G + "post_skull.gltf", 12.0, z + 6.0, 270.0, 1.6)
	# glowing cracks in the ground (the lava material, flat on the ground, no light)
	var cracks := 0
	tries = 0
	while cracks < 36 and tries < 600:
		tries += 1
		var p := Vector2(_rng.randf_range(BOUNDS.position.x + 8.0, BOUNDS.end.x - 8.0),
				_rng.randf_range(BOUNDS.position.y + 8.0, BOUNDS.end.y - 8.0))
		if (p - CAMP).length() < CAMP_RADIUS + 4.0 or absf(p.y - stream_z(p.x)) < STREAM_WIDTH * 0.5 + 3.0:
			continue
		if TEMPLE.grow(4.0).has_point(p) or _terrain.near_path(p, 5.0) or ENTRY.distance_to(p) < 12.0:
			continue
		cracks += 1
		var crack := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(_rng.randf_range(2.5, 7.0), 0.04, _rng.randf_range(0.18, 0.4))
		crack.mesh = mesh
		crack.material_override = _lava
		crack.position = wp(p.x, p.y, 0.1)
		crack.rotation.y = _rng.randf() * TAU
		crack.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_root.add_child(crack)


# -------------------------------------------------------------------- the camp ----

func _build_camp() -> void:
	for i in 6:                                   # six tents in a ring, doors toward the fire
		var a := TAU * float(i) / 6.0
		var p := CAMP + Vector2(cos(a), sin(a)) * 19.0
		var tent := _prop(W + "decoration/props/tent.gltf", p.x, p.y, rad_to_deg(atan2(CAMP.x - p.x, CAMP.y - p.y)), 10.0)
		Interiors.collider_for(tent)
	_fire(CAMP.x, CAMP.y, 3.2, 24.0, 3.0)         # the big fire in the middle
	for off in [Vector2(-10, -7), Vector2(10, -7), Vector2(-10, 10), Vector2(10, 10)]:
		_fire(CAMP.x + off.x, CAMP.y + off.y, 2.4, 9.0, 1.4)
	var P := W + "decoration/props/"
	_prop(P + "crate_A_big.gltf", 13.0, 27.0, 20.0, 7.0, 0.0, true)
	_prop(P + "barrel.gltf", 15.0, 29.0, 0.0, 7.0, 0.0, true)
	_prop(P + "sack.gltf", -13.0, 26.0, 40.0, 7.0)
	_prop(P + "weaponrack.gltf", 6.0, 43.0, 180.0, 7.0, 0.0, true)
	_prop(P + "wheelbarrow.gltf", -6.0, 43.0, 60.0, 7.0)
	_prop(P + "resource_stone.gltf", 11.0, 36.0, 0.0, 6.0, 0.0, true)       # Damianos' forge corner


# ------------------------------------------------------------------- the temple ----

func _stone_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Catacombs._brick_texture()
	m.albedo_color = Color(0.85, 0.62, 0.52)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * 0.25
	m.roughness = 0.95
	return m


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


## A round tower with a dark red cone roof.
func _tower(at: Vector2) -> void:
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 5.0
	cyl.bottom_radius = 5.4
	cyl.height = WALL_HEIGHT + 5.0
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
	roof_mat.albedo_color = Color(0.34, 0.08, 0.05)
	roof_mat.roughness = 0.9
	roof.material_override = roof_mat
	roof.position = wp(at.x, at.y, cyl.height + 3.0)
	_root.add_child(roof)


func _pillar(x: float, z: float) -> void:
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 1.5
	cyl.height = 9.0
	body.mesh = cyl
	body.material_override = _stone
	body.position = wp(x, z, 4.5)
	_root.add_child(body)
	var collider := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var shape_cyl := CylinderShape3D.new()
	shape_cyl.radius = 1.5
	shape_cyl.height = 9.0
	shape.shape = shape_cyl
	collider.add_child(shape)
	body.add_child(collider)


func _build_temple() -> void:
	var t := TEMPLE
	var half_gap := GATE_WIDTH / 2.0
	_wall(Vector2(t.position.x, t.end.y), Vector2(-half_gap, t.end.y))      # south wall, left of the gate
	_wall(Vector2(half_gap, t.end.y), Vector2(t.end.x, t.end.y))            # south wall, right of the gate
	_wall(Vector2(t.position.x, t.position.y), Vector2(t.end.x, t.position.y))   # north wall
	_wall(Vector2(t.position.x, t.position.y), Vector2(t.position.x, t.end.y))   # west wall
	_wall(Vector2(t.end.x, t.position.y), Vector2(t.end.x, t.end.y))             # east wall
	for corner in [t.position, Vector2(t.end.x, t.position.y), Vector2(t.position.x, t.end.y), t.end]:
		_tower(corner)
	_tower(Vector2(-half_gap - 5.8, t.end.y))                               # the two gate towers
	_tower(Vector2(half_gap + 5.8, t.end.y))
	# two rows of pillars with a brazier beside each
	for z in [-146.0, -162.0, -178.0]:
		for x in [-16.0, 16.0]:
			_pillar(x, z)
			var bx: float = x * 1.45
			_prop(I + "torch_lit.gltf.glb", bx, z, 0.0, 3.4)
			if z != -162.0:                                           # the middle pair burns without a light (frame rate at night)
				_fire_light(bx, z, 3.2, Color(1.0, 0.55, 0.22), 1.7, 15.0)
	_build_flame()
	# bones and skulls on the stones
	var bones := [G + "bone_A.gltf", G + "bone_B.gltf", G + "bone_C.gltf", G + "skull.gltf", G + "ribcage.gltf"]
	var yard := t.grow(-7.0)
	for i in 24:
		var p := Vector2(_rng.randf_range(yard.position.x, yard.end.x), _rng.randf_range(yard.position.y, yard.end.y))
		if absf(p.x) < 9.0 and p.y > -184.0:
			continue                                                  # keep the middle lane clear for the fight
		_prop(bones[_rng.randi() % bones.size()], p.x, p.y, _rng.randf() * 360.0, _rng.randf_range(1.2, 1.8))


## The Flame of the Keeper: a stone dais with a bowl and a tall flame that breathes.
func _build_flame() -> void:
	_box(wp(FLAME.x, FLAME.y, 0.4), Vector3(14.0, 0.8, 8.0), _stone, true)
	var bowl := MeshInstance3D.new()
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = 2.6
	bowl_mesh.bottom_radius = 1.6
	bowl_mesh.height = 1.4
	bowl.mesh = bowl_mesh
	bowl.material_override = _stone
	bowl.position = wp(FLAME.x, FLAME.y, 1.5)
	_root.add_child(bowl)
	var fire := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.7
	cone.height = 4.4
	fire.mesh = cone
	var fire_mat := StandardMaterial3D.new()
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire_mat.albedo_color = Color(1.0, 0.55, 0.12)
	fire.material_override = fire_mat
	fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fire.position = wp(FLAME.x, FLAME.y, 4.4)
	_root.add_child(fire)
	_fire_light(FLAME.x, FLAME.y + 3.0, 4.6, Color(1.0, 0.5, 0.15), 4.2, 34.0)


## The sealed temple gate: it dissolves when the quest "Τα Θραύσματα της Φλόγας" is ready.
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
	mat.albedo_color = Color(1.0, 0.35, 0.10, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.35, 0.10)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	barrier.material_override = mat
	barrier.position = body.position
	barrier.add_to_group("ash_gate")
	_gate.add_child(barrier)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.4, 0.15)
	light.light_energy = 2.0
	light.omni_range = 14.0
	light.position = wp(0.0, GATE_Z + 2.0, 4.0)
	_gate.add_child(light)
	var label := Label3D.new()
	label.text = Strings.PROMPT_TEMPLE_GATE
	label.font_size = 52
	label.pixel_size = 0.0085
	label.outline_size = 16
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.78, 0.55)
	label.no_depth_test = true
	label.position = wp(0.0, GATE_Z + 1.2, WALL_HEIGHT * 0.8)
	_gate.add_child(label)
	var spot := InteractSpot.make(Strings.PROMPT_TEMPLE_GATE, func(p: Player): p.message.emit(Strings.MSG_TEMPLE_SEALED), 5.0)
	spot.position = wp(0.0, GATE_Z + 3.0)
	_gate.add_child(spot)


func _on_quests_changed() -> void:
	if not _gate_open and Quests.state["a_shards"] >= Quests.S.READY:
		_open_gate()
	_check_bosses()


func _open_gate() -> void:
	_gate_open = true
	if is_instance_valid(_gate):
		var player := get_tree().get_first_node_in_group("player") as Player
		if player:
			player.message.emit(Strings.MSG_TEMPLE_OPEN)
		Sfx.ui("quest_ready")
		var g := _gate
		_gate = null
		for child in g.get_children():
			if child is StaticBody3D or child is InteractSpot:
				child.queue_free()
			if child.is_in_group("ash_gate"):
				child.remove_from_group("ash_gate")
		var tween := create_tween()
		tween.tween_interval(0.6)
		tween.tween_callback(g.queue_free)


func _build_embers() -> void:
	_embers = GPUParticles3D.new()
	_embers.name = "Embers"
	_embers.amount = 180
	_embers.lifetime = 3.5
	_embers.preprocess = 1.5
	_embers.randomness = 0.4
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(18.0, 4.0, 18.0)
	mat.direction = Vector3(0.15, 1.0, 0.05).normalized()
	mat.spread = 30.0
	mat.initial_velocity_min = 1.2
	mat.initial_velocity_max = 2.6
	mat.gravity = Vector3(0.0, 0.25, 0.0)
	mat.scale_min = 0.04
	mat.scale_max = 0.12
	mat.color = Color(1.0, 0.58, 0.15, 0.85)
	_embers.process_material = mat
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	draw_mat.albedo_color = Color(1.0, 0.55, 0.15, 0.9)
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = draw_mat
	_embers.draw_pass_1 = quad
	_embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(_embers)


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
	for s in SHARDS:
		var pos := wp(s.x, s.y)
		if SaveGame.collected_items.has("shard@" + SaveGame.key_for(pos)):
			continue
		var item := QuestItem.new()
		item.item_id = "shard"
		item.position = pos
		_root.add_child(item)
	for c in CRYSTALS:
		var pos := wp(c.x, c.y)
		if SaveGame.collected_items.has("crystal@" + SaveGame.key_for(pos)):
			continue
		var item := QuestItem.new()
		item.item_id = "crystal"
		item.position = pos
		_root.add_child(item)
	# the two people of the Shelter
	var theofilos := Npc.new()
	theofilos.npc_id = "theofilos"
	theofilos.rest_yaw = 0.8
	theofilos.position = wp(CAMP.x - 5.0, CAMP.y + 4.0, 0.05)
	_root.add_child(theofilos)
	var damianos := Npc.new()
	damianos.npc_id = "damianos"
	damianos.rest_yaw = -0.8
	damianos.position = wp(CAMP.x + 7.0, CAMP.y + 4.0, 0.05)
	_root.add_child(damianos)


func _spawn_creatures() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null:
		push_warning("ash_valley.gd: no enemy spawner")
		return
	for s in SPAWNS:
		var enemy: Enemy = spawner.spawn_extra(s[0], wp(s[1], s[2], 0.05))
		if enemy and s[0] in _boss_kinds():
			_bosses[s[0]] = enemy


func _boss_kinds() -> Array:
	return ["pyrforos", "ash_lord"]


## A boss that was killed before his quest began comes back when the quest is taken.
func _check_bosses() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null:
		return
	for s in SPAWNS:
		var kind: String = s[0]
		if not kind in _boss_kinds():
			continue
		var quest: String = spawner.KINDS[kind].get("quest", "")
		if quest == "" or Quests.state[quest] != Quests.S.ACTIVE:
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
