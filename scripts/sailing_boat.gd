class_name SailingBoat
extends CharacterBody3D
## Interactive Fishing Skiff / Sailing Boat for South Sea coastal exploration.
## Allows George to board at the 22m fishing pier, sail around the 7 sea stacks,
## reach the shipwreck and explore the coastal cliffs and underwater sea caves.

signal boarded(player: Player)
signal disembarked

const MAX_SPEED := 9.0
const SPRINT_SPEED := 14.5
const ACCEL := 4.5
const DECEL := 3.0
const TURN_SPEED := 1.8
const WATER_Y := -0.15

var is_sailing := false
var current_player: Player = null

var _speed := 0.0
var _yaw := 0.0
var _boat_root: Node3D
var _lantern_light: OmniLight3D
var _hull_mesh: MeshInstance3D
var _rudder: Node3D
var _sail_mesh: MeshInstance3D

func _ready() -> void:
	name = "SailingSkiff"
	add_to_group("interactables")
	add_to_group("boats")
	_build_boat_mesh()
	_yaw = rotation.y


func _build_boat_mesh() -> void:
	_boat_root = Node3D.new()
	_boat_root.name = "BoatVisual"
	add_child(_boat_root)

	var wood_hull := StandardMaterial3D.new()
	wood_hull.albedo_color = Color(0.38, 0.24, 0.12) # oak planks
	wood_hull.roughness = 0.85

	var wood_deck := StandardMaterial3D.new()
	wood_deck.albedo_color = Color(0.55, 0.40, 0.25) # pine decking
	wood_deck.roughness = 0.75

	var white_sail := StandardMaterial3D.new()
	white_sail.albedo_color = Color(0.92, 0.90, 0.82)
	white_sail.cull_mode = BaseMaterial3D.CULL_DISABLED
	white_sail.roughness = 0.9

	# 1. Main Keel & Hull Box
	var hull := MeshInstance3D.new()
	var h_box := BoxMesh.new()
	h_box.size = Vector3(2.2, 0.75, 5.2)
	hull.mesh = h_box
	hull.position = Vector3(0.0, 0.35, 0.0)
	hull.material_override = wood_hull
	_boat_root.add_child(hull)
	_hull_mesh = hull

	# 2. Pointed Bow (front triangle)
	var bow := MeshInstance3D.new()
	var b_prism := PrismMesh.new()
	b_prism.size = Vector3(2.2, 0.75, 1.8)
	bow.mesh = b_prism
	bow.position = Vector3(0.0, 0.35, -3.1)
	bow.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	bow.material_override = wood_hull
	_boat_root.add_child(bow)

	# 3. Inner Cockpit / Deck floor
	var deck := MeshInstance3D.new()
	var d_box := BoxMesh.new()
	d_box.size = Vector3(1.8, 0.15, 4.4)
	deck.mesh = d_box
	deck.position = Vector3(0.0, 0.45, -0.4)
	deck.material_override = wood_deck
	_boat_root.add_child(deck)

	# 4. Wooden Benches (thwarts)
	for z_pos: float in [-1.4, 0.3, 1.8]:
		var bench := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.85, 0.12, 0.45)
		bench.mesh = bm
		bench.position = Vector3(0.0, 0.65, z_pos)
		bench.material_override = wood_hull
		_boat_root.add_child(bench)

	# 5. Mast & Sail
	var mast := MeshInstance3D.new()
	var mc := CylinderMesh.new()
	mc.top_radius = 0.08
	mc.bottom_radius = 0.12
	mc.height = 4.8
	mast.mesh = mc
	mast.position = Vector3(0.0, 2.7, -1.2)
	mast.material_override = wood_hull
	_boat_root.add_child(mast)

	# Sail Yardarm
	var yard := MeshInstance3D.new()
	var yc := CylinderMesh.new()
	yc.top_radius = 0.05
	yc.bottom_radius = 0.05
	yc.height = 2.6
	yard.mesh = yc
	yard.position = Vector3(0.0, 4.5, -1.2)
	yard.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	yard.material_override = wood_hull
	_boat_root.add_child(yard)

	# Cloth Sail
	var sail := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.4, 3.2)
	sail.mesh = qm
	sail.position = Vector3(0.0, 2.9, -1.15)
	sail.material_override = white_sail
	_boat_root.add_child(sail)
	_sail_mesh = sail

	# 6. Bow Maritime Lantern
	_lantern_light = OmniLight3D.new()
	_lantern_light.light_color = Color(1.0, 0.78, 0.45)
	_lantern_light.light_energy = 1.8
	_lantern_light.omni_range = 8.0
	_lantern_light.position = Vector3(0.0, 0.9, -3.8)
	_boat_root.add_child(_lantern_light)

	# 7. Collision Shape
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(2.4, 1.2, 6.2)
	col.shape = cbox
	col.position = Vector3(0.0, 0.5, -0.6)
	add_child(col)


func interact_prompt() -> String:
	if is_sailing:
		return "[R] Αποβίβαση στην Ακτή"
	return "[R] Σαλπάρισμα με τη Βάρκα"


func interact_range() -> float:
	return 4.2


func interact(player: Player) -> void:
	if is_sailing:
		disembark()
	else:
		board(player)


func board(player: Player) -> void:
	if is_sailing or player == null or player.is_dead or player.busy:
		return
	if player.mounted:
		player.dismount()
	is_sailing = true
	current_player = player
	player.busy = true
	if is_inside_tree() and player.is_inside_tree():
		player.global_position = global_position + Vector3(0.0, 0.7, 1.2)
		Sfx.play("door_open", global_position)
	else:
		player.position = position + Vector3(0.0, 0.7, 1.2)
	player.velocity = Vector3.ZERO
	player._play("Sit_Chair_Idle", 0.2)
	player.message.emit("Σαλπάρισες! [W/S] Πρόωση, [A/D] Πηδάλιο, [Shift] Άνοιγμα Πανιού, [R] Αποβίβαση.")
	boarded.emit(player)


func disembark() -> void:
	if not is_sailing or current_player == null:
		return
	var p := current_player
	is_sailing = false
	current_player = null
	p.busy = false
	_speed = 0.0

	# Step off beside the boat onto nearest dry land / dock or water surface
	var exit_pos: Vector3
	if is_inside_tree():
		exit_pos = global_position + Basis(Vector3.UP, _yaw) * Vector3(2.4, 0.5, 0.0)
		p.global_position = exit_pos
		Sfx.play("land", exit_pos)
	else:
		exit_pos = position + Basis(Vector3.UP, _yaw) * Vector3(2.4, 0.5, 0.0)
		p.position = exit_pos
	p.velocity = Vector3.ZERO
	p._play("Idle", 0.2)
	p.message.emit("Αποβιβάστηκες από τη βάρκα.")
	disembarked.emit()


func _physics_process(delta: float) -> void:
	# Gentle wave bobbing & rocking motion
	var time_ms := float(Time.get_ticks_msec())
	var wave_bob := sin(time_ms / 500.0) * 0.06
	var wave_roll := cos(time_ms / 650.0) * 0.03
	var wave_pitch := sin(time_ms / 800.0) * 0.025

	if _boat_root != null:
		_boat_root.position.y = wave_bob
		_boat_root.rotation.z = wave_roll
		_boat_root.rotation.x = wave_pitch

	if not is_sailing:
		if is_inside_tree():
			global_position.y = WATER_Y
		else:
			position.y = WATER_Y
		velocity = Vector3.ZERO
		return

	# Handle Sailing Inputs
	var throttle := Input.get_axis("move_back", "move_forward")
	var steer := -Input.get_axis("strafe_left", "strafe_right")
	if steer == 0.0:
		steer = -Input.get_axis("turn_left", "turn_right")

	var is_sprint := Input.is_action_pressed("run")
	var target_max := SPRINT_SPEED if is_sprint else MAX_SPEED
	var target_speed := throttle * target_max

	if throttle != 0.0:
		_speed = move_toward(_speed, target_speed, ACCEL * delta)
	else:
		_speed = move_toward(_speed, 0.0, DECEL * delta)

	# Steer boat
	if absf(_speed) > 0.2:
		var steer_mult := 1.0 if _speed >= 0.0 else -0.8
		_yaw += steer * TURN_SPEED * steer_mult * delta
		rotation.y = _yaw

	# Forward velocity along boat heading (-Z in local space)
	var forward := -Basis(Vector3.UP, _yaw).z
	velocity = forward * _speed
	velocity.y = 0.0

	if is_inside_tree():
		global_position.y = WATER_Y
		move_and_slide()
		global_position.x = clampf(global_position.x, -165.0, 58.0)
		global_position.z = clampf(global_position.z, 108.0, 480.0)
		if current_player != null and current_player.is_inside_tree():
			current_player.global_position = global_position + Basis(Vector3.UP, _yaw) * Vector3(0.0, 0.72 + wave_bob, 1.2)
			current_player.rotation.y = _yaw
			if Input.is_action_just_pressed("interact"):
				disembark()
	else:
		position.y = WATER_Y
		position += forward * _speed * delta
