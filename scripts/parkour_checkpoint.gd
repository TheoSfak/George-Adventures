class_name ParkourCheckpoint
extends Node3D
## Roblox-style Obby Checkpoint Pad.
## Illuminates in golden yellow until stepped on, then flashes into vivid neon green,
## plays a chime sound, and records the player's respawn location.

signal reached(index: int, pos: Vector3, heading: float)

@export var checkpoint_index: int = 1
@export var respawn_heading: float = 0.0

const COLOR_INACTIVE := Color(1.0, 0.82, 0.18)
const COLOR_ACTIVE := Color(0.2, 1.0, 0.38)

var active: bool = false
var _pad_mat: StandardMaterial3D
var _crystal: MeshInstance3D
var _crystal_mat: StandardMaterial3D
var _light: OmniLight3D


func _init() -> void:
	_pad_mat = StandardMaterial3D.new()
	_pad_mat.albedo_color = COLOR_INACTIVE
	_pad_mat.emission_enabled = true
	_pad_mat.emission = COLOR_INACTIVE
	_pad_mat.emission_energy_multiplier = 1.8
	_pad_mat.roughness = 0.25

	_crystal_mat = StandardMaterial3D.new()
	_crystal_mat.albedo_color = COLOR_INACTIVE
	_crystal_mat.emission_enabled = true
	_crystal_mat.emission = COLOR_INACTIVE
	_crystal_mat.emission_energy_multiplier = 2.4
	_crystal_mat.roughness = 0.15


func _ready() -> void:
	_build_visuals()
	_build_trigger()


func _process(delta: float) -> void:
	if _crystal != null:
		_crystal.rotation.y += delta * 1.8
		_crystal.position.y = 1.35 + sin(Time.get_ticks_msec() * 0.003) * 0.12


func _build_visuals() -> void:
	# Base plate
	var base := MeshInstance3D.new()
	var base_cyl := CylinderMesh.new()
	base_cyl.top_radius = 1.45
	base_cyl.bottom_radius = 1.55
	base_cyl.height = 0.15
	base.mesh = base_cyl
	base.position.y = 0.075
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.18, 0.20, 0.22)
	base_mat.roughness = 0.7
	base_mat.metallic = 0.4
	base.material_override = base_mat
	add_child(base)

	# Glowing Checkpoint Surface Pad
	var pad := MeshInstance3D.new()
	var pad_cyl := CylinderMesh.new()
	pad_cyl.top_radius = 1.25
	pad_cyl.bottom_radius = 1.30
	pad_cyl.height = 0.10
	pad.mesh = pad_cyl
	pad.position.y = 0.13
	pad.material_override = _pad_mat
	add_child(pad)

	# Floating Rotating Diamond Crystal
	_crystal = MeshInstance3D.new()
	var prism := BoxMesh.new()
	prism.size = Vector3(0.45, 0.75, 0.45)
	_crystal.mesh = prism
	_crystal.position.y = 1.35
	_crystal.rotation_degrees = Vector3(45.0, 0.0, 45.0)
	_crystal.material_override = _crystal_mat
	add_child(_crystal)

	# Beacon Light
	_light = OmniLight3D.new()
	_light.light_color = COLOR_INACTIVE
	_light.light_energy = 1.8
	_light.omni_range = 4.5
	_light.position.y = 0.6
	add_child(_light)

	# Solid Collision Base
	var static_body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 0.2, 2.8)
	col_shape.shape = box
	col_shape.position.y = 0.1
	static_body.add_child(col_shape)
	add_child(static_body)


func _build_trigger() -> void:
	var area := Area3D.new()
	area.collision_mask = 1 | 2
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.35
	cyl.height = 1.2
	shape.shape = cyl
	shape.position.y = 0.65
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)


func _on_body_entered(body: Node3D) -> void:
	if body is Player and not active:
		var p: Player = body
		if p.is_dead:
			return
		activate()


func activate() -> void:
	if active:
		return
	active = true
	if is_inside_tree():
		Sfx.play("checkpoint_chime", global_position, 3.5)

	# Flash into neon green
	if _pad_mat != null:
		_pad_mat.albedo_color = COLOR_ACTIVE
		_pad_mat.emission = COLOR_ACTIVE
	if _crystal_mat != null:
		_crystal_mat.albedo_color = COLOR_ACTIVE
		_crystal_mat.emission = COLOR_ACTIVE
	if _light != null:
		_light.light_color = COLOR_ACTIVE

	if is_inside_tree():
		if _light != null:
			var tw := create_tween()
			_light.light_energy = 5.0
			tw.tween_property(_light, "light_energy", 2.2, 0.6)

		if _crystal != null:
			var c_tw := create_tween()
			_crystal.scale = Vector3(1.6, 1.6, 1.6)
			c_tw.tween_property(_crystal, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var spawn_pos := (global_position if is_inside_tree() else position) + Vector3(0.0, 0.25, 0.0)
	reached.emit(checkpoint_index, spawn_pos, respawn_heading)


func reset_state() -> void:
	active = false
	if _pad_mat != null:
		_pad_mat.albedo_color = COLOR_INACTIVE
		_pad_mat.emission = COLOR_INACTIVE
	if _crystal_mat != null:
		_crystal_mat.albedo_color = COLOR_INACTIVE
		_crystal_mat.emission = COLOR_INACTIVE
	if _light != null:
		_light.light_color = COLOR_INACTIVE
		_light.light_energy = 1.8

