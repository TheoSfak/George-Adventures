class_name JumpPad
extends Node3D
## Roblox-style bouncy jump pad / trampoline.
## Flings the player high into the air with a springy boing sound and bounce animation.

@export var launch_power: float = 20.0
@export var forward_kick: Vector3 = Vector3.ZERO
@export var pad_color: Color = Color(0.15, 0.9, 1.0)
@export var cooldown: float = 0.5

var _pad_mesh: MeshInstance3D
var _light: OmniLight3D
var _cooldown_timer: float = 0.0


func _ready() -> void:
	_build_visuals()
	_build_trigger()


func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta


func _build_visuals() -> void:
	# Base rim (dark iron / brushed steel)
	var base := MeshInstance3D.new()
	var base_cyl := CylinderMesh.new()
	base_cyl.top_radius = 1.15
	base_cyl.bottom_radius = 1.25
	base_cyl.height = 0.2
	base.mesh = base_cyl
	base.position.y = 0.1
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.2, 0.22, 0.26)
	base_mat.roughness = 0.6
	base_mat.metallic = 0.5
	base.material_override = base_mat
	add_child(base)

	# Spring / Bouncy Center Pad
	_pad_mesh = MeshInstance3D.new()
	var pad_cyl := CylinderMesh.new()
	pad_cyl.top_radius = 0.92
	pad_cyl.bottom_radius = 0.95
	pad_cyl.height = 0.14
	_pad_mesh.mesh = pad_cyl
	_pad_mesh.position.y = 0.18
	var pad_mat := StandardMaterial3D.new()
	pad_mat.albedo_color = pad_color
	pad_mat.emission_enabled = true
	pad_mat.emission = pad_color * 0.9
	pad_mat.emission_energy_multiplier = 1.6
	pad_mat.roughness = 0.2
	_pad_mesh.material_override = pad_mat
	add_child(_pad_mesh)

	# Glowing Chevron / Arrow mesh on top
	var arrow := MeshInstance3D.new()
	var prism := BoxMesh.new()
	prism.size = Vector3(0.5, 0.04, 0.5)
	arrow.mesh = prism
	arrow.position.y = 0.26
	arrow.rotation_degrees.y = 45.0
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color.WHITE
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color.WHITE
	arrow_mat.emission_energy_multiplier = 2.0
	arrow.material_override = arrow_mat
	add_child(arrow)

	# Glowing beacon light
	_light = OmniLight3D.new()
	_light.light_color = pad_color
	_light.light_energy = 1.5
	_light.omni_range = 4.0
	_light.position.y = 0.5
	add_child(_light)

	# Solid base collider so players can land or stand on the pad frame
	var static_body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 0.2, 2.2)
	col_shape.shape = box
	col_shape.position.y = 0.1
	static_body.add_child(col_shape)
	add_child(static_body)


func _build_trigger() -> void:
	var area := Area3D.new()
	area.collision_mask = 1 | 2
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.05
	cyl.height = 0.7
	shape.shape = cyl
	shape.position.y = 0.45
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)


func _on_body_entered(body: Node3D) -> void:
	if _cooldown_timer > 0.0:
		return
	if body is Player:
		var p: Player = body
		if p.is_dead:
			return
		_cooldown_timer = cooldown
		Sfx.play("jump_pad_boing", global_position, 3.0)

		# Squash and stretch animation
		var tw := create_tween()
		tw.tween_property(_pad_mesh, "scale", Vector3(1.25, 0.35, 1.25), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_pad_mesh, "scale", Vector3(0.85, 1.45, 0.85), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_pad_mesh, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

		# Flash light
		var l_tw := create_tween()
		_light.light_energy = 4.0
		l_tw.tween_property(_light, "light_energy", 1.5, 0.4)

		# Launch player
		p.launch_up(launch_power, forward_kick)
