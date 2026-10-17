class_name VillageDog
extends CharacterBody3D
## Mourgos the loyal Village Dog & Active Animal Companion.
## - Follows George outdoors across the island.
## - Detects hidden/buried chests and barks excitedly while pointing to them.
## - Assists in combat by biting and distracting enemies.
## - Learns and performs tricks (Sit, Paw Shake, Roll Over, Happy Leap) with affection progression.

signal companion_mode_changed(active: bool)
signal trick_performed(trick_name: String, affection: int)
signal treasure_scented(chest_pos: Vector3)

const REST_POS := Vector2(-12.0, 14.0)

var companion_name := "Μούργος"
var is_active_companion := false
var is_sitting := false
var affection_level := 1

var _model: Node3D
var _tail: Node3D
var _head: Node3D
var _ears: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _bark_label: Label3D
var _wag_intensity := 1.0
var _wag_timer := 0.0
var _bark_timer := 8.0 + randf() * 14.0
var _trot_timer := 5.0
var _target_pos := Vector3(-12.0, 0.0, 14.0)
var _anim_clock := 0.0

var _scent_timer := 0.0
var _attack_cooldown := 0.0
var _trick_clock := 0.0
var _current_trick := 0
var _target_enemy: Enemy = null

func _ready() -> void:
	name = "Mourgos"
	add_to_group("interactables")
	add_to_group("animals")
	add_to_group("companions")
	collision_layer = 16
	collision_mask = 1
	_build_mesh()
	_build_bark_label()
	_target_pos = global_position if is_inside_tree() else position


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


func _build_bark_label() -> void:
	_bark_label = Label3D.new()
	_bark_label.text = ""
	_bark_label.font_size = 28
	_bark_label.pixel_size = 0.0055
	_bark_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bark_label.modulate = Color(1.0, 0.9, 0.3)
	_bark_label.position.y = 1.3
	_bark_label.visible = false
	add_child(_bark_label)


# =========================================================================
# COMPANION CONTROLS & TRICKS
# =========================================================================
func set_companion(active: bool) -> void:
	is_active_companion = active
	is_sitting = false
	_wag_timer = 4.0
	if active:
		Sfx.play("dog_bark", global_position if is_inside_tree() else position)
		show_bark("Γαβ! Είμαι έτοιμος!")
	companion_mode_changed.emit(active)


func toggle_sitting() -> void:
	is_sitting = not is_sitting
	_wag_timer = 2.0
	if is_sitting:
		velocity = Vector3.ZERO
		show_bark("Περιμένω εδώ...")
	else:
		show_bark("Σηκώθηκα! Πάμε!")


func perform_next_trick(player: Player = null) -> void:
	var tricks := [
		{"name": "Κάτσε!", "bark": "Κάθομαι ήσυχα!"},
		{"name": "Δώσε ποδαράκι!", "bark": "🐾 Δίνω ποδαράκι!"},
		{"name": "Κάνε τούμπα!", "bark": "🌀 Χαρούμενη τούμπα!"},
		{"name": "Άλμα χαράς!", "bark": "✨ Άλμα στον αέρα!"}
	]
	var trick: Dictionary = tricks[_current_trick % tricks.size()]
	_current_trick += 1
	affection_level = mini(affection_level + 1, 10)
	_wag_timer = 6.0
	_trick_clock = 1.8

	Sfx.play("dog_whimper", global_position if is_inside_tree() else position)
	show_bark(trick["bark"])

	if player != null:
		if player.has_method("apply_pet_buff"):
			player.call("apply_pet_buff", 180.0)
		var msg := "Ο %s έκανε το κόλπο: '%s'! (Αγάπη: Lv.%d, +10%% Ταχύτητα)" % [companion_name, trick["name"], affection_level]
		var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree != null and tree.has_group("hud"):
			tree.call_group("hud", "show_banner", msg, 3.0)
		if player.has_signal("message"):
			player.emit_signal("message", msg)

	trick_performed.emit(trick["name"], affection_level)


func show_bark(text: String, duration: float = 3.0) -> void:
	if _bark_label == null:
		return
	_bark_label.text = text
	_bark_label.visible = true
	if is_inside_tree() and get_tree() != null:
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(_bark_label) and _bark_label.text == text:
				_bark_label.visible = false
		)


# =========================================================================
# MAIN AI PROCESS (FOLLOWING, SCENT TRACKING, COMBAT ASSIST)
# =========================================================================
func _physics_process(delta: float) -> void:
	_anim_clock += delta
	_wag_timer = maxf(_wag_timer - delta, 0.0)
	_scent_timer = maxf(_scent_timer - delta, 0.0)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_trick_clock = maxf(_trick_clock - delta, 0.0)

	var cur_wag := 14.0 if _wag_timer > 0.0 else 3.5
	if _tail != null:
		_tail.rotation.y = sin(_anim_clock * cur_wag) * (0.65 if _wag_timer > 0.0 else 0.25)
	if _head != null:
		_head.rotation.z = sin(_anim_clock * 1.5) * 0.08
		_head.rotation.x = sin(_anim_clock * 2.0) * 0.05

	if not is_inside_tree():
		return

	var player_node := get_tree().get_first_node_in_group("player") as Node3D

	# 1. Active Companion Logic
	if is_active_companion and player_node != null:
		var p_pos := player_node.global_position
		var my_pos := global_position
		var dist_to_player := my_pos.distance_to(p_pos)

		# Extreme distance teleport catch-up
		if dist_to_player > 50.0:
			global_position = p_pos + Vector3(1.5, 0.0, 1.5)
			velocity = Vector3.ZERO
			return

		if is_sitting or _trick_clock > 0.0:
			# Stay in sitting posture
			velocity = Vector3.ZERO
			if _model != null:
				_model.position.y = 0.0
			return

		# Scent detection for hidden chests
		if _scent_timer <= 0.0:
			_check_chest_scent(my_pos, player_node as Player)

		# Combat assist
		if _attack_cooldown <= 0.0:
			_check_combat_assist(my_pos)

		# Move toward target position
		if _target_enemy != null and is_instance_valid(_target_enemy) and not _target_enemy.is_dead():
			_target_pos = _target_enemy.global_position
		else:
			_target_enemy = null
			var p_rot: float = player_node.call("get_heading") if player_node.has_method("get_heading") else player_node.rotation.y
			var offset := Basis(Vector3.UP, p_rot) * Vector3(1.6, 0.0, 1.4)
			_target_pos = p_pos + offset

		var move_vec := _target_pos - my_pos
		move_vec.y = 0.0
		var dist := move_vec.length()

		if dist > 0.6:
			var dir := move_vec.normalized()
			var speed := 8.2 if dist > 12.0 else (5.6 if dist > 4.5 else 3.6)
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			var target_heading := atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_heading, 9.0 * delta)
			# Animate trot
			for i in _legs.size():
				var leg := _legs[i]
				var phase := 1.0 if (i % 2 == 0) else -1.0
				leg.rotation.x = sin(_anim_clock * (12.0 if speed > 5.0 else 8.0)) * 0.45 * phase
		else:
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
			for leg in _legs:
				leg.rotation.x = move_toward(leg.rotation.x, 0.0, 4.0 * delta)

			# If close to enemy, perform bite assist
			if _target_enemy != null and dist <= 1.8:
				_bite_enemy(_target_enemy)

	# 2. Village Roaming / Idle Mode (when not companion)
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
			velocity.x = dir.x * 1.8
			velocity.z = dir.z * 1.8
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
			for i in _legs.size():
				var leg := _legs[i]
				var phase := 1.0 if (i % 2 == 0) else -1.0
				leg.rotation.x = sin(_anim_clock * 8.0) * 0.35 * phase
		else:
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
			for leg in _legs:
				leg.rotation.x = move_toward(leg.rotation.x, 0.0, 4.0 * delta)

	if not is_on_floor():
		velocity.y -= 19.6 * delta
	move_and_slide()


func _check_chest_scent(my_pos: Vector3, player: Player = null, tree_ref: SceneTree = null) -> void:
	var tree: SceneTree = tree_ref if tree_ref != null else (get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree))
	if tree == null:
		return
	var chests: Array = tree.get_nodes_in_group("chests")
	if chests.is_empty() and tree.root != null:
		for n in tree.root.find_children("*", "", true, false):
			if n.is_in_group("chests") or "opened" in n:
				chests.append(n)
	for c in chests:
		var is_open: bool = bool(c.get("opened")) if ("opened" in c) else false
		if not is_open:
			var c_pos: Vector3 = c.global_position if c.is_inside_tree() else c.position
			var d := my_pos.distance_to(c_pos)
			if d < 15.0 and d > 2.0:
				_scent_timer = 24.0
				_wag_timer = 8.0
				Sfx.play("dog_bark", global_position if is_inside_tree() else position)
				show_bark("🐾 Γαβ! (Μυρίστηκα θησαυρό!)")
				var msg := "Ο %s γάβγισε! Μυρίστηκε κρυμμένο θησαυρό κοντά!" % companion_name
				if tree.has_group("hud"):
					tree.call_group("hud", "show_banner", msg, 3.0)
				if player != null and player.has_signal("message"):
					player.emit_signal("message", msg)
				treasure_scented.emit(c_pos)
				break


func _check_combat_assist(my_pos: Vector3) -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	var closest: Enemy = null
	var min_d := 9.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy != null and not enemy.is_dead():
			var d := my_pos.distance_to(enemy.global_position)
			if d < min_d:
				min_d = d
				closest = enemy
	if closest != null:
		_target_enemy = closest


func _bite_enemy(enemy: Enemy) -> void:
	_attack_cooldown = 3.5
	Sfx.play("dog_bark", global_position)
	show_bark("Γκρρρ! (Δάγκωμα!)", 1.8)
	var dmg := 12.0 + float(affection_level) * 1.5
	enemy.take_damage(dmg, global_position, 2.0)
	_target_enemy = null
	_wag_timer = 3.0


# =========================================================================
# INTERACTION
# =========================================================================
func interact_prompt() -> String:
	if not is_active_companion:
		return "[R] Ακολούθησέ με, %s! (Σύντροφος)" % companion_name
	elif is_sitting:
		return "[R] Σήκω και ακολούθησέ με, %s" % companion_name
	return "[R] Κάτσε εδώ και περίμενε, %s" % companion_name


func interact_range() -> float:
	return 3.2


func interact(player: Player) -> void:
	if not is_active_companion:
		set_companion(true)
		if player != null:
			player.message.emit("Ο %s είναι πλέον ο πιστός σου σύντροφος!" % companion_name)
	else:
		# Toggle sit / follow or perform trick
		if Input.is_action_pressed("jump") or Input.is_action_pressed("block"):
			toggle_sitting()
		else:
			perform_next_trick(player)
