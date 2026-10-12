class_name Pickup
extends Node3D
## A loot item lying on the ground (gold or a health potion). It pops out of the
## enemy that dropped it, hovers and spins, and flies to George when he gets close.
## Create with Pickup.make("gold", 5) and add it to the scene.

const ITEMS := "res://assets/items/"
const COLLECT_RADIUS := 1.1
const MAGNET_RADIUS := 6.0
const LIFETIME := 90.0

var kind := "gold"
var amount := 1

var _visual: Node3D
var _velocity := Vector3.ZERO
var _ground_y := 0.0
var _landed := false
var _age := 0.0
var _collected := false
var _player: Player
var _fly_speed := 0.0


static func make(item_kind: String, item_amount: int) -> Pickup:
	var p := Pickup.new()
	p.kind = item_kind
	p.amount = item_amount
	return p


func _ready() -> void:
	add_to_group("pickups")
	_ground_y = global_position.y
	var angle := randf() * TAU
	_velocity = Vector3(cos(angle) * randf_range(1.5, 3.0), randf_range(4.5, 6.5), sin(angle) * randf_range(1.5, 3.0))
	_visual = Node3D.new()
	add_child(_visual)
	var model := (load(_model_path()) as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * _model_scale()
	_visual.add_child(model)
	_visual.rotation.y = randf() * TAU
	if _is_potion() or _is_junk():
		var glow := OmniLight3D.new()
		glow.light_color = _glow_color()
		glow.light_energy = 1.4 if _is_potion() else 0.9
		glow.omni_range = 3.5
		glow.position.y = 0.6
		_visual.add_child(glow)


const POTION_LOOK := {
	"potion": ["bottle_A_green.gltf.glb", Color(0.95, 0.25, 0.30)],
	"power_potion": ["bottle_C_brown.gltf.glb", Color(1.0, 0.62, 0.18)],
	"speed_potion": ["bottle_B_green.gltf.glb", Color(0.35, 0.78, 1.0)],
}


## junk id -> [model, scale]
const JUNK_MODELS := {
	"bone": ["res://assets/graveyard/bone_A.gltf", 2.2],
	"rust": ["res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf", 1.3],
	"charm": ["res://assets/items/coin.gltf.glb", 2.2],
}


func _is_potion() -> bool:
	return POTION_LOOK.has(kind)


func _is_junk() -> bool:
	return kind.begins_with("junk_")


func _glow_color() -> Color:
	if _is_junk():
		return ShopData.JUNK[kind.substr(5)]["color"]
	return POTION_LOOK[kind][1]


func _model_path() -> String:
	if _is_potion():
		return ITEMS + POTION_LOOK[kind][0]
	if _is_junk():
		return JUNK_MODELS[kind.substr(5)][0]
	if amount >= 8:
		return ITEMS + "coin_stack_medium.gltf.glb"
	if amount >= 4:
		return ITEMS + "coin_stack_small.gltf.glb"
	return ITEMS + "coin.gltf.glb"


func _model_scale() -> float:
	if _is_potion():
		return 1.5
	if _is_junk():
		return JUNK_MODELS[kind.substr(5)][1]
	if amount >= 8:
		return 0.9
	if amount >= 4:
		return 1.1
	return 1.8


func _physics_process(delta: float) -> void:
	if _collected:
		return
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	_visual.rotation.y += delta * 2.2

	if not _landed:
		_velocity.y -= 18.0 * delta
		global_position += _velocity * delta
		if global_position.y <= _ground_y and _velocity.y < 0.0:
			global_position.y = _ground_y
			_landed = true
		return

	_visual.position.y = 0.45 + sin(_age * 3.0) * 0.08
	if _age < 0.6:
		return  # let it settle before it can be grabbed
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	if _player == null or _player.is_dead:
		return
	var target := _player.global_position + Vector3.UP * 0.9
	var dist := global_position.distance_to(target)
	if dist < COLLECT_RADIUS:
		_collect()
	elif dist < MAGNET_RADIUS:
		_fly_speed = minf(_fly_speed + 40.0 * delta, 14.0)
		global_position = global_position.move_toward(target, _fly_speed * delta)
		_ground_y = global_position.y
	else:
		_fly_speed = 0.0


func _collect() -> void:
	_collected = true
	_player.collect(kind, amount)
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3.ZERO, 0.12)
	tween.tween_callback(queue_free)
