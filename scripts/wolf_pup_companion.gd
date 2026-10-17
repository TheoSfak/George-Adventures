class_name WolfPupCompanion
extends CharacterBody3D
## The Rescued Silver Wolf Pup ("Ασημένιος Λυκίσκος") wilderness pet companion.
## Found trapped in briars in the Golden Grove.
## Once rescued by George, becomes an active wilderness companion with keen
## scent tracking (18m chest detection), fierce bite attacks (16 dmg), and wild tricks.

signal rescued
signal companion_toggled(active: bool)
signal trick_done(trick_name: String)
signal treasure_scented(chest_pos: Vector3)

var companion_name := "Ασημένιος Λυκίσκος"
var is_trapped := true
var is_active_companion := false
var is_sitting := false
var affection_level := 1

var _model: Node3D
var _bark_label: Label3D
var _anim_clock := 0.0
var _scent_timer := 0.0
var _attack_cooldown := 0.0
var _target_pos := Vector3.ZERO
var _target_enemy: Enemy = null
var _current_trick := 0

func _ready() -> void:
	name = "WolfPup"
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
	_model.name = "PupModel"
	add_child(_model)

	var silver_mat := StandardMaterial3D.new()
	silver_mat.albedo_color = Color(0.70, 0.72, 0.75) # silver grey fur
	silver_mat.roughness = 0.85

	var dark_slate := StandardMaterial3D.new()
	dark_slate.albedo_color = Color(0.35, 0.38, 0.42)
	dark_slate.roughness = 0.8

	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.3, 0.85, 1.0) # sparkling cyan
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.2, 0.8, 1.0)
	eye_mat.emission_energy_multiplier = 1.5

	# 1. Pup Torso
	var body := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(0.36, 0.38, 0.65)
	body.mesh = b_box
	body.position = Vector3(0.0, 0.35, 0.0)
	body.material_override = silver_mat
	_model.add_child(body)

	# 2. Pup Head & Snout
	var head := MeshInstance3D.new()
	var h_box := BoxMesh.new()
	h_box.size = Vector3(0.30, 0.28, 0.30)
	head.mesh = h_box
	head.position = Vector3(0.0, 0.50, 0.32)
	head.material_override = silver_mat
	_model.add_child(head)

	var snout := MeshInstance3D.new()
	var s_box := BoxMesh.new()
	s_box.size = Vector3(0.18, 0.14, 0.22)
	snout.mesh = s_box
	snout.position = Vector3(0.0, 0.44, 0.52)
	snout.material_override = dark_slate
	_model.add_child(snout)

	# 3. Pointy Wolf Ears
	for s in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var p := PrismMesh.new()
		p.size = Vector3(0.12, 0.22, 0.10)
		ear.mesh = p
		ear.position = Vector3(s * 0.12, 0.70, 0.30)
		ear.material_override = dark_slate
		_model.add_child(ear)

	# 4. Fluffy Tail
	var tail := MeshInstance3D.new()
	var t_cyl := CylinderMesh.new()
	t_cyl.top_radius = 0.05
	t_cyl.bottom_radius = 0.10
	t_cyl.height = 0.38
	tail.mesh = t_cyl
	tail.position = Vector3(0.0, 0.45, -0.38)
	tail.rotation_degrees.x = -45.0
	tail.material_override = dark_slate
	_model.add_child(tail)

	# 5. Collision Shape
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(0.6, 0.7, 0.9)
	col.shape = cs
	col.position = Vector3(0.0, 0.35, 0.0)
	add_child(col)


func _build_bark_label() -> void:
	_bark_label = Label3D.new()
	_bark_label.text = ""
	_bark_label.font_size = 28
	_bark_label.pixel_size = 0.0055
	_bark_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bark_label.modulate = Color(0.4, 0.9, 1.0)
	_bark_label.position.y = 1.2
	_bark_label.visible = false
	add_child(_bark_label)


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


func rescue(player: Player = null) -> void:
	if not is_trapped:
		return
	is_trapped = false
	is_active_companion = true
	Sfx.play("wolf_howl", global_position if is_inside_tree() else position)
	show_bark("Αούουου! Ελεύθερος!")
	if player != null:
		var msg := "Απελευθέρωσες τον Ασημένιο Λυκίσκο! Τώρα είναι ο άγριος σύντροφός σου!"
		var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree != null and tree.has_group("hud"):
			tree.call_group("hud", "show_banner", msg, 3.5)
		if player.has_signal("message"):
			player.emit_signal("message", msg)
		if player.has_method("apply_pet_buff"):
			player.call("apply_pet_buff", 240.0)
	rescued.emit()


func perform_wild_trick(player: Player = null) -> void:
	var tricks := [
		{"name": "Ούρλιαξε στη σελήνη!", "bark": "🌕 Αούουουου!"},
		{"name": "Στάση κυνηγού!", "bark": "🐾 Ετοιμάζει ενέδρα!"},
		{"name": "Κυνήγησε την ουρά!", "bark": "🌀 Άγριο στριφογύρισμα!"},
		{"name": "Άγριο άλμα!", "bark": "⚡ Αστραπιαίο άλμα!"}
	]
	var trick: Dictionary = tricks[_current_trick % tricks.size()]
	_current_trick += 1
	affection_level = mini(affection_level + 1, 10)

	Sfx.play("wolf_howl", global_position if is_inside_tree() else position)
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

	trick_done.emit(trick["name"])


func _physics_process(delta: float) -> void:
	_anim_clock += delta
	_scent_timer = maxf(_scent_timer - delta, 0.0)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	if is_trapped or not is_inside_tree():
		return

	var player_node := get_tree().get_first_node_in_group("player") as Node3D
	if is_active_companion and player_node != null:
		var p_pos := player_node.global_position
		var my_pos := global_position
		var dist_to_player := my_pos.distance_to(p_pos)

		if dist_to_player > 50.0:
			global_position = p_pos + Vector3(-1.5, 0.0, 1.5)
			velocity = Vector3.ZERO
			return

		if is_sitting:
			velocity = Vector3.ZERO
			return

		# Keen wilderness scent detection (18m range)
		if _scent_timer <= 0.0:
			check_chest_scent(my_pos, get_tree(), player_node)

		# Fierce combat assist
		if _attack_cooldown <= 0.0:
			var closest: Enemy = null
			var min_d := 10.0
			for e in get_tree().get_nodes_in_group("enemies"):
				var enemy := e as Enemy
				if enemy != null and not enemy.is_dead():
					var d := my_pos.distance_to(enemy.global_position)
					if d < min_d:
						min_d = d
						closest = enemy
			if closest != null:
				_target_enemy = closest

		if _target_enemy != null and is_instance_valid(_target_enemy) and not _target_enemy.is_dead():
			_target_pos = _target_enemy.global_position
		else:
			_target_enemy = null
			var offset := Basis(Vector3.UP, player_node.rotation.y) * Vector3(-1.6, 0.0, 1.4)
			_target_pos = p_pos + offset

		var move_vec := _target_pos - my_pos
		move_vec.y = 0.0
		var dist := move_vec.length()

		if dist > 0.6:
			var dir := move_vec.normalized()
			var speed := 8.5 if dist > 12.0 else (6.0 if dist > 4.5 else 3.8)
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 9.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)

			if _target_enemy != null and dist <= 1.8:
				_attack_cooldown = 3.2
				Sfx.play("wolf_howl", global_position)
				show_bark("Δάγκωμα Λύκου!", 1.5)
				_target_enemy.take_damage(16.0 + float(affection_level) * 2.0, global_position, 2.5)
				_target_enemy = null

	if not is_on_floor():
		velocity.y -= 19.6 * delta
	move_and_slide()


func interact_prompt() -> String:
	if is_trapped:
		return "[R] Απελευθέρωση του Παγιδευμένου Λυκίσκου"
	elif not is_active_companion:
		return "[R] Ακολούθησέ με, %s! (Σύντροφος)" % companion_name
	elif is_sitting:
		return "[R] Σήκω και ακολούθησέ με, %s" % companion_name
	return "[R] Κάτσε εδώ και περίμενε, %s" % companion_name


func interact_range() -> float:
	return 3.2


func interact(player: Player) -> void:
	if is_trapped:
		rescue(player)
	elif not is_active_companion:
		is_active_companion = true
		is_sitting = false
		show_bark("Αούου! Είμαι μαζί σου!")
		if player != null:
			var msg := "Ο %s σε ακολουθεί ως πιστός άγριος σύντροφος!" % companion_name
			var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			if tree != null and tree.has_group("hud"):
				tree.call_group("hud", "show_banner", msg, 3.0)
			if player.has_signal("message"):
				player.emit_signal("message", msg)
		companion_toggled.emit(true)
	else:
		if Input.is_action_pressed("jump") or Input.is_action_pressed("block"):
			is_sitting = not is_sitting
			show_bark("Περιμένω εδώ..." if is_sitting else "Σηκώθηκα! Πάμε!")
		else:
			perform_wild_trick(player)


func check_chest_scent(my_pos: Vector3, tree_ref: SceneTree = null, player_node: Node3D = null) -> void:
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
			if d < 18.0 and d > 2.0:
				_scent_timer = 22.0
				Sfx.play("wolf_howl", global_position if is_inside_tree() else position)
				show_bark("🐺 Αούου! (Άγριο ένστικτο: Θησαυρός κοντά!)")
				var msg := "Ο %s μύρισε κρυμμένο θησαυρό σε απόσταση %d μέτρων!" % [companion_name, int(d)]
				if tree.has_group("hud"):
					tree.call_group("hud", "show_banner", msg, 3.0)
				if player_node != null and player_node.has_signal("message"):
					player_node.emit_signal("message", msg)
				treasure_scented.emit(c_pos)
				break
