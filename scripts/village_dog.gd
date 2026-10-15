class_name VillageDog
extends CharacterBody3D
## The friendly village dog ("Μούργος"): hangs out around the tavern and village square,
## greets George with a happy bark and tail wags, can be petted for a speed buff, and trots
## around the square during the day.

const REST_POS := Vector2(-12.0, 14.0)

var _model: Node3D
var _tail: Node3D
var _head: Node3D
var _ears: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _wag_intensity := 1.0
var _wag_timer := 0.0
var _bark_timer := 8.0 + randf() * 14.0
var _trot_timer := 5.0
var _target_pos := Vector3(-12.0, 0.0, 14.0)
var _follow_time := 0.0
var _anim_clock := 0.0


func _ready() -> void:
	name = "Mourgos"
	add_to_group("interactables")
	add_to_group("animals")
	collision_layer = 16
	collision_mask = 1
	_build_mesh()
	_target_pos = global_position


func _build_mesh() -> void:
	_model = Node3D.new()
	_model.name = "DogModel"
	add_child(_model)

	var fur_mat := StandardMaterial3D.new()
	fur_mat.albedo_color = Color(0.78, 0.52, 0.26)    # warm golden coat
	fur_mat.roughness = 0.85

	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.48, 0.31, 0.15)   # floppy ear / spot color
	dark_mat.roughness = 0.85

	var nose_mat := StandardMaterial3D.new()
	nose_mat.albedo_color = Color(0.08, 0.08, 0.08)
	nose_mat.roughness = 0.3

	var collar_mat := StandardMaterial3D.new()
	collar_mat.albedo_color = Color(0.85, 0.15, 0.15)  # red collar

	var tag_mat := StandardMaterial3D.new()
	tag_mat.albedo_color = Color(1.0, 0.82, 0.20)     # gold tag
	tag_mat.metallic = 0.8
	tag_mat.roughness = 0.3

	# Body
	var body := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(0.42, 0.44, 0.75)
	body.mesh = body_box
	body.material_override = fur_mat
	body.position = Vector3(0.0, 0.42, 0.0)
	_model.add_child(body)

	# Collar
	var collar := MeshInstance3D.new()
	var collar_box := BoxMesh.new()
	collar_box.size = Vector3(0.36, 0.08, 0.36)
	collar.mesh = collar_box
	collar.material_override = collar_mat
	collar.position = Vector3(0.0, 0.52, 0.34)
	_model.add_child(collar)

	var tag := MeshInstance3D.new()
	var tag_box := BoxMesh.new()
	tag_box.size = Vector3(0.08, 0.08, 0.04)
	tag.mesh = tag_box
	tag.material_override = tag_mat
	tag.position = Vector3(0.0, 0.46, 0.53)
	_model.add_child(tag)

	# Head pivot (for nodding and tilting)
	_head = Node3D.new()
	_head.position = Vector3(0.0, 0.58, 0.38)
	_model.add_child(_head)

	var head_mesh := MeshInstance3D.new()
	var head_box := BoxMesh.new()
	head_box.size = Vector3(0.34, 0.32, 0.34)
	head_mesh.mesh = head_box
	head_mesh.material_override = fur_mat
	_head.add_child(head_mesh)

	# Snout & Nose
	var snout := MeshInstance3D.new()
	var snout_box := BoxMesh.new()
	snout_box.size = Vector3(0.22, 0.16, 0.24)
	snout.mesh = snout_box
	snout.material_override = fur_mat
	snout.position = Vector3(0.0, -0.06, 0.24)
	_head.add_child(snout)

	var nose := MeshInstance3D.new()
	var nose_box := BoxMesh.new()
	nose_box.size = Vector3(0.09, 0.07, 0.07)
	nose.mesh = nose_box
	nose.material_override = nose_mat
	nose.position = Vector3(0.0, -0.01, 0.36)
	_head.add_child(nose)

	# Floppy Ears
	for side in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var ear_box := BoxMesh.new()
		ear_box.size = Vector3(0.08, 0.24, 0.14)
		ear.mesh = ear_box
		ear.material_override = dark_mat
		ear.position = Vector3(side * 0.19, 0.02, -0.02)
		ear.rotation.z = side * 0.22
		_head.add_child(ear)
		_ears.append(ear)

	# Tail pivot
	_tail = Node3D.new()
	_tail.position = Vector3(0.0, 0.54, -0.37)
	_model.add_child(_tail)

	var tail_mesh := MeshInstance3D.new()
	var tail_box := BoxMesh.new()
	tail_box.size = Vector3(0.1, 0.12, 0.32)
	tail_mesh.mesh = tail_box
	tail_mesh.material_override = dark_mat
	tail_mesh.position = Vector3(0.0, 0.06, -0.14)
	tail_mesh.rotation.x = -0.35
	_tail.add_child(tail_mesh)

	# 4 Legs
	for side in [-1.0, 1.0]:
		for fb in [-0.24, 0.24]:
			var leg := MeshInstance3D.new()
			var leg_box := BoxMesh.new()
			leg_box.size = Vector3(0.12, 0.32, 0.12)
			leg.mesh = leg_box
			leg.material_override = fur_mat
			leg.position = Vector3(side * 0.16, 0.16, fb)
			_model.add_child(leg)
			_legs.append(leg)

	# Collider for interactions
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(0.7, 0.8, 1.0)
	col.shape = box_shape
	col.position = Vector3(0.0, 0.4, 0.0)
	add_child(col)


func _physics_process(delta: float) -> void:
	_anim_clock += delta
	_wag_timer = maxf(_wag_timer - delta, 0.0)
	_follow_time = maxf(_follow_time - delta, 0.0)

	var cur_wag := 12.0 if _wag_timer > 0.0 else 3.5
	_tail.rotation.y = sin(_anim_clock * cur_wag) * (0.6 if _wag_timer > 0.0 else 0.25)
	_head.rotation.z = sin(_anim_clock * 1.5) * 0.08
	_head.rotation.x = sin(_anim_clock * 2.0) * 0.05

	# Bark timer
	_bark_timer -= delta
	if _bark_timer <= 0.0:
		_bark_timer = 20.0 + randf() * 30.0
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player != null and global_position.distance_to(player.global_position) < 22.0:
			Sfx.play("dog_bark", global_position, -3.0)

	# Movement logic
	var player_node := get_tree().get_first_node_in_group("player") as Node3D
	if _follow_time > 0.0 and player_node != null:
		var to_player := player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 3.0:
			_target_pos = player_node.global_position - to_player.normalized() * 2.2
	else:
		_trot_timer -= delta
		if _trot_timer <= 0.0:
			_trot_timer = 6.0 + randf() * 10.0
			var offset := Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
			_target_pos = Vector3(REST_POS.x + offset.x, 0.0, REST_POS.y + offset.y)

	var move_vec := _target_pos - global_position
	move_vec.y = 0.0
	var dist := move_vec.length()

	if dist > 0.4:
		var dir := move_vec.normalized()
		var speed := 3.2 if _follow_time > 0.0 else 1.8
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		var target_heading := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_heading, 8.0 * delta)
		# Leg trot animation
		for i in _legs.size():
			var leg := _legs[i]
			var phase := 1.0 if (i % 2 == 0) else -1.0
			leg.rotation.x = sin(_anim_clock * 10.0) * 0.4 * phase
	else:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		for leg in _legs:
			leg.rotation.x = move_toward(leg.rotation.x, 0.0, 4.0 * delta)

	if not is_on_floor():
		velocity.y -= 19.6 * delta
	move_and_slide()


# ------------------------------------------------------------- interaction ----

func interact_prompt() -> String:
	return "Χάιδεψε τον Μούργο [E]"


func interact_range() -> float:
	return 2.8


func interact(player: Node) -> void:
	_wag_timer = 5.0
	_follow_time = 35.0
	Sfx.play("dog_whimper", global_position, -2.0)
	get_tree().create_timer(0.35).timeout.connect(func():
		Sfx.play("dog_bark", global_position, -2.0)
	)
	if player.has_method("apply_pet_buff"):
		player.call("apply_pet_buff", 120.0)
	get_tree().call_group("hud", "show_banner", "Ο Μούργος κουνάει χαρούμενος την ουρά του! (+10% ταχύτητα)", 3.0)
