class_name Enemy
extends CharacterBody3D
## Skeleton enemy (KayKit Skeletons). Patrols around its home point, chases George
## when he comes close, and fights him: swords and axes up close, crossbow arrows or
## magic orbs from a distance. At night "invaders" march on the village well instead of
## patrolling. Stats are set by scripts/enemies.gd before the node enters the tree.

signal died(enemy: Enemy)

@export var model_path := "res://assets/characters/Skeleton_Warrior.glb"
@export var weapon_path := ""         # attached to the right hand
@export var offhand_path := ""        # attached to the left hand
@export var kind_id := "warrior"      # warrior / minion / rogue / mage / brute / captain / king
@export var display_name := ""        # bosses show a name above their head
@export var model_scale := 1.0        # bosses are bigger
@export var tint_color := Color(0, 0, 0, 0)   # alpha 0 = no tint; otherwise a colour wash over the model
@export_group("Stats")
@export var max_health := 45.0
@export var attack_damage := 12.0
@export var patrol_speed := 1.5
@export var chase_speed := 4.2
@export_group("Rewards")
@export var xp_reward := 20
@export var gold_min := 2
@export var gold_max := 6
@export var potion_chance := 0.3
@export_group("Behaviour")
@export var aggro_range := 14.0       # starts chasing inside this distance
@export var leash_range := 26.0       # gives up beyond this distance
@export var attack_range := 2.0
@export var attack_cooldown := 1.6
@export var attack_hit_time := 0.5    # seconds into the swing when the blow lands
@export var attack_anim := ""         # "" = a random one-handed swing
@export var patrol_radius := 6.0
@export var gravity := 22.0
@export_group("Ranged")
@export var ranged := false           # archers and mages keep their distance and shoot
@export var projectile_kind := "arrow"
@export var ranged_min := 6.0
@export var ranged_max := 13.0
@export var projectile_speed := 17.0
@export var shoot_anim := "1H_Ranged_Shoot"
@export_group("Invasion")
@export var invader := false          # marches on the village well until it meets George
@export var march_target := Vector3.ZERO

enum State { PATROL, MARCH, CHASE, ATTACK, HURT, DEAD }

const LOOPED: Array[String] = ["Idle", "Walking_D_Skeletons", "Running_A", "Running_B", "Walking_Backwards"]
const ATTACKS: Array[String] = ["1H_Melee_Attack_Chop", "1H_Melee_Attack_Slice_Horizontal"]
const HITS: Array[String] = ["Hit_A", "Hit_B"]
const HEALTH_BAR_SIZE := Vector2i(48, 6)

@onready var _model_root: Node3D = $Model

var health := 0.0
var _state := State.PATROL
var _anim: AnimationPlayer
var _player: Player
var _home := Vector3.ZERO
var _patrol_target := Vector3.ZERO
var _patrol_wait := 0.0
var _attack_timer := 0.0              # time since the swing started
var _attack_landed := false
var _current_attack := ""
var _hit_time := 0.5
var _cooldown := 0.0
var _hurt_timer := 0.0
var _bar: Sprite3D
var _blocked_time := 0.0              # trying to move but not getting anywhere
var _detour_time := 0.0               # walking around an obstacle
var _detour_sign := 1.0


func _ready() -> void:
	health = max_health
	_model_root.scale = Vector3.ONE * model_scale
	var body_shape := $CollisionShape3D as CollisionShape3D
	body_shape.scale = Vector3.ONE * model_scale
	body_shape.position.y = 0.85 * model_scale
	_home = global_position
	_patrol_target = _home
	_patrol_wait = randf_range(0.5, 3.0)
	add_to_group("enemies")
	if invader:
		add_to_group("invaders")
		_state = State.MARCH
	_load_model()
	_build_health_bar()


func _load_model() -> void:
	var model := (load(model_path) as PackedScene).instantiate() as Node3D
	_model_root.add_child(model)
	_model_root.rotation.y = randf() * TAU

	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton:
		_attach(skeleton, "handslot.r", weapon_path)
		_attach(skeleton, "handslot.l", offhand_path)

	if tint_color.a > 0.0:
		var wash := StandardMaterial3D.new()
		wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wash.albedo_color = tint_color
		wash.cull_mode = BaseMaterial3D.CULL_BACK
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = wash

	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null:
		push_warning("Enemy: no AnimationPlayer in %s" % model_path)
		return
	for anim_name in LOOPED:
		if _anim.has_animation(anim_name):
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	_anim.animation_finished.connect(_on_animation_finished)
	_play("Idle")


func _attach(skeleton: Skeleton3D, bone: String, path: String) -> void:
	if path.is_empty() or skeleton.find_bone(bone) < 0:
		return
	var holder := BoneAttachment3D.new()
	holder.bone_name = bone
	skeleton.add_child(holder)
	holder.add_child((load(path) as PackedScene).instantiate())


func _build_health_bar() -> void:
	_bar = Sprite3D.new()
	_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bar.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_bar.shaded = false
	_bar.position = Vector3(0.0, 2.35 * model_scale, 0.0)
	_bar.pixel_size = 0.028 * maxf(1.0, model_scale * 0.8)
	_bar.visible = display_name != ""
	add_child(_bar)
	_update_health_bar()
	if display_name != "":
		var tag := Label3D.new()
		tag.text = display_name
		tag.font_size = 48
		tag.pixel_size = 0.0085 * maxf(1.0, model_scale * 0.8)
		tag.outline_size = 16
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.modulate = Color(1.0, 0.45, 0.35)
		tag.position = Vector3(0.0, 2.35 * model_scale + 0.55 * maxf(1.0, model_scale * 0.8), 0.0)
		tag.no_depth_test = true
		add_child(tag)


func _update_health_bar() -> void:
	var img := Image.create(HEALTH_BAR_SIZE.x, HEALTH_BAR_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.05, 0.05, 0.9))
	var inner := HEALTH_BAR_SIZE - Vector2i(2, 2)
	var filled := ceili(inner.x * clampf(health / max_health, 0.0, 1.0))
	img.fill_rect(Rect2i(1, 1, filled, inner.y), Color(0.85, 0.15, 0.12))
	_bar.texture = ImageTexture.create_from_image(img)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player

	if not is_on_floor():
		velocity.y -= gravity * delta
	_cooldown = maxf(_cooldown - delta, 0.0)

	var target_velocity := Vector3.ZERO
	match _state:
		State.PATROL:
			target_velocity = _patrol(delta)
		State.MARCH:
			target_velocity = _march(delta)
		State.CHASE:
			target_velocity = _chase()
		State.ATTACK:
			_attack(delta)
		State.HURT:
			_hurt_timer -= delta
			if _hurt_timer <= 0.0:
				_set_state(State.CHASE if _player_alive() else _idle_state())

	# Knockback and stagger decay, normal movement accelerates toward its goal.
	var accel := 30.0 if _state != State.HURT else 8.0
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)
	move_and_slide()
	_check_blocked(target_velocity, delta)


## Skeletons have no navigation mesh: if one pushes against a wall or tree without
## getting anywhere it sidesteps for a moment, which gets it around most obstacles.
func _check_blocked(target_velocity: Vector3, delta: float) -> void:
	if _detour_time > 0.0:
		_detour_time -= delta
		return
	var want := Vector2(target_velocity.x, target_velocity.z).length()
	var real := get_real_velocity()
	var got := Vector2(real.x, real.z).length()
	if want > 0.5 and got < want * 0.25:
		_blocked_time += delta
		if _blocked_time > 0.45:
			_detour_time = 1.3
			_detour_sign = -1.0 if randf() < 0.5 else 1.0
			_blocked_time = 0.0
	else:
		_blocked_time = 0.0


func _detour(dir: Vector3) -> Vector3:
	if _detour_time > 0.0:
		return dir.rotated(Vector3.UP, deg_to_rad(80.0) * _detour_sign)
	return dir


func _idle_state() -> State:
	return State.MARCH if invader else State.PATROL


func _patrol(delta: float) -> Vector3:
	if _can_see_player():
		_set_state(State.CHASE)
		return Vector3.ZERO
	if _patrol_wait > 0.0:
		_patrol_wait -= delta
		_play("Idle", 0.2)
		if _patrol_wait <= 0.0:
			var angle := randf() * TAU
			_patrol_target = _home + Vector3(cos(angle), 0.0, sin(angle)) * randf_range(2.0, patrol_radius)
		return Vector3.ZERO
	var to_target := _flat(_patrol_target - global_position)
	if to_target.length() < 0.6:
		_patrol_wait = randf_range(1.5, 4.0)
		return Vector3.ZERO
	var dir := _detour(to_target.normalized())
	_face(dir, delta)
	_play("Walking_D_Skeletons", 0.2)
	return dir * patrol_speed


## Night invaders run for the well in the middle of the village.
func _march(delta: float) -> Vector3:
	if _can_see_player():
		_set_state(State.CHASE)
		return Vector3.ZERO
	var to_target := _flat(march_target - global_position)
	if to_target.length() < 6.0:
		_play("Idle", 0.2)   # they have arrived and are tearing at the village
		return Vector3.ZERO
	var dir := _detour(to_target.normalized())
	_face(dir, delta)
	_play("Running_A", 0.15)
	return dir * chase_speed * 0.85


func _chase() -> Vector3:
	if not _player_alive():
		_set_state(_idle_state())
		return Vector3.ZERO
	var to_player := _flat(_player.global_position - global_position)
	var dist := to_player.length()
	if dist > leash_range:
		_set_state(_idle_state())
		_patrol_target = _home
		return Vector3.ZERO
	var delta := get_physics_process_delta_time()
	_face(to_player, delta)
	if ranged:
		return _chase_ranged(to_player, dist, delta)
	if dist <= attack_range and _cooldown <= 0.0:
		_start_attack()
		return Vector3.ZERO
	if dist <= attack_range * 0.85:
		_play("Idle", 0.15)  # close enough, wait for the cooldown
		return Vector3.ZERO
	_play("Running_A", 0.15)
	return _detour(to_player.normalized()) * chase_speed


## Archers and mages: back away when George is close, close in when he is far,
## and shoot from the comfortable distance in between.
func _chase_ranged(to_player: Vector3, dist: float, _delta: float) -> Vector3:
	if dist < ranged_min:
		if _cooldown <= 0.0 and dist < ranged_min * 0.6:
			_start_attack()   # cornered: shoot anyway
			return Vector3.ZERO
		_play("Walking_Backwards", 0.1)
		return _detour(-to_player.normalized()) * chase_speed * 0.8
	if dist > ranged_max:
		_play("Running_A", 0.15)
		return _detour(to_player.normalized()) * chase_speed
	_play("Idle", 0.15)
	if _cooldown <= 0.0:
		_start_attack()
	return Vector3.ZERO


func _start_attack() -> void:
	_set_state(State.ATTACK)
	_attack_timer = 0.0
	_attack_landed = false
	if ranged:
		_current_attack = shoot_anim
		_hit_time = 0.55
		if _anim and _anim.has_animation(shoot_anim):
			_hit_time = _anim.get_animation(shoot_anim).length * 0.55
	else:
		_current_attack = attack_anim if attack_anim != "" else ATTACKS.pick_random()
		_hit_time = attack_hit_time
	_play(_current_attack, 0.08, true)


func _attack(delta: float) -> void:
	_attack_timer += delta
	if ranged and not _attack_landed and _player_alive():
		_face(_flat(_player.global_position - global_position), delta)   # keep aiming
	if not _attack_landed and _attack_timer >= _hit_time:
		_attack_landed = true
		if ranged:
			_fire()
		elif _player_alive():
			var to_player := _flat(_player.global_position - global_position)
			var forward := Vector3(sin(_model_root.rotation.y), 0.0, cos(_model_root.rotation.y))
			if to_player.length() <= attack_range + 0.6 and forward.dot(to_player.normalized()) > 0.3:
				_player.take_damage(attack_damage, global_position)


func _fire() -> void:
	if not _player_alive() or get_parent() == null:
		return
	var forward := Vector3(sin(_model_root.rotation.y), 0.0, cos(_model_root.rotation.y))
	var muzzle := global_position + Vector3.UP * 1.3 * model_scale + forward * 0.7
	var aim := _player.global_position + Vector3.UP * 1.0 - muzzle
	if projectile_kind == "arrow":
		aim = aim.rotated(Vector3.UP, randf_range(-0.05, 0.05))   # archers are not perfect
	get_parent().add_child(Projectile.make(projectile_kind, muzzle, aim, projectile_speed, attack_damage))


func take_damage(amount: float, from: Vector3, knock: float = 5.0) -> void:
	if _state == State.DEAD:
		return
	health -= amount
	_bar.visible = true
	_update_health_bar()
	var away := _flat(global_position - from)
	if away.length() < 0.01:
		away = Vector3.BACK
	away = away.normalized()
	if health <= 0.0:
		_die(away)
		return
	_set_state(State.HURT)
	_hurt_timer = 0.45
	_cooldown = maxf(_cooldown, 0.5)
	velocity.x = away.x * knock
	velocity.z = away.z * knock
	_play(HITS.pick_random(), 0.05, true)


## Stuns the skeleton for a while (the Charge skill).
func stun(seconds: float) -> void:
	if _state == State.DEAD:
		return
	_set_state(State.HURT)
	_hurt_timer = maxf(_hurt_timer, seconds)
	_play(HITS.pick_random(), 0.05, true)


func _die(_away: Vector3) -> void:
	_set_state(State.DEAD)
	remove_from_group("enemies")
	remove_from_group("invaders")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	_bar.visible = false
	_play("Death_B", 0.05, true)
	died.emit(self)
	var tween := create_tween()
	tween.tween_interval(3.5)
	tween.tween_property(self, "position:y", position.y - 2.0, 1.5)
	tween.tween_callback(queue_free)


## At dawn the invaders that are left crumble to dust (no reward, no `died` signal).
func dissolve() -> void:
	if _state == State.DEAD:
		return
	_set_state(State.DEAD)
	remove_from_group("enemies")
	remove_from_group("invaders")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	_bar.visible = false
	_play("Death_A", 0.05, true)
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(self, "position:y", position.y - 2.5, 1.2)
	tween.tween_callback(queue_free)


func _set_state(s: State) -> void:
	_state = s


func is_dead() -> bool:
	return _state == State.DEAD


func _can_see_player() -> bool:
	return _player_alive() and global_position.distance_to(_player.global_position) <= aggro_range


func _player_alive() -> bool:
	return _player != null and not _player.is_dead


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _face(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	# KayKit models face +Z, so yaw = atan2(x, z).
	var target_angle := atan2(direction.x, direction.z)
	_model_root.rotation.y = lerp_angle(_model_root.rotation.y, target_angle, 1.0 - exp(-10.0 * delta))


func _play(anim_name: String, blend: float = 0.15, restart: bool = false) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	if not restart and _anim.current_animation == anim_name and _anim.is_playing():
		return
	_anim.play(anim_name, blend)


func _on_animation_finished(anim_name: StringName) -> void:
	if _state == State.ATTACK and String(anim_name) == _current_attack:
		_cooldown = attack_cooldown
		_set_state(State.CHASE if _player_alive() else _idle_state())
