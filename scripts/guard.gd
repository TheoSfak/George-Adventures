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
const ATTACKS: Array[String] = ["1H_Melee_Attack_Slice_Diagonal", "1H_Melee_Attack_Slice_Horizontal", "1H_Melee_Attack_Chop"]

var home := Vector3.ZERO
var damage := 10.0

var _model_root: Node3D
var _anim: AnimationPlayer
var _target: Enemy
var _cooldown := 0.0
var _swing := -1.0                   # time since the swing started, -1 = not swinging
var _leaving := false


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
		if n.name in Npc.WEAPON_NODES:
			n.visible = n.name == "1H_Sword" or n.name == "Rectangle_Shield"
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim:
		for a in ["Idle", "Running_A"]:
			if _anim.has_animation(a):
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		_anim.play("Idle")
	var tag := Label3D.new()
	tag.text = Strings.GUARD_NAME
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
	var tween := create_tween()
	tween.tween_property(_model_root, "scale", Vector3.ONE * 0.05, 0.6)
	tween.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if _leaving:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		_target = _find_target()
	var wanted := Vector3.ZERO
	var anim := "Idle"
	if _swing >= 0.0:
		_swing += delta
		if _swing >= HIT_TIME and _swing - delta < HIT_TIME:
			_land_blow()
		if _swing >= 0.9:
			_swing = -1.0
	elif _target != null:
		var to := _target.global_position - global_position
		to.y = 0.0
		if to.length() > REACH:
			wanted = to.normalized() * SPEED
			anim = "Running_A"
			_face(to, delta)
		else:
			_face(to, delta)
			if _cooldown <= 0.0:
				_start_swing()
	else:
		var back := home - global_position
		back.y = 0.0
		if back.length() > 1.2:
			wanted = back.normalized() * SPEED * 0.7
			anim = "Running_A"
			_face(back, delta)
	velocity.x = move_toward(velocity.x, wanted.x, 40.0 * delta)
	velocity.z = move_toward(velocity.z, wanted.z, 40.0 * delta)
	move_and_slide()
	if _swing < 0.0 and _anim != null and _anim.has_animation(anim) and _anim.current_animation != anim:
		_anim.play(anim, 0.15)


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_dist := SIGHT
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.is_dead():
			continue
		var d := Vector2(enemy.global_position.x - home.x, enemy.global_position.z - home.z).length()
		var own := global_position.distance_to(enemy.global_position)
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
		_target.take_damage(damage, global_position, 4.0)
		Sfx.play("sword_hit", _target.global_position, -4.0)


func _face(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	_model_root.rotation.y = lerp_angle(_model_root.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-10.0 * delta))
