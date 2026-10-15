class_name ParkourMover
extends AnimatableBody3D
## Moving / bobbing obstacle platform for parkour obbies.
## Smoothly shifts along travel_offset, carrying the player seamlessly.

@export var travel_offset: Vector3 = Vector3(0.0, 0.0, 6.0)
@export var cycle_duration: float = 3.8
@export var phase_offset: float = 0.0
@export var platform_size: Vector3 = Vector3(3.2, 0.4, 3.2)
@export var neon_color: Color = Color(1.0, 0.5, 0.1)

var _origin: Vector3 = Vector3.ZERO
var _elapsed: float = 0.0


func _init() -> void:
	_elapsed = phase_offset
	_origin = position


func _ready() -> void:
	sync_to_physics = true
	_origin = global_position
	_build_platform()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var progress := sin(_elapsed * (TAU / maxf(cycle_duration, 0.5)))
	# Shift smoothly between -0.5 * offset and +0.5 * offset
	if is_inside_tree():
		global_position = _origin + travel_offset * (progress * 0.5)
	else:
		position = _origin + travel_offset * (progress * 0.5)


func _build_platform() -> void:
	# Main Platform Mesh
	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = platform_size
	mesh_inst.mesh = box_mesh
	mesh_inst.position.y = platform_size.y * 0.5

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.48, 0.32, 0.18) # rustic wood
	mat.roughness = 0.8
	mesh_inst.material_override = mat
	add_child(mesh_inst)

	# Glowing Neon Trim along edges
	var trim := MeshInstance3D.new()
	var trim_mesh := BoxMesh.new()
	trim_mesh.size = Vector3(platform_size.x * 1.02, 0.08, platform_size.z * 1.02)
	trim.mesh = trim_mesh
	trim.position.y = platform_size.y + 0.02

	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = neon_color
	trim_mat.emission_enabled = true
	trim_mat.emission = neon_color
	trim_mat.emission_energy_multiplier = 1.8
	trim.material_override = trim_mat
	add_child(trim)

	# Collision Shape
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = platform_size
	shape.shape = box_shape
	shape.position.y = platform_size.y * 0.5
	add_child(shape)
