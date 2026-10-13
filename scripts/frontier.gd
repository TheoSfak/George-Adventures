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

const G := "res://assets/graveyard/"
const I := "res://assets/items/"
const W := "res://assets/world/"
const C := "res://assets/characters/"

var exit_action := Callable()               # set by Interiors: leaves the Frontier

var _root: Node3D
var _rng := RandomNumberGenerator.new()


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
	await get_tree().physics_frame
	await get_tree().physics_frame


## Snow instead of meadow: the village ground shader with cold colours, a trampled camp,
## a dirt track up the pass and a cobbled road to the fortress.
func _build_ground() -> void:
	var terrain := Terrain.new()
	terrain.name = "Terrain"
	terrain.position = ORIGIN                  # its geometry is local, the shaders use world noise
	_root.add_child(terrain)
	terrain.setup(7731)
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
