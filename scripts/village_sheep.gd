class_name VillageSheep
extends CharacterBody3D
## Friendly pasture sheep that graze peacefully in the farm meadow, bob their heads,
## chew grass, bleat softly, and react happily when fed by the player.

var _model: Node3D
var _head: Node3D
var _jaw: Node3D
var _legs: Array[Node3D] = []
var _anim_clock := randf() * 10.0
var _graze_timer := 3.0 + randf() * 4.0
var _grazing := false
var _bleat_timer := 15.0 + randf() * 25.0
var _fed_timer := 0.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("animals")
	collision_layer = 16
	collision_mask = 1
	_build_mesh()


func _build_mesh() -> void:
	_model = Node3D.new()
	_model.name = "SheepModel"
	add_child(_model)

	var wool_mat := StandardMaterial3D.new()
	wool_mat.albedo_color = Color(0.94, 0.93, 0.88)   # creamy soft wool
	wool_mat.roughness = 0.95

	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.22, 0.20, 0.18)   # dark face and legs
	skin_mat.roughness = 0.85

	var pink_mat := StandardMaterial3D.new()
	pink_mat.albedo_color = Color(0.85, 0.65, 0.65)   # ear interior

	# Fluffy Body (multiple intersecting soft boxes for cloud-like wool volume)
	var body_main := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(0.55, 0.50, 0.80)
	body_main.mesh = b_box
	body_main.material_override = wool_mat
	body_main.position = Vector3(0.0, 0.45, 0.0)
	_model.add_child(body_main)

	var body_puff := MeshInstance3D.new()
	var p_box := BoxMesh.new()
	p_box.size = Vector3(0.62, 0.44, 0.65)
	body_puff.mesh = p_box
	body_puff.material_override = wool_mat
	body_puff.position = Vector3(0.0, 0.48, 0.0)
	_model.add_child(body_puff)

	# Tail puff
	var tail := MeshInstance3D.new()
	var t_box := BoxMesh.new()
	t_box.size = Vector3(0.12, 0.14, 0.12)
	tail.mesh = t_box
	tail.material_override = wool_mat
	tail.position = Vector3(0.0, 0.52, -0.42)
	_model.add_child(tail)

	# Head pivot (for grazing and head bobs)
	_head = Node3D.new()
	_head.position = Vector3(0.0, 0.56, 0.40)
	_model.add_child(_head)

	var head_wool := MeshInstance3D.new()
	var hw_box := BoxMesh.new()
	hw_box.size = Vector3(0.28, 0.26, 0.26)
	head_wool.mesh = hw_box
	head_wool.material_override = wool_mat
	head_wool.position = Vector3(0.0, 0.08, 0.0)
	_head.add_child(head_wool)

	var face := MeshInstance3D.new()
	var f_box := BoxMesh.new()
	f_box.size = Vector3(0.24, 0.22, 0.32)
	face.mesh = f_box
	face.material_override = skin_mat
	face.position = Vector3(0.0, -0.02, 0.16)
	_head.add_child(face)

	# Chewing Jaw
	_jaw = Node3D.new()
	_jaw.position = Vector3(0.0, -0.11, 0.22)
	_head.add_child(_jaw)

	var jaw_mesh := MeshInstance3D.new()
	var j_box := BoxMesh.new()
	j_box.size = Vector3(0.20, 0.08, 0.22)
	jaw_mesh.mesh = j_box
	jaw_mesh.material_override = skin_mat
	_jaw.add_child(jaw_mesh)

	# Ears
	for side in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var ear_box := BoxMesh.new()
		ear_box.size = Vector3(0.06, 0.18, 0.10)
		ear.mesh = ear_box
		ear.material_override = skin_mat
		ear.position = Vector3(side * 0.18, 0.04, -0.02)
		ear.rotation.z = side * 0.45
		ear.rotation.x = -0.15
		_head.add_child(ear)

	# 4 Dark Legs
	for side in [-1.0, 1.0]:
		for fb in [-0.25, 0.25]:
			var leg := MeshInstance3D.new()
			var leg_box := BoxMesh.new()
			leg_box.size = Vector3(0.10, 0.28, 0.10)
			leg.mesh = leg_box
			leg.material_override = skin_mat
			leg.position = Vector3(side * 0.20, 0.14, fb)
			_model.add_child(leg)
			_legs.append(leg)

	# Collider
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(0.7, 0.75, 0.95)
	col.shape = box_shape
	col.position = Vector3(0.0, 0.4, 0.0)
	add_child(col)


func _physics_process(delta: float) -> void:
	_anim_clock += delta
	_fed_timer = maxf(_fed_timer - delta, 0.0)

	# Periodic grazing cycles
	_graze_timer -= delta
	if _graze_timer <= 0.0:
		_grazing = not _grazing
		_graze_timer = randf_range(4.0, 9.0) if _grazing else randf_range(2.0, 5.0)

	var target_pitch: float = 0.55 if _grazing else 0.05
	_head.rotation.x = lerp_angle(_head.rotation.x, target_pitch + sin(_anim_clock * 1.5) * 0.04, 3.0 * delta)

	# Chewing motion
	var chew_speed := 9.0 if (_grazing or _fed_timer > 0.0) else 2.0
	_jaw.position.y = -0.11 + sin(_anim_clock * chew_speed) * 0.02
	_jaw.position.x = sin(_anim_clock * (chew_speed * 0.5)) * 0.015

	# Bleat timer
	_bleat_timer -= delta
	if _bleat_timer <= 0.0:
		_bleat_timer = 25.0 + randf() * 35.0
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player != null and global_position.distance_to(player.global_position) < 20.0:
			Sfx.play("sheep_baa", global_position, -3.0)

	if not is_on_floor():
		velocity.y -= 19.6 * delta
		move_and_slide()


# ------------------------------------------------------------- interaction ----

func interact_prompt() -> String:
	return "Τάισε το προβατάκι [E]"


func interact_range() -> float:
	return 2.6


func interact(_player: Node) -> void:
	_fed_timer = 6.0
	_grazing = true
	Sfx.play("sheep_baa", global_position, -2.0)
	get_tree().call_group("hud", "show_banner", "Το προβατάκι μασουλάει ευχαριστημένο!", 2.5)
