class_name Balloon
extends Node3D
## A hot-air balloon. Drifting ones glide slowly on an ellipse around `center` (local to the Great Tree
## area) with a gentle bob and turn; a moored one just stands where it is placed. The mesh comes from
## TreeMeshes.balloon (its origin is the bottom of the basket).

var center := Vector3.ZERO              # centre of the ellipse; y = height of the basket bottom
var radii := Vector2(40.0, 34.0)        # ellipse radii (x, z)
var angle := 0.0                        # where on the ellipse (radians)
var angular_speed := 0.024              # radians per second
var moored := false

var _t := 0.0


## Builds the mesh: `stripes` are the colours of the envelope stripes.
func setup(stripes: Array, seed_value: int) -> void:
	add_to_group("balloons")
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = TreeMeshes.balloon(stripes, seed_value)
	mi.material_override = TreeMeshes.material()
	add_child(mi)


func _ready() -> void:
	if not moored:
		_place()


func _process(delta: float) -> void:
	if moored:
		return
	_t += delta
	angle += angular_speed * delta
	_place()


func _place() -> void:
	position = center + Vector3(cos(angle) * radii.x, sin(_t * 0.35 + angle) * 1.4, sin(angle) * radii.y)
	rotation.y = -angle * 0.5 + sin(_t * 0.2) * 0.2
