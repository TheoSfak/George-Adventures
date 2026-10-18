class_name Guard
extends CharacterBody3D
## A village guard of captain Βασίλης. During a night invasion guards stand near the well and
## fight the skeletons that come close (the invasion spawns them: 2, plus one for every quest
## of Βασίλης that George has finished). Skeletons only go for George, so guards cannot be
## hurt; they are a helping hand, not a second life bar.

const MODEL := "res://assets/characters/Knight.glb"
const SPEED := 5.0
const REACH := 2.3
const SIGHT := 22.0                  # how far from its post a guard notices a skeleton
const COOLDOWN := 1.35
const HIT_TIME := 0.45
const GRAVITY := 22.0
const CLEARANCE := 0.6               # NavGrid clearance class of a guard (capsule radius 0.45 + 0.2)
const ATTACKS: Array[String] = ["1H_Melee_Attack_Slice_Diagonal", "1H_Melee_Attack_Slice_Horizontal", "1H_Melee_Attack_Chop"]

var home := Vector3.ZERO
var damage := 10.0
var follow_player := false
var follow_slot := 0
var max_follow_dist: float = 48.0
var guard_name := ""

var _model_root: Node3D
var _anim: AnimationPlayer
var _target: Enemy
var _cooldown := 0.0
var _scan_cd := 0.0
var _celebrating := false
var _swing := -1.0                   # time since the swing started, -1 = not swinging
var _leaving := false
var _returning := false                 # true while moving back to home post

# anti-snag: a guard that pushes against a prop without getting anywhere sidesteps left or right
# until it is free (no navigation mesh in the village, same idea as Enemy._check_blocked)
var _blocked_time := 0.0             # trying to move but not getting anywhere
var _detour_time := 0.0              # sidestepping around an obstacle
var _detour_sign := 1.0              # +1 / -1 = which side
var _detour_count := 0               # sidesteps in a row without getting free (each one lasts longer)
var _free_time := 0.0                # moving freely
var _since_detour := 99.0           # seconds since the last sidestep began
var _wall_normal := Vector3.ZERO     # horizontal normal of the last obstacle that was hit
var _goal_dir := Vector3.ZERO        # the direction the guard wants to go (before sidestepping)
var _last_steer := Vector3.ZERO      # the direction of the current sidestep
var _detour_extra := 0.0             # seconds the sidestep was prolonged because the way to the goal stayed blocked
var _nav := NavFollower.new()        # the way around houses and trees (nav_grid.gd); the sidestep above stays the last resort


func _ready() -> void:
	add_to_group("guards")
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	_model_root = Node3D.new()
	add_child(_model_root)
	var model := (load(MODEL) as PackedScene).instantiate() as Node3D
	_model_root.add_child(model)
	for n in model.find_children("*", "Node3D", true, false):
		if n.name in CharacterProps.NODES:
			n.visible = n.name == "1H_Sword" or n.name == "Rectangle_Shield"
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim:
		for a in ["Idle", "Running_A"]:
			if _anim.has_animation(a):
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		_anim.play("Idle")
	var tag := Label3D.new()
	tag.text = guard_name if guard_name != "" else Strings.GUARD_NAME
	tag.font_size = 40
	tag.pixel_size = 0.0068
	tag.outline_size = 12
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.6, 0.85, 1.0)
	tag.position.y = 2.4
	tag.no_depth_test = true
	add_child(tag)
	_cooldown = randf_range(0.2, 0.8)
	# a puff of light when they arrive
	_model_root.scale = Vector3.ONE * 0.05
	create_tween().tween_property(_model_root, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The night is over: the guard walks off and fades.
func dismiss() -> void:
	if _leaving:
		return
	_leaving = true
	remove_from_group("guards")
	if is_inside_tree() and _model_root != null:
		var tween := create_tween()
		if tween != null:
			tween.tween_property(_model_root, "scale", Vector3.ONE * 0.05, 0.6)
			tween.tween_callback(queue_free)
			return
	queue_free()


## Fortress is liberated: the guard celebrates and gracefully fades after a victory stance.
func celebrate_and_dismiss() -> void:
	if _celebrating or _leaving:
		return
	_celebrating = true
	follow_player = false
	_target = null
	_returning = false
	velocity = Vector3.ZERO
	_nav.reset()

	var lbl := Label3D.new()
	lbl.text = "Ζήτω ο Γιώργος!"
	lbl.font_size = 36
	lbl.pixel_size = 0.007
	lbl.outline_size = 10
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1.0, 0.9, 0.3)
	lbl.position.y = 2.8
	lbl.no_depth_test = true
	add_child(lbl)

	if _anim != null and _anim.has_animation("Idle"):
		_anim.play("Idle")

	if is_inside_tree() and get_tree() != null:
		var timer := get_tree().create_timer(6.0)
		timer.timeout.connect(func():
			if is_instance_valid(self):
				dismiss()
		)
	else:
		dismiss()


func _physics_process(delta: float) -> void:
	if _leaving or _celebrating:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_scan_cd = maxf(_scan_cd - delta, 0.0)
	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		if _scan_cd <= 0.0:
			_target = _find_target()
			_scan_cd = 0.35 if _target == null else 0.08
	var wanted := Vector3.ZERO
	var anim := "Idle"
	if _swing >= 0.0:
		_swing += delta
		if _swing >= HIT_TIME and _swing - delta < HIT_TIME:
			_land_blow()
		if _swing >= 0.9:
			_swing = -1.0
	elif _target != null:
		_returning = false
		var to := _target.global_position - global_position
		to.y = 0.0
		if to.length() > REACH:
			wanted = _steer(_nav.direction(global_position, _target.global_position, CLEARANCE, delta)) * SPEED
			anim = "Running_A"
			_face(wanted if (_detour_time > 0.0 or _nav.active) else to, delta)
		else:
			_face(to, delta)
			if _cooldown <= 0.0:
				_start_swing()
	else:
		var target_pos := home
		if follow_player and is_inside_tree():
			var p := get_tree().get_first_node_in_group("player") as Node3D
			if p != null:
				var p_dist_home := (p.global_position - home).length() if home != Vector3.ZERO else 0.0
				if home != Vector3.ZERO and max_follow_dist > 0.0 and p_dist_home > max_follow_dist:
					# Player has moved outside the raid/fortress zone; guards hold ground at home
					target_pos = home
				else:
					var fwd := -p.global_transform.basis.z
					fwd.y = 0.0
					if fwd.length_squared() < 0.01:
						fwd = Vector3.FORWARD
					else:
						fwd = fwd.normalized()
					var right := Vector3(-fwd.z, 0.0, fwd.x)
					var offset := Vector3.ZERO
					match follow_slot % 3:
						0: offset = -right * 2.2 - fwd * 1.6
						1: offset = right * 2.2 - fwd * 1.6
						2: offset = -fwd * 3.2
					target_pos = p.global_position + offset
		var back := target_pos - global_position
		back.y = 0.0
		var dist := back.length()
		var start_thresh := 4.2 if follow_player else 2.2
		var stop_thresh := 2.0 if follow_player else 0.45

		if not _returning:
			if dist > start_thresh:
				_returning = true
		else:
			if dist <= stop_thresh:
				_returning = false
				_detour_time = 0.0
				_blocked_time = 0.0
				_nav.reset()
				velocity.x = 0.0
				velocity.z = 0.0

		if _returning:
			wanted = _steer(_nav.direction(global_position, target_pos, CLEARANCE, delta)) * SPEED * (1.1 if follow_player else 0.7)
			anim = "Running_A"
			_face(wanted if (_detour_time > 0.0 or _nav.active) else back, delta)
		else:
			wanted = Vector3.ZERO
			anim = "Idle"
			if not follow_player and home != Vector3.ZERO:
				_face(Vector3(home.x, 0.0, home.z).normalized(), delta)
	velocity.x = move_toward(velocity.x, wanted.x, (40.0 if wanted != Vector3.ZERO else 60.0) * delta)
	velocity.z = move_toward(velocity.z, wanted.z, (40.0 if wanted != Vector3.ZERO else 60.0) * delta)
	move_and_slide()
	_check_blocked(wanted, delta)
	if _swing < 0.0 and _anim != null and _anim.has_animation(anim) and _anim.current_animation != anim:
		_anim.play(anim, 0.15)


## While sidestepping the guard walks along the obstacle (the tangent of the wall it hit, to the left
## or to the right) instead of at the goal; without a known wall it turns the goal direction 85 degrees.
func _steer(dir: Vector3) -> Vector3:
	_goal_dir = dir
	if _detour_time <= 0.0:
		return dir
	if _wall_normal == Vector3.ZERO:
		return dir.rotated(Vector3.UP, deg_to_rad(85.0) * _detour_sign)
	var tangent := Vector3.UP.cross(_wall_normal) * _detour_sign
	_last_steer = (tangent + _wall_normal * 0.1).normalized()      # slightly away from the wall: pressing into it wedges the capsule on a corner
	return _last_steer


## Stuck = wants to go somewhere but makes less than a quarter of that speed toward it for 0.3 s
## (sliding along a wall does not count as progress). Then the guard sidesteps along the obstacle,
## longer each time it is still stuck afterwards and always to the same side (that side was free);
## if the sidestep itself is blocked it tries the other side.
func _check_blocked(wanted: Vector3, delta: float) -> void:
	if wanted.length_squared() < 0.01:
		_blocked_time = 0.0
		_detour_time = 0.0
		return
	_since_detour += delta
	if get_slide_collision_count() > 0:
		var n := get_slide_collision(0).get_normal()
		n.y = 0.0
		if n.length() > 0.1:
			n = n.normalized()
			if _detour_time > 0.0 and n.dot(_last_steer) < -0.6:
				# the sidestep ran head-on into another obstacle (a dead end): the other side, at once
				_detour_sign = -_detour_sign
				_detour_time = 1.5
				_blocked_time = 0.0
			else:
				_wall_normal = n
	var want := Vector2(wanted.x, wanted.z).length()
	var progress := 0.0
	if want > 0.01:
		var real := get_real_velocity()
		progress = (real.x * wanted.x + real.z * wanted.z) / want
	var stuck := want > 0.5 and progress < want * 0.25
	if _detour_time > 0.0:
		_detour_time -= delta
		if _detour_time <= 0.0 and _goal_dir != Vector3.ZERO and test_move(global_transform, _goal_dir * 0.9):
			# still no way straight to the goal: keep sidestepping until the path is free
			_detour_time = 0.25
			_detour_extra += 0.25
			if _detour_extra > 4.0:                  # a long way along this side: try the other one
				_detour_sign = -_detour_sign
				_detour_extra = 0.0
		elif _detour_time <= 0.0:
			_detour_extra = 0.0
		if stuck:
			_blocked_time += delta
			if _blocked_time > 0.3:                  # the sidestep is blocked too: the other side
				_detour_sign = -_detour_sign
				_detour_time = 1.0
				_blocked_time = 0.0
		else:
			_blocked_time = 0.0
		return
	if stuck:
		_free_time = 0.0
		_blocked_time += delta
		if _blocked_time > 0.3:
			if _detour_count == 0 and _since_detour > 3.0:
				var along := _goal_dir.dot(Vector3.UP.cross(_wall_normal))
				if absf(along) > 0.2:
					_detour_sign = 1.0 if along > 0.0 else -1.0       # the side the goal is on
				else:
					_detour_sign = -1.0 if randf() < 0.5 else 1.0
			_detour_time = minf(0.8 + 0.8 * float(_detour_count), 3.0)
			_detour_count += 1
			_since_detour = 0.0
			_blocked_time = 0.0
	else:
		_blocked_time = 0.0
		if want > 0.5 and progress > want * 0.6:
			_free_time += delta
			if _free_time > 0.6:
				_detour_count = 0                    # free again: forget this obstacle


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_dist := SIGHT
	var own_pos := global_position
	var max_range_bound := SIGHT + 14.0
	var max_range_sq := max_range_bound * max_range_bound
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.is_dead():
			continue
		var ep := enemy.global_position
		var dx := absf(ep.x - own_pos.x)
		var dz := absf(ep.z - own_pos.z)
		if dx > max_range_bound or dz > max_range_bound:
			continue
		var own_sq := dx * dx + dz * dz
		if own_sq > max_range_sq:
			continue
		var own := sqrt(own_sq)
		var d := Vector2(ep.x - home.x, ep.z - home.z).length()
		if d < best_dist + 8.0 and own < best_dist + 14.0 and own < best_dist * 2.0:
			if own < best_dist or best == null:
				best_dist = minf(own, best_dist)
				best = enemy
	return best


func _start_swing() -> void:
	_swing = 0.0
	_cooldown = COOLDOWN
	if _anim:
		var name: String = ATTACKS.pick_random()
		if _anim.has_animation(name):
			_anim.play(name, 0.08)
	Sfx.play("sword_swing", global_position, -6.0)


func _land_blow() -> void:
	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		return
	if global_position.distance_to(_target.global_position) <= REACH + 0.8:
		var george := get_tree().get_first_node_in_group("player") as Player
		var weight := LevelScaling.health_mult(george.level) if george != null else 1.0   # guards stay as useful as before
		_target.take_damage(damage * weight, global_position, 4.0)
		Sfx.play("sword_hit", _target.global_position, -4.0)


func _face(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	_model_root.rotation.y = lerp_angle(_model_root.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-10.0 * delta))
