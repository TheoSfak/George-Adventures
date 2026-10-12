class_name Player
extends CharacterBody3D
## George - third-person hero (KayKit Knight model).
## World-of-Warcraft style controls:
##   Hold RIGHT mouse: look around and steer George (A/D strafe).   Hold LEFT mouse: orbit the camera.
##   Both buttons: run forward.   W/S forward/back, A/D turn, Q/E strafe, Shift run, Space jump.
##   Quick left click / F / J: attack.   K / Ctrl: block.   Mouse wheel: zoom.   Gamepad also works.

signal attacked(combo_index: int)
signal health_changed(current: float, maximum: float)
signal died
signal respawned
signal xp_changed(level: int, xp: int, xp_needed: int)
signal leveled_up(level: int)
signal inventory_changed(gold: int, potions: int)
signal message(text: String)
signal prompt_changed(text: String)
signal bar_changed
signal talents_changed
signal gear_changed

@export_group("Movement")
@export var walk_speed := 5.0
@export var run_speed := 9.0
@export var jump_velocity := 8.5
@export var gravity := 22.0
@export var acceleration := 30.0
@export var turn_speed := 14.0

@export_group("Combat")
@export var max_health := 100.0
@export var sword_damage := 15.0
@export var sword_reach := 2.9          # metres in front of George
@export var sword_arc := 0.35           # min dot(facing, direction to enemy); 0.35 = ~140 degree cone
@export var sword_hit_delay := 0.3      # seconds into the swing when the blade connects
@export var block_reduction := 0.85     # share of damage a block absorbs from the front
@export var respawn_time := 3.0

@export_group("Progress")
@export var max_level := 20
@export var health_per_level := 10.0
@export var damage_per_level := 2.0
@export var potion_heal := 40.0

@export_group("Camera")
@export var mouse_sensitivity := 0.0025
@export var stick_sensitivity := 2.8
@export var pitch_min := -1.1   # camera high, looking down
@export var pitch_max := 0.45   # camera low, looking up
@export var camera_height := 1.7
@export var camera_follow := 14.0
@export var zoom_min := 2.5
@export var zoom_max := 14.0
@export var key_turn_speed := 3.0       # radians/second when turning with A/D
@export var camera_recenter := 7.0      # how fast the camera swings back behind George

const MODEL_PATH := "res://assets/characters/Knight.glb"

# The KayKit model ships with every weapon/shield visible. Hide the ones we don't use.
const HIDDEN_NODES: Array[String] = [
	"1H_Sword_Offhand", "2H_Sword", "Badge_Shield", "Rectangle_Shield", "Spike_Shield",
]

const LOOPED: Array[String] = [
	"Idle", "Walking_A", "Walking_B", "Walking_C", "Running_A", "Running_B",
	"Jump_Idle", "Blocking", "Walking_Backwards",
]

const COMBO: Array[String] = [
	"1H_Melee_Attack_Slice_Diagonal",
	"1H_Melee_Attack_Slice_Horizontal",
	"1H_Melee_Attack_Chop",
]

@onready var _model_root: Node3D = $Model
@onready var _rig: Node3D = $CameraRig
@onready var _arm: SpringArm3D = $CameraRig/SpringArm3D

var _model: Node3D
var _anim: AnimationPlayer
var _yaw := 0.0               # camera yaw
var _heading := PI            # which way George faces (KayKit yaw: forward = (sin, 0, cos))
var _mouse_look := false      # a mouse button is held, so the cursor is hidden and moves the camera
var _saved_cursor := Vector2.ZERO
var _lmb_travel := 0.0        # how far the mouse moved while the left button was down
var _lmb_time := 0.0
var _attack_queued := 0.0     # seconds left on a buffered attack click
var _pitch := -0.3
var _attacking := false
var _blocking := false
var _landing := false
var _combo_index := 0
var _combo_timer := 0.0
var _was_on_floor := true
var _spawn_point := Vector3.ZERO
var health := 0.0
var is_dead := false
var level := 1
var xp := 0
var gold := 0
var consumables := {"health": 0, "health_big": 0, "power": 0, "speed": 0}
var base_max_health := 100.0     # without equipment and talents; max_health / sword_damage are the totals
var base_damage := 15.0
var stats := Stats.new()         # equipment and talent modifiers (stats.gd)
var gear_owned: Array[String] = []                       # ids from ShopData.GEAR that George owns
var equipped := {"weapon": "", "armor": "", "shield": ""} # slot -> gear id ("" = George's own gear)
var junk := {}                   # junk id -> count, sold at the market
var talents := {}                # talent id -> rank (talent_data.gd)
var _frenzy_time := 0.0
var _shout_time := 0.0
var _wall_time := 0.0
var _sanct_time := 0.0
var _sanct_pos := Vector3.ZERO
var _sanct_visual: MeshInstance3D
var _rebirth_cd := 0.0
var _regen_acc := 0.0
var _leap_time := 0.0
var _leaping := false
var _leap_clock := 0.0
var _crit_notice := 0.0
var potions: int:                # health potions (kept for older code)
	get:
		return consumables["health"]
	set(v):
		consumables["health"] = v
var bar: Array[String] = []      # the 8 action-bar slots, see skill_data.gd
var _cooldowns := {}             # skill id -> seconds left
var _potion_cooldown := 0.0
var _guard_time := 0.0
var _power_time := 0.0
var _speed_time := 0.0
var _dash_time := 0.0
var _dash_dir := Vector3.ZERO
var _dash_hit: Array = []
var _special_time := 0.0         # a gesture animation (prayer) is playing
var _game_lmb := false           # mouse buttons that went down over the game, not over a menu
var _game_rmb := false
var _guard_visual: MeshInstance3D
var busy := false              # in a dialogue or a door transition: George stands still
var _interactable: Node
var _last_prompt := ""
var _stun := 0.0
var _attack_serial := 0
var _invulnerable := 0.0
var _step_dist := 0.0


func _ready() -> void:
	add_to_group("player")
	base_max_health = max_health
	base_damage = sword_damage
	_recalc()
	health = max_health
	_spawn_point = global_position
	_rig.top_level = true
	_rig.global_position = global_position + Vector3.UP * camera_height
	_arm.add_excluded_object(get_rid())
	bar.assign(SkillData.DEFAULT_BAR)
	_load_model()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Let the HUD (which is built after the player) show the starting values.
	_announce.call_deferred()


func _load_model() -> void:
	var scene := load(MODEL_PATH) as PackedScene
	_model = scene.instantiate()
	_model_root.add_child(_model)
	_heading = PI
	_model_root.rotation.y = _heading  # face -Z (into the screen) at start
	_yaw = 0.0

	for n in _model.find_children("*", "Node3D", true, false):
		if n.name in HIDDEN_NODES:
			n.visible = false
	_update_equipment_visuals()

	_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null:
		push_warning("Player: no AnimationPlayer found in %s" % MODEL_PATH)
		return
	for anim_name in LOOPED:
		if _anim.has_animation(anim_name):
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	_anim.animation_finished.connect(_on_animation_finished)
	_play("Idle")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _mouse_look:
			_yaw -= event.relative.x * mouse_sensitivity
			_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, pitch_min, pitch_max)  # mouse up = look up
			_lmb_travel += event.relative.length()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_arm.spring_length = clampf(_arm.spring_length - 0.8, zoom_min, zoom_max)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_arm.spring_length = clampf(_arm.spring_length + 0.8, zoom_min, zoom_max)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_game_lmb = true
				_lmb_travel = 0.0
				_lmb_time = 0.0
			elif _game_lmb and _lmb_travel < 8.0 and _lmb_time < 0.3 and not _game_rmb:
				_attack_queued = 0.25  # a quick click with no dragging is a sword swing
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_game_rmb = true


## The cursor is free normally. While left or right mouse is held it is hidden and
## locked, so moving the mouse turns the camera - the same trick World of Warcraft uses.
func _update_mouse_look(delta: float) -> void:
	_game_lmb = _game_lmb and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_game_rmb = _game_rmb and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var lmb := _game_lmb
	var rmb := _game_rmb
	if lmb:
		_lmb_time += delta
	var want := lmb or rmb
	if want and not _mouse_look:
		_saved_cursor = get_viewport().get_mouse_position()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif not want and _mouse_look:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.warp_mouse(_saved_cursor)
	_mouse_look = want


func _physics_process(delta: float) -> void:
	_update_mouse_look(delta)
	_update_interaction()
	_tick_timers(delta)
	if not busy:
		if Input.is_action_just_pressed("potion"):
			use_consumable("health")
		for i in bar.size():
			if Input.is_action_just_pressed("slot_%d" % (i + 1)):
				use_slot(i)
	var rmb := _game_rmb
	var lmb := _game_lmb

	# --- Camera look (gamepad stick) ---
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	_yaw -= look.x * stick_sensitivity * delta
	_pitch = clampf(_pitch + look.y * stick_sensitivity * delta, pitch_min, pitch_max)

	# --- Gravity and jumping ---
	var on_floor := is_on_floor()
	if not on_floor:
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and not _attacking and not is_dead and _stun <= 0.0 and not busy:
		velocity.y = jump_velocity
		Sfx.play("jump", global_position, -4.0)
		_landing = false
		_play("Jump_Start", 0.05)

	# --- Combat state ---
	_stun = maxf(_stun - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	var can_act := not is_dead and _stun <= 0.0 and not busy
	_blocking = can_act and on_floor and not _attacking and Input.is_action_pressed("block")
	_attack_queued = maxf(_attack_queued - delta, 0.0)
	if Input.is_action_just_pressed("attack"):
		_attack_queued = 0.25
	if can_act and on_floor and not _blocking and _attack_queued > 0.0 and not _attacking:
		_attack_queued = 0.0
		_start_attack()
	_combo_timer -= delta
	if _combo_timer <= 0.0 and not _attacking:
		_combo_index = 0

	# --- Steering ---
	# Right mouse: George always faces where the camera looks, A/D strafe.
	# Otherwise A/D turn George, and the camera swings back behind him once the mouse is released.
	var forward_axis := Input.get_axis("move_back", "move_forward")
	var strafe_axis := Input.get_axis("strafe_left", "strafe_right")
	var turn_axis := Input.get_axis("turn_left", "turn_right")
	if rmb:
		strafe_axis = clampf(strafe_axis + turn_axis, -1.0, 1.0)
		turn_axis = 0.0
	if lmb and rmb:
		forward_axis = 1.0
	if not can_act:
		forward_axis = 0.0
		strafe_axis = 0.0
		turn_axis = 0.0

	var pad := Input.get_vector("pad_left", "pad_right", "pad_forward", "pad_back")
	var using_pad := can_act and pad.length() > 0.1
	var prev_heading := _heading
	if rmb:
		_heading = _yaw + PI
	elif turn_axis != 0.0:
		_heading -= turn_axis * key_turn_speed * delta
	if not _mouse_look and (turn_axis != 0.0 or forward_axis != 0.0 or strafe_axis != 0.0 or using_pad):
		_yaw = lerp_angle(_yaw, _heading + PI, 1.0 - exp(-camera_recenter * delta))

	# Steering turns George's momentum with him (no drifting or slowing down in a turn, like WoW).
	if on_floor and _stun <= 0.0 and not using_pad:
		var flat := Vector3(velocity.x, 0.0, velocity.z).rotated(Vector3.UP, angle_difference(prev_heading, _heading))
		velocity.x = flat.x
		velocity.z = flat.z

	var facing := Vector3(sin(_heading), 0.0, cos(_heading))
	var right := Vector3(-cos(_heading), 0.0, sin(_heading))
	var dir := facing * forward_axis + right * strafe_axis
	if using_pad:
		dir = Basis(Vector3.UP, _yaw) * Vector3(pad.x, 0.0, pad.y)
		_heading = atan2(dir.x, dir.z)
	dir = dir.limit_length(1.0)

	var speed := run_speed if Input.is_action_pressed("run") else walk_speed
	if _speed_time > 0.0:
		speed *= 1.4
	speed *= 1.0 + stats.total("speed_mult") + (0.15 if _frenzy_time > 0.0 else 0.0)
	if forward_axis < 0.0 and strafe_axis == 0.0:
		speed *= 0.6  # backing up is slower
	var target := dir * speed
	if _attacking:
		target = Vector3.ZERO
	elif _blocking:
		target *= 0.3
	# Being hit knocks George back, so let the knockback decay instead of snapping to zero.
	var accel := acceleration if _stun <= 0.0 else 6.0
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	if _dash_time > 0.0:
		velocity.x = _dash_dir.x * 30.0
		velocity.z = _dash_dir.z * 30.0
		_dash_hits()
	if _leap_time > 0.0:
		velocity.x = _dash_dir.x * 9.0
		velocity.z = _dash_dir.z * 9.0

	var fall_speed := velocity.y
	move_and_slide()

	# --- Κεραυνός του Πολέμου: the slam happens when the leap lands
	if _leaping:
		_leap_clock += delta
		if (is_on_floor() and _leap_clock > 0.15) or _leap_clock > 1.6:
			_leaping = false
			_leap_time = 0.0
			_leap_slam()

	# --- Landing ---
	if is_on_floor() and not _was_on_floor and not _attacking:
		_landing = true
		_play("Jump_Land", 0.05)
		if fall_speed < -6.0:
			Sfx.play("land", global_position, -2.0)
	_was_on_floor = is_on_floor()
	_footsteps()

	# --- Turn the model toward its heading ---
	_model_root.rotation.y = lerp_angle(_model_root.rotation.y, _heading, 1.0 - exp(-turn_speed * delta))

	_update_camera(delta)
	_update_animation()

	if global_position.y < -30.0:
		global_position = _spawn_point
		velocity = Vector3.ZERO


## A footstep every stride: cobbles in the square, wood indoors, grass elsewhere.
func _footsteps() -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or is_dead or speed < 1.2:
		return
	_step_dist += speed * get_physics_process_delta_time()
	if _step_dist < (2.4 if speed > 6.5 else 1.7):
		return
	_step_dist = 0.0
	var interiors := get_tree().get_first_node_in_group("interiors")
	var id := "footstep_grass"
	if interiors != null and interiors.is_inside():
		id = "footstep_wood"
	elif Vector2(global_position.x, global_position.z).length() < 26.0:
		id = "footstep_stone"
	Sfx.play(id)


func _update_camera(delta: float) -> void:
	_rig.rotation.y = _yaw
	_arm.rotation.x = _pitch
	var goal := global_position + Vector3.UP * camera_height
	_rig.global_position = _rig.global_position.lerp(goal, 1.0 - exp(-camera_follow * delta))


func _start_attack(skill: String = "") -> void:
	_attacking = true
	_assist_aim()
	_combo_timer = 1.4
	Sfx.play("sword_swing", global_position, -2.0)
	if skill == "power_strike":
		_play("1H_Melee_Attack_Chop", 0.05, true)
		attacked.emit(2)
		get_tree().create_timer(sword_hit_delay + 0.05).timeout.connect(_swing_hits.bind(_attack_serial_next(), sword_damage * 2.2 * (1.0 + stats.total("ps_mult")), 11.0))
		return
	var idx := _combo_index
	_combo_index = (_combo_index + 1) % COMBO.size()
	_play(COMBO[idx], 0.06)
	attacked.emit(idx)
	# The third hit of the combo is a heavy chop.
	var damage := sword_damage * (1.5 if idx == COMBO.size() - 1 else 1.0)
	get_tree().create_timer(sword_hit_delay).timeout.connect(_swing_hits.bind(_attack_serial_next(), damage))


## Swinging at something close but not quite in front turns George toward it.
func _assist_aim() -> void:
	var best: Enemy = null
	var best_dist := sword_reach + 1.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_to((e as Enemy).global_position)
		if d < best_dist:
			best_dist = d
			best = e as Enemy
	if best and not _game_rmb:  # with right mouse held the camera aims
		var to := best.global_position - global_position
		_heading = atan2(to.x, to.z)
		_model_root.rotation.y = _heading


func _attack_serial_next() -> int:
	_attack_serial += 1
	return _attack_serial


## Damages every enemy in the cone in front of George, unless the swing was interrupted.
func _swing_hits(serial: int, damage: float, knock: float = 5.0) -> void:
	if serial != _attack_serial or not _attacking or is_dead:
		return
	var forward := _facing()
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		var to_enemy := enemy.global_position - global_position
		to_enemy.y = 0.0
		var dist := to_enemy.length()
		if dist > sword_reach:
			continue
		if dist > 0.8 and forward.dot(to_enemy / dist) < sword_arc:
			continue
		_hit(enemy, damage, knock)
	_hit_breakables(damage, sword_reach, true)


## Totems and other breakable objects take the same blows as skeletons. `reach` is measured
## from the surface of the object; with `cone` only things in front of George are hit.
func _hit_breakables(damage: float, reach: float, cone: bool = false) -> void:
	var forward := _facing()
	for b in get_tree().get_nodes_in_group("breakables"):
		if not b.visible:
			continue
		var to: Vector3 = b.global_position - global_position
		to.y = 0.0
		var dist := to.length() - float(b.get("hit_radius"))
		if dist > reach:
			continue
		if cone and dist > 0.8 and forward.dot(to.normalized()) < sword_arc:
			continue
		b.take_damage(damage * _damage_mult(), global_position)


## Every blow George lands goes through here: damage buffs, critical hits, lifesteal, stun.
func _hit(enemy: Enemy, damage: float, knock: float, stun_time: float = 0.0) -> void:
	var dealt := damage * _damage_mult()
	var crit := randf() < stats.total("crit")
	if crit:
		dealt *= 2.0
		if _crit_notice <= 0.0:
			message.emit(Strings.MSG_CRIT)
			_crit_notice = 1.5
	enemy.take_damage(dealt, global_position, knock)
	Sfx.play("sword_crit" if crit else "sword_hit", enemy.global_position)
	if stun_time > 0.0:
		enemy.stun(stun_time)
	var steal := stats.total("lifesteal") + (0.12 if _frenzy_time > 0.0 else 0.0)
	if steal > 0.0:
		_restore(dealt * steal)


## Raw health restoring (lifesteal, regeneration); potions and prayers apply heal_mult themselves.
func _restore(amount: float) -> void:
	if is_dead or health >= max_health:
		return
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)


func _facing() -> Vector3:
	# KayKit models face +Z, so forward = (sin yaw, 0, cos yaw).
	return Vector3(sin(_model_root.rotation.y), 0.0, cos(_model_root.rotation.y))


## Called by enemies. `from` is the attacker's position (for blocking and knockback).
func take_damage(amount: float, from: Vector3) -> void:
	if is_dead or _invulnerable > 0.0:
		return
	if _guard_time > 0.0:
		amount *= 0.25
	if _shout_time > 0.0:
		amount *= 0.75
	if _sanct_time > 0.0 and global_position.distance_to(_sanct_pos) < 5.0:
		amount *= 0.85
	if health < max_health * 0.3:
		amount *= 1.0 - stats.total("last_stand")
	amount *= 1.0 - stats.total("defense")
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -_facing()
	var blocked := _blocking and _facing().dot(-away) > 0.2
	if blocked:
		amount *= 1.0 - minf(block_reduction + stats.total("block_add"), 0.95)
		velocity.x = away.x * 2.5
		velocity.z = away.z * 2.5
		_play("Block_Hit", 0.05, true)
		Sfx.play("block_hit", global_position)
		_invulnerable = 0.3
	else:
		_attacking = false
		_attack_serial += 1  # cancels a swing that has not connected yet
		_landing = false
		_stun = 0.4
		_invulnerable = 0.7
		velocity.x = away.x * 6.0
		velocity.z = away.z * 6.0
		_play("Hit_A", 0.05, true)
		Sfx.play("player_hurt", global_position)
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		if stats.total("rebirth") > 0.0 and _rebirth_cd <= 0.0:
			_rebirth_cd = 300.0
			health = max_health * 0.5
			_invulnerable = 2.0
			health_changed.emit(health, max_health)
			message.emit(Strings.MSG_REBIRTH)
			Sfx.ui("skill_resurrect")
			_ring_effect(Color(1.0, 0.92, 0.45), 5.0, 1.0, 0.2)
			return
		_die()


# ------------------------------------------------------------ progression ----

func xp_needed(for_level: int = level) -> int:
	return 40 + 35 * (for_level - 1)


func gain_xp(amount: int) -> void:
	if is_dead or level >= max_level:
		return
	xp += amount
	message.emit(Strings.MSG_XP % amount)
	while level < max_level and xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		base_max_health += health_per_level
		base_damage += damage_per_level
		_recalc()
		health = max_health
		health_changed.emit(health, max_health)
		leveled_up.emit(level)
		Sfx.ui("level_up")
		for id in SkillData.SKILLS:
			if SkillData.SKILLS[id]["level"] == level and not SkillData.is_talent_skill(id):
				message.emit(Strings.SKILL_UNLOCKED % SkillData.SKILLS[id]["name"])
		message.emit(Strings.MSG_TALENT_POINT)
		talents_changed.emit()
	if level >= max_level:
		xp = 0
	xp_changed.emit(level, xp, xp_needed())


## Called by pickups and chests.
func collect(kind: String, amount: int) -> void:
	Sfx.ui("gold_pickup" if kind == "gold" else "item_pickup", -3.0)
	match kind:
		"gold":
			gold += amount
			message.emit(Strings.MSG_GOLD % amount)
		"potion":
			consumables["health"] += amount
			message.emit(Strings.MSG_POTION if amount == 1 else Strings.MSG_POTIONS % amount)
		"power_potion":
			consumables["power"] += amount
			message.emit(Strings.MSG_POTION_POWER)
		"speed_potion":
			consumables["speed"] += amount
			message.emit(Strings.MSG_POTION_SPEED)
		_:
			if kind.begins_with("junk_"):
				var jid := kind.substr(5)
				junk[jid] = int(junk.get(jid, 0)) + amount
				message.emit(Strings.MSG_JUNK % ShopData.JUNK[jid]["name"])
	inventory_changed.emit(gold, potions)


func use_potion() -> void:
	use_consumable("health")


## Drinks a potion: "health", "power" or "speed".
func use_consumable(id: String) -> void:
	if is_dead or busy or consumables.get(id, 0) <= 0 or _potion_cooldown > 0.0:
		return
	match id:
		"health":
			if health >= max_health:
				return
			var healed := potion_heal * (1.0 + stats.total("heal_mult"))
			health = minf(health + healed, max_health)
			health_changed.emit(health, max_health)
			message.emit(Strings.MSG_POTION_USED % int(healed))
		"health_big":
			if health >= max_health:
				return
			var healed_big := 100.0 * (1.0 + stats.total("heal_mult"))
			health = minf(health + healed_big, max_health)
			health_changed.emit(health, max_health)
			message.emit(Strings.MSG_POTION_USED % int(healed_big))
		"power":
			_power_time = 25.0
			message.emit(Strings.MSG_POWER_ON)
		"speed":
			_speed_time = 20.0
			message.emit(Strings.MSG_SPEED_ON)
	consumables[id] -= 1
	_potion_cooldown = 0.6
	Sfx.ui("potion_drink" if id.begins_with("health") else "potion_buff")
	inventory_changed.emit(gold, potions)


## Quest rewards: {"xp": N, "gold": N, "potions": N, "damage": N}
func apply_reward(reward: Dictionary) -> void:
	if reward.has("gold"):
		collect("gold", reward["gold"])
	if reward.has("potions"):
		collect("potion", reward["potions"])
	if reward.has("power"):
		collect("power_potion", int(reward["power"]))
	if reward.has("speed"):
		collect("speed_potion", int(reward["speed"]))
	if reward.has("damage"):
		base_damage += reward["damage"]
		_recalc()
		message.emit(Strings.MSG_DAMAGE_UP % int(reward["damage"]))
	if reward.has("xp"):
		gain_xp(reward["xp"])


# ------------------------------------------------------ equipment & talents ----

## Adds up equipment and talent modifiers into max_health and sword_damage.
func _recalc() -> void:
	stats.set_source("equip", ShopData.equipment_mods(equipped))
	stats.set_source("talents", TalentData.mods_for(talents))
	var old_max := max_health
	max_health = base_max_health + stats.total("hp_add")
	sword_damage = (base_damage + stats.total("damage_add")) * (1.0 + stats.total("damage_mult"))
	if not is_dead and health > 0.0 and max_health > old_max:
		health += max_health - old_max
	health = minf(health, max_health)
	health_changed.emit(health, max_health)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		message.emit(Strings.MSG_NO_GOLD)
		Sfx.ui("error")
		return false
	gold -= amount
	inventory_changed.emit(gold, potions)
	return true


## Puts on a piece of gear George owns. Returns false when his level is too low.
func equip(id: String) -> bool:
	if not gear_owned.has(id):
		return false
	var g: Dictionary = ShopData.GEAR[id]
	if level < int(g["level"]):
		message.emit(Strings.SKILL_LOCKED % int(g["level"]))
		return false
	equipped[g["slot"]] = id
	_recalc()
	_update_equipment_visuals()
	message.emit(Strings.MSG_EQUIPPED % g["name"])
	Sfx.ui("equip")
	gear_changed.emit()
	return true


func unequip(slot: String) -> void:
	equipped[slot] = ""
	_recalc()
	_update_equipment_visuals()
	gear_changed.emit()


func _gear_tier(slot: String) -> int:
	var id: String = equipped.get(slot, "")
	return 0 if id == "" else int(ShopData.GEAR[id]["tier"])


const SHIELD_NODES: Array[String] = ["Round_Shield", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "Spike_Shield"]
const ARMOR_NODES: Array[String] = ["Knight_Body", "Knight_ArmLeft", "Knight_ArmRight", "Knight_LegLeft", "Knight_LegRight", "Knight_Helmet"]


## Shows the equipped shield and sword on the model; higher tiers glow, armor gets a tint.
func _update_equipment_visuals() -> void:
	if _model == null:
		return
	var weapon_tier := _gear_tier("weapon")
	var armor_tier := _gear_tier("armor")
	var shield_tier := _gear_tier("shield")
	var shield_name := SHIELD_NODES[shield_tier]
	for n in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.name in ["Round_Shield", "Badge_Shield", "Rectangle_Shield", "Spike_Shield"]:
			mi.visible = mi.name == shield_name
			mi.material_overlay = _glow_overlay(ShopData.TIER_COLORS[3], 0.28) if shield_tier == 4 and mi.visible else null
		elif mi.name == "1H_Sword":
			mi.visible = weapon_tier < 3
			mi.material_overlay = _glow_overlay(ShopData.TIER_COLORS[weapon_tier - 1], 0.30) if weapon_tier == 2 else null
		elif mi.name == "2H_Sword":
			mi.visible = weapon_tier >= 3
			mi.material_overlay = _glow_overlay(ShopData.TIER_COLORS[weapon_tier - 1], 0.30) if weapon_tier >= 3 else null
		elif mi.name in ARMOR_NODES:
			mi.material_overlay = _glow_overlay(ShopData.TIER_COLORS[armor_tier - 1], 0.07, 0.12) if armor_tier >= 2 else null


func _glow_overlay(color: Color, alpha: float, glow: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = glow
	return m


func talent_points_free() -> int:
	return TalentData.points_for_level(level) - TalentData.spent(talents)


## Spends one talent point. Returns true if the talent got a new rank.
func learn_talent(id: String) -> bool:
	if is_dead or TalentData.block_reason(talents, id, talent_points_free()) != "":
		return false
	talents[id] = int(talents.get(id, 0)) + 1
	Sfx.ui("talent_learn")
	var node: Dictionary = TalentData.NODES[id]
	if node.has("skill"):
		var skill: String = node["skill"]
		message.emit(Strings.SKILL_UNLOCKED % SkillData.SKILLS[skill]["name"])
		if not bar.has(skill):
			var free := bar.find("")
			if free >= 0:
				bar[free] = skill
				bar_changed.emit()
	_recalc()
	talents_changed.emit()
	return true


func respec_cost() -> int:
	return 50 * level


## Takes all talent points back for gold. Learned talent skills leave the action bar.
func respec() -> bool:
	if talents.is_empty():
		message.emit(Strings.MSG_RESPEC_NONE)
		return false
	if not spend_gold(respec_cost()):
		return false
	talents.clear()
	for i in bar.size():
		if SkillData.is_talent_skill(bar[i]):
			bar[i] = ""
	_recalc()
	message.emit(Strings.MSG_RESPEC_DONE)
	talents_changed.emit()
	bar_changed.emit()
	return true


# ------------------------------------------------------------------ skills ----

func _tick_timers(delta: float) -> void:
	_potion_cooldown = maxf(_potion_cooldown - delta, 0.0)
	for id in _cooldowns.keys():
		_cooldowns[id] = maxf(_cooldowns[id] - delta, 0.0)
	_guard_time = maxf(_guard_time - delta, 0.0)
	_power_time = maxf(_power_time - delta, 0.0)
	_speed_time = maxf(_speed_time - delta, 0.0)
	_special_time = maxf(_special_time - delta, 0.0)
	_frenzy_time = maxf(_frenzy_time - delta, 0.0)
	_shout_time = maxf(_shout_time - delta, 0.0)
	_wall_time = maxf(_wall_time - delta, 0.0)
	_rebirth_cd = maxf(_rebirth_cd - delta, 0.0)
	_crit_notice = maxf(_crit_notice - delta, 0.0)
	_leap_time = maxf(_leap_time - delta, 0.0)
	_tick_regen(delta)
	if _dash_time > 0.0:
		_dash_time -= delta
		if _dash_time <= 0.0:
			_attacking = false
			velocity.x = 0.0   # stop where the dash ends instead of gliding on
			velocity.z = 0.0
	if _guard_visual != null:
		var shielded := maxf(_guard_time, _wall_time)
		_guard_visual.visible = shielded > 0.0
		if shielded > 0.0:
			var pulse := 1.0 + sin(Time.get_ticks_msec() / 120.0) * 0.04
			_guard_visual.scale = Vector3.ONE * pulse * (0.7 + 0.3 * minf(shielded, 1.0))


## Regeneration (talents, armor, the Ιερός Κύκλος). Health changes are batched to ~4 per second.
func _tick_regen(delta: float) -> void:
	var rate := stats.total("regen")
	if _sanct_time > 0.0:
		_sanct_time -= delta
		if global_position.distance_to(_sanct_pos) < 5.0:
			rate += max_health * 0.04
		if _sanct_time <= 0.0 and _sanct_visual != null:
			_sanct_visual.queue_free()
			_sanct_visual = null
	if rate <= 0.0 or is_dead or health >= max_health:
		_regen_acc = 0.0
		return
	_regen_acc += rate * (1.0 + stats.total("heal_mult")) * delta
	if _regen_acc >= 0.5:
		_restore(_regen_acc)
		_regen_acc = 0.0


func cooldown_left(id: String) -> float:
	return _cooldowns.get(id, 0.0)


## Full cooldown of a skill after cooldown reduction.
func cooldown_total(id: String) -> float:
	return SkillData.SKILLS[id]["cooldown"] * (1.0 - stats.total("cdr"))


## True when the skill is usable: reached its level, or learned in the talent tree.
func knows_skill(id: String) -> bool:
	if not SkillData.SKILLS.has(id):
		return false
	if SkillData.is_talent_skill(id):
		return int(talents.get(SkillData.SKILLS[id]["talent"], 0)) > 0
	return level >= SkillData.SKILLS[id]["level"]


func potion_cooldown() -> float:
	return _potion_cooldown


## Seconds left of a buff: "power", "speed" or "guard".
func buff_time(id: String) -> float:
	match id:
		"power":
			return _power_time
		"speed":
			return _speed_time
		"guard":
			return _guard_time
		"frenzy":
			return _frenzy_time
		"shout":
			return _shout_time
		"wall":
			return _wall_time
	return 0.0


func _damage_mult() -> float:
	var m := 1.0
	if _power_time > 0.0:
		m *= 1.6
	if _frenzy_time > 0.0:
		m *= 1.25
	return m


func use_slot(i: int) -> void:
	if i < 0 or i >= bar.size() or is_dead or busy:
		return
	var entry := bar[i]
	if entry == "":
		return
	if SkillData.is_item(entry):
		use_consumable(SkillData.item_id(entry))
	else:
		use_skill(entry)


func assign_slot(index: int, entry: String, from_index: int = -1) -> void:
	if index < 0 or index >= bar.size():
		return
	if from_index >= 0 and from_index < bar.size():
		bar[from_index] = bar[index]   # dragging from another slot swaps the two
	else:
		for j in bar.size():
			if bar[j] == entry:
				bar[j] = ""            # a skill sits on the bar only once
	bar[index] = entry
	bar_changed.emit()


func clear_slot(index: int) -> void:
	if index >= 0 and index < bar.size():
		bar[index] = ""
		bar_changed.emit()


## Uses a skill if it is unlocked and ready. Returns true if it fired.
const SKILL_SOUNDS := {
	"power_strike": "skill_heavy", "whirlwind": "skill_whirl", "guard": "skill_shield", "prayer": "skill_blessing",
	"charge": "skill_dash", "taunt": "skill_shout", "wall": "skill_wall", "frenzy": "skill_frenzy",
	"leap": "skill_dash", "flame": "skill_flame", "sanctuary": "skill_holy_circle",
}


func use_skill(id: String) -> bool:
	if is_dead or busy or _stun > 0.0 or not SkillData.SKILLS.has(id):
		return false
	var def: Dictionary = SkillData.SKILLS[id]
	if not knows_skill(id):
		if SkillData.is_talent_skill(id):
			message.emit(Strings.SKILL_NEEDS_TALENT)
		else:
			message.emit(Strings.SKILL_LOCKED % def["level"])
		return false
	if cooldown_left(id) > 0.0:
		return false
	var melee := id == "power_strike" or id == "whirlwind" or id == "charge" or id == "leap"
	if melee and (_attacking or not is_on_floor() or _blocking):
		return false
	_cooldowns[id] = cooldown_total(id)
	Sfx.play(SKILL_SOUNDS.get(id, "skill_heavy"), global_position)
	match id:
		"power_strike":
			_start_attack("power_strike")
		"whirlwind":
			_attacking = true
			_play("2H_Melee_Attack_Spin" if _anim and _anim.has_animation("2H_Melee_Attack_Spin") else "1H_Melee_Attack_Slice_Horizontal", 0.05, true)
			var serial := _attack_serial_next()
			get_tree().create_timer(0.4).timeout.connect(_whirl_hits.bind(serial, sword_damage * 1.4))
			get_tree().create_timer(0.95).timeout.connect(_end_skill_attack.bind(serial))
			_ring_effect(Color(0.85, 0.92, 1.0), 4.6 + stats.total("whirl_radius"), 0.45, 0.5)
		"guard":
			_guard_time = 5.0 + stats.total("guard_time_add")
			_ensure_guard_visual()
			message.emit(Strings.MSG_GUARD)
			_ring_effect(Color(0.45, 0.7, 1.0), 2.4, 0.5, 0.2)
		"prayer":
			var amount := max_health * (0.4 + stats.total("prayer_add")) * (1.0 + stats.total("heal_mult"))
			health = minf(health + amount, max_health)
			health_changed.emit(health, max_health)
			message.emit(Strings.MSG_PRAYER % int(amount))
			_ring_effect(Color(1.0, 0.92, 0.45), 3.0, 0.8, 0.2)
			if _anim and _anim.has_animation("Cheer"):
				_special_time = 0.9
				_play("Cheer", 0.1, true)
		"charge":
			_dash_dir = _facing()
			_dash_time = 0.28
			_dash_hit.clear()
			_attacking = true
			_invulnerable = maxf(_invulnerable, 0.4)
			_play("1H_Melee_Attack_Stab", 0.05, true)
			_ring_effect(Color(1.0, 0.75, 0.55), 2.6, 0.4, 0.2)
		# --- skills from the talent tree (talent_data.gd)
		"taunt":
			_shout_time = 6.0
			for e in get_tree().get_nodes_in_group("enemies"):
				if global_position.distance_to((e as Enemy).global_position) <= 9.0:
					(e as Enemy).stun(2.0)
			message.emit(Strings.MSG_TAUNT)
			_ring_effect(Color(0.5, 0.75, 1.0), 9.0, 0.55, 0.3)
			_cheer()
		"wall":
			_wall_time = 3.0
			_invulnerable = maxf(_invulnerable, 3.0)
			_ensure_guard_visual()
			message.emit(Strings.MSG_WALL)
			_ring_effect(Color(0.6, 0.85, 1.0), 3.0, 0.5, 0.2)
		"frenzy":
			_frenzy_time = 8.0
			message.emit(Strings.MSG_FRENZY)
			_ring_effect(Color(1.0, 0.3, 0.25), 3.2, 0.5, 0.2)
			_cheer()
		"leap":
			_dash_dir = _facing()
			_leap_time = 0.85
			_leaping = true
			_leap_clock = 0.0
			_attacking = true
			_invulnerable = maxf(_invulnerable, 0.3)
			velocity.y = 9.0
			_play("Jump_Idle", 0.05, true)
			_ring_effect(Color(1.0, 0.8, 0.3), 2.2, 0.3, 0.1)
		"flame":
			var dealt := 0.0
			var flame_damage := sword_damage * 2.2
			for e in get_tree().get_nodes_in_group("enemies"):
				var enemy := e as Enemy
				if global_position.distance_to(enemy.global_position) <= 7.0:
					_hit(enemy, flame_damage, 8.0)
					dealt += flame_damage * _damage_mult()
			_hit_breakables(flame_damage, 7.0)
			var gain := minf(dealt * 0.25, max_health * 0.3) * (1.0 + stats.total("heal_mult"))
			_restore(gain)
			message.emit(Strings.MSG_FLAME % int(gain))
			_ring_effect(Color(1.0, 0.85, 0.4), 7.0, 0.6, 0.3)
			_cheer()
		"sanctuary":
			_sanct_time = 8.0
			_sanct_pos = global_position
			_spawn_sanctuary_visual()
			message.emit(Strings.MSG_SANCTUARY)
			_ring_effect(Color(1.0, 0.92, 0.5), 5.0, 0.6, 0.1)
	return true


func _cheer() -> void:
	if _anim and _anim.has_animation("Cheer"):
		_special_time = 0.9
		_play("Cheer", 0.1, true)


## The leap has landed: a shockwave that hits and stuns everyone close.
func _leap_slam() -> void:
	var serial := _attack_serial_next()
	_attacking = true
	_play("1H_Melee_Attack_Chop", 0.05, true)
	Sfx.play("skill_lightning", global_position)
	get_tree().create_timer(0.5).timeout.connect(_end_skill_attack.bind(serial))
	_ring_effect(Color(1.0, 0.8, 0.3), 5.0, 0.4, 0.1)
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if global_position.distance_to(enemy.global_position) <= 4.5:
			_hit(enemy, sword_damage * 2.0, 10.0, 1.2)
	_hit_breakables(sword_damage * 2.0, 4.5)


func _spawn_sanctuary_visual() -> void:
	if _sanct_visual != null:
		_sanct_visual.queue_free()
	_sanct_visual = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 5.0
	disc.bottom_radius = 5.0
	disc.height = 0.06
	_sanct_visual.mesh = disc
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.9, 0.45, 0.13)
	_sanct_visual.material_override = mat
	_sanct_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(_sanct_visual)
	_sanct_visual.global_position = _sanct_pos + Vector3.UP * 0.08


## The spin animation is long; George is free again after the swing itself.
func _end_skill_attack(serial: int) -> void:
	if serial == _attack_serial:
		_attacking = false


## The spin attack: every enemy around George, in every direction.
func _whirl_hits(serial: int, damage: float) -> void:
	if serial != _attack_serial or not _attacking or is_dead:
		return
	var radius := 4.6 + stats.total("whirl_radius")
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		var to_enemy := enemy.global_position - global_position
		to_enemy.y = 0.0
		if to_enemy.length() <= radius:
			_hit(enemy, damage, 9.0)
	_hit_breakables(damage, radius)


## While dashing: hit and stun every enemy George runs into (once each).
func _dash_hits() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy in _dash_hit:
			continue
		var to_enemy := enemy.global_position - global_position
		to_enemy.y = 0.0
		if to_enemy.length() <= 2.8:
			_dash_hit.append(enemy)
			_hit(enemy, sword_damage * 1.2, 9.0, 1.2)


func _ensure_guard_visual() -> void:
	if _guard_visual != null:
		return
	_guard_visual = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.35
	sphere.height = 2.7
	_guard_visual.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.4, 0.65, 1.0, 0.22)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.55, 1.0)
	mat.emission_energy_multiplier = 0.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_guard_visual.material_override = mat
	_guard_visual.position.y = 1.0
	_guard_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_guard_visual)


## A flat glowing ring that expands around George (skill feedback).
func _ring_effect(color: Color, final_radius: float, duration: float, start_height: float) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(color.r, color.g, color.b, 0.9)
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(0, start_height, 0)
	ring.scale = Vector3.ONE * 0.4
	add_child(ring)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * final_radius, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	tween.chain().tween_callback(ring.queue_free)


# ------------------------------------------------------------- interaction ----
# Anything in the group "interactables" (NPCs, chests, doors) offers:
#   interact_prompt() -> String   (empty = not usable right now)
#   interact_range() -> float
#   interact(player)

func _update_interaction() -> void:
	var best: Node = null
	var best_dist := INF
	if not busy and not is_dead:
		for n in get_tree().get_nodes_in_group("interactables"):
			var node := n as Node3D
			if node == null or not node.is_visible_in_tree():
				continue
			var d := global_position.distance_to(node.global_position)
			if d < node.call("interact_range") and d < best_dist and node.call("interact_prompt") != "":
				best = node
				best_dist = d
	_interactable = best
	var text := "" if best == null else str(best.call("interact_prompt"))
	if text != _last_prompt:
		_last_prompt = text
		prompt_changed.emit(text)
	if best != null and Input.is_action_just_pressed("interact"):
		best.call("interact", self)


## Moves George somewhere instantly (doors) and points him and the camera along `heading`.
func teleport(pos: Vector3, heading: float) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_heading = heading
	_model_root.rotation.y = heading
	_yaw = heading + PI
	_rig.global_position = pos + Vector3.UP * camera_height


func _announce() -> void:
	health_changed.emit(health, max_health)
	xp_changed.emit(level, xp, xp_needed())
	inventory_changed.emit(gold, potions)


func _die() -> void:
	is_dead = true
	_attacking = false
	_blocking = false
	_play("Death_A", 0.05, true)
	Sfx.play("player_death", global_position)
	died.emit()
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)


func _respawn() -> void:
	global_position = _spawn_point
	velocity = Vector3.ZERO
	health = max_health
	is_dead = false
	_stun = 0.0
	_invulnerable = 2.0
	_play("Idle", 0.2, true)
	Sfx.ui("heal")
	health_changed.emit(health, max_health)
	respawned.emit()


func _update_animation() -> void:
	if _anim == null or _attacking or _landing or is_dead or _stun > 0.0 or _special_time > 0.0:
		return
	if not is_on_floor():
		# Jump_Start plays on the way up; switch to the looping air pose when it ends or we start falling.
		if velocity.y < 0.5 or not _anim.is_playing():
			_play("Jump_Idle", 0.15)
		return
	if _blocking:
		_play("Blocking", 0.1)
		return
	var h_speed := Vector2(velocity.x, velocity.z).length()
	if h_speed > walk_speed + 0.5:
		_play("Running_A", 0.15)
	elif h_speed > 0.3:
		_play("Walking_A", 0.15)
	else:
		_play("Idle", 0.2)


func _play(anim_name: String, blend: float = 0.15, restart: bool = false) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	if not restart and _anim.current_animation == anim_name and _anim.is_playing():
		return
	_anim.play(anim_name, blend)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name in COMBO or anim_name == &"1H_Melee_Attack_Chop" or anim_name == &"2H_Melee_Attack_Spin" or anim_name == &"2H_Melee_Attack_Spinning":
		_attacking = false
	elif anim_name == &"Jump_Land":
		_landing = false
