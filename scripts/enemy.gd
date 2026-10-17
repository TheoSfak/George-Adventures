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
@export var human := false            # a person (bandit) instead of a skeleton: other sounds, only `show_nodes` props visible
@export var show_nodes: Array = []                               # props of an Adventurers model that stay visible (CharacterProps)
@export var walk_anim := "Walking_D_Skeletons"                    # humans walk with "Walking_A"
@export var idle_anim := "Idle"
@export var run_anim := "Running_A"
@export var hit_anim := ""
@export var death_anim := ""
@export_group("Props")                # creatures made from props (no skeleton, no AnimationPlayer): body language in static_rig.gd
@export var static_mob := false
@export var parts: Array = []         # [{"path", "pos", "scale", "yaw"}] built under the model root when model_path is ""
@export var hop_height := 0.0         # a hopping gait (metres), 0 = none
@export var hop_rate := 2.4
@export var sway := 0.0               # radians of rocking (rooted creatures, a sleeping pile)
@export var static_attack_time := 1.0 # seconds from the start of a swing until it is over (no animation to end it)
@export var dormant := false          # stands as a prop until George comes close or hurts it
@export var wake_range := 6.0
@export var wake_spawn := ""          # a dormant creature that bursts into helpers of this kind instead of standing up
@export var wake_count := 3
@export var wake_text := ""
@export var sound_set := "bone"       # bone / stone / wood / squish / mimic: which sounds it makes (see SOUND_SETS)
@export var glow_color := Color(0, 0, 0, 0)   # alpha 0 = no light; otherwise a small light on the creature (pumpkins)
@export var stomp_slow := 0.0         # seconds a landed blow slows George down (the golem's stomp)
@export var steals_gold := 0          # gold stolen from George on a melee hit
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
@export_group("Dungeon")
@export var need_los := false         # only notices George with a clear line (walls hide him), gives up after a while
@export var summon_kind := ""         # bosses that call helpers while fighting
@export var summon_interval := 14.0
@export var summon_max := 4
@export var enrage_below := 0.0       # health share (0..1) below which a boss enrages
@export var enrage_summon := ""       # helper kind an enraged boss starts calling
@export var projectile_slows := false # its shots slow George down
@export_group("Invasion")
@export var invader := false          # marches on the village well until it meets George
@export var march_target := Vector3.ZERO

enum State { PATROL, MARCH, CHASE, ATTACK, HURT, DEAD, DORMANT }

const LOOPED: Array[String] = ["Idle", "Walking_D_Skeletons", "Running_A", "Running_B", "Walking_Backwards"]
const ATTACKS: Array[String] = ["1H_Melee_Attack_Chop", "1H_Melee_Attack_Slice_Horizontal"]
const HITS: Array[String] = ["Hit_A", "Hit_B"]
const HEALTH_BAR_SIZE := Vector2i(96, 12)       # drawn at double resolution (pixel_size is halved)
## The sound a creature makes for each of the skeleton's sounds (attack, hurt, death, aggro cry).
const SOUND_SETS := {
	"stone": {"skel_attack": "stone_hit", "skel_hurt": "stone_hit", "skel_death": "stone_death", "skel_aggro": "brute_roar"},
	"wood": {"skel_attack": "wood_hit", "skel_hurt": "wood_hit", "skel_death": "wood_death", "skel_aggro": "brute_roar"},
	"squish": {"skel_attack": "squish_hit", "skel_hurt": "squish_hit", "skel_death": "squish_death", "skel_aggro": "skel_aggro"},
	"mimic": {"skel_attack": "mimic_snap", "skel_hurt": "wood_hit", "skel_death": "wood_death", "skel_aggro": "mimic_snap"},
	"scarecrow": {"skel_attack": "wood_hit", "skel_hurt": "scarecrow_groan", "skel_death": "wood_death", "skel_aggro": "scarecrow_groan"},
	"orc": {"skel_attack": "sword_swing", "skel_hurt": "boss_roar", "skel_death": "brute_roar", "skel_aggro": "brute_roar"},
	"wolf": {"skel_attack": "dog_bark", "skel_hurt": "dog_whimper", "skel_death": "dog_whimper", "skel_aggro": "dog_bark"},
	"spider": {"skel_attack": "squish_hit", "skel_hurt": "squish_hit", "skel_death": "squish_death", "skel_aggro": "mimic_snap"},
}

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
var _detour_dir := Vector3.ZERO
var _nav := NavFollower.new()          # walks around houses and trees on the region's NavGrid (nav_grid.gd)
var _lost_time := 0.0                 # chasing without a line of sight (dungeon enemies)
var _summon_timer := 5.0
var _summons: Array[Enemy] = []
var _enraged := false
var besiege_target: Node3D = null     # rescue event: hits the air in front of this victim until George shows up
var _besiege_swing := 0.0
var _rig: StaticRig                   # the body language of a static creature
var _tag: Label3D                     # the name above its head (hidden while it sleeps)


func _ready() -> void:
	health = max_health
	_model_root.scale = Vector3.ONE * model_scale
	var body_shape := $CollisionShape3D as CollisionShape3D
	body_shape.scale = Vector3.ONE * model_scale
	body_shape.position.y = 0.85 * model_scale
	_home = global_position
	_patrol_target = _home
	_patrol_wait = randf_range(0.5, 3.0)
	floor_stop_on_slope = true
	floor_constant_speed = true
	floor_max_angle = 0.959931
	floor_snap_length = 0.35
	add_to_group("enemies")
	if invader:
		add_to_group("invaders")
		_state = State.MARCH
	if dormant:
		_state = State.DORMANT
	_load_model()
	_build_health_bar()


func _load_model() -> void:
	var model: Node3D
	if static_mob and model_path == "":
		model = Node3D.new()                     # a creature put together from several props
		for part in parts:
			if part.has("eye"):                      # a glowing eye: {"eye": radius, "pos", "color"}
				model.add_child(_make_eye(part))
				continue
			var piece := (load(part["path"]) as PackedScene).instantiate() as Node3D
			piece.position = part.get("pos", Vector3.ZERO)
			var piece_scale = part.get("scale", 1.0)             # a number, or a Vector3 to stretch a rock
			piece.scale = piece_scale if piece_scale is Vector3 else Vector3.ONE * float(piece_scale)
			piece.rotation.y = deg_to_rad(float(part.get("yaw", 0.0)))
			model.add_child(piece)
	else:
		model = (load(model_path) as PackedScene).instantiate() as Node3D
	_model_root.add_child(model)
	_model_root.rotation.y = randf() * TAU
	if glow_color.a > 0.0:
		var light := OmniLight3D.new()
		light.light_color = Color(glow_color.r, glow_color.g, glow_color.b)
		light.light_energy = glow_color.a * 2.0
		light.omni_range = 6.0
		light.position = Vector3(0.0, 0.8, 0.0)
		_model_root.add_child(light)

	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton:
		_attach(skeleton, "handslot.r", weapon_path)
		_attach(skeleton, "handslot.l", offhand_path)

	if human:
		CharacterProps.apply(model, show_nodes)
	if tint_color.a > 0.0:
		_apply_tint(model, tint_color)

	if static_mob:
		_rig = StaticRig.new()
		add_child(_rig)
		_rig.setup(_model_root, model_scale, hop_height, hop_rate, sway)
		if dormant:
			_rig.rise = 0.55
		return
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null:
		push_warning("Enemy: no AnimationPlayer in %s" % model_path)
		return
	var looped: Array = LOOPED.duplicate()
	looped.append(walk_anim)
	for anim_name in looped:
		if _anim.has_animation(anim_name):
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	_anim.animation_finished.connect(_on_animation_finished)
	_play("Idle")


func _make_eye(part: Dictionary) -> MeshInstance3D:
	var eye := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = float(part["eye"])
	sphere.height = sphere.radius * 2.0
	eye.mesh = sphere
	var mat := StandardMaterial3D.new()
	var color: Color = part.get("color", Color(1.0, 0.5, 0.1))
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye.material_override = mat
	eye.position = part.get("pos", Vector3.ZERO)
	return eye


func _attach(skeleton: Skeleton3D, bone: String, path: String) -> void:
	if path.is_empty() or skeleton.find_bone(bone) < 0:
		return
	var holder := BoneAttachment3D.new()
	holder.bone_name = bone
	skeleton.add_child(holder)
	holder.add_child((load(path) as PackedScene).instantiate())


## A colour wash over every mesh of the model (the colour of the creature's kind).
func _apply_tint(model: Node3D, color: Color) -> void:
	var wash := StandardMaterial3D.new()
	wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wash.albedo_color = color
	wash.cull_mode = BaseMaterial3D.CULL_BACK
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = wash


func _build_health_bar() -> void:
	_bar = Sprite3D.new()
	_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bar.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_bar.shaded = false
	_bar.no_depth_test = false
	_bar.position = Vector3(0.0, 2.35 * model_scale, 0.0)
	_bar.pixel_size = 0.014 * maxf(1.0, model_scale * 0.8)
	_bar.visible = display_name != "" and not dormant      # a sleeping boulder must not give itself away
	add_child(_bar)
	_update_health_bar()
	if display_name != "":
		var tag := Label3D.new()
		_tag = tag
		tag.visible = not dormant
		tag.text = display_name
		tag.font_size = 48
		tag.pixel_size = 0.0085 * maxf(1.0, model_scale * 0.8)
		tag.outline_size = 16
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.modulate = Color(1.0, 0.45, 0.35)
		tag.position = Vector3(0.0, 2.35 * model_scale + 0.55 * maxf(1.0, model_scale * 0.8), 0.0)
		tag.no_depth_test = false
		add_child(tag)


func _update_health_bar() -> void:
	_bar.texture = FancyBar.texture(HEALTH_BAR_SIZE.x, HEALTH_BAR_SIZE.y, clampf(health / max_health, 0.0, 1.0),
			Color(1.0, 0.50, 0.44), Color(0.74, 0.10, 0.14))


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
		State.DORMANT:
			_dormant()
		State.HURT:
			_hurt_timer -= delta
			if _hurt_timer <= 0.0:
				_set_state(State.CHASE if _player_alive() else _idle_state())

	if summon_kind != "" and (_state == State.CHASE or _state == State.ATTACK):
		_summon_timer -= delta
		if _summon_timer <= 0.0:
			_summon_timer = summon_interval
			_summon()

	# Knockback and stagger decay, normal movement accelerates toward its goal.
	var accel := 30.0 if _state != State.HURT else 8.0
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)
	move_and_slide()
	_check_blocked(target_velocity, delta)
	if _rig != null:
		var real := get_real_velocity()
		_rig.tick(delta, 0.0 if chase_speed <= 0.01 else clampf(Vector2(real.x, real.z).length() / chase_speed, 0.0, 1.0), _state == State.DORMANT)


## Skeletons have no navigation mesh: if one pushes against a wall or tree without
## getting anywhere it sidesteps along the obstacle tangent, which smoothly guides it around.
func _check_blocked(target_velocity: Vector3, delta: float) -> void:
	if _detour_time > 0.0:
		_detour_time -= delta
		if _detour_time <= 0.0:
			_detour_dir = Vector3.ZERO
		return
	var want := Vector2(target_velocity.x, target_velocity.z).length()
	var real := get_real_velocity()
	var got := Vector2(real.x, real.z).length()
	if want > 0.5 and (got < want * 0.25 or is_on_wall()):
		_blocked_time += delta
		if _blocked_time > 0.35:
			_detour_time = 1.1
			var want_dir := Vector3(target_velocity.x, 0.0, target_velocity.z).normalized()
			if is_on_wall():
				var n := get_wall_normal()
				n.y = 0.0
				if n.length_squared() > 0.01:
					n = n.normalized()
					var tangent := Vector3(-n.z, 0.0, n.x)
					# Choose the tangent direction closest to our intended movement
					if want_dir.dot(tangent) < 0.0:
						tangent = -tangent
					_detour_dir = (tangent + n * 0.25).normalized()
					# Micro-unstuck nudge away from concave corners if held for longer
					if _blocked_time > 0.75:
						global_position += n * 0.12
				else:
					_detour_sign = -1.0 if randf() < 0.5 else 1.0
					_detour_dir = want_dir.rotated(Vector3.UP, deg_to_rad(65.0) * _detour_sign)
			else:
				_detour_sign = -1.0 if randf() < 0.5 else 1.0
				_detour_dir = want_dir.rotated(Vector3.UP, deg_to_rad(65.0) * _detour_sign)
			_blocked_time = 0.0
	else:
		_blocked_time = 0.0


func _detour(dir: Vector3) -> Vector3:
	if _detour_time > 0.0:
		if _detour_dir != Vector3.ZERO:
			return _detour_dir
		return dir.rotated(Vector3.UP, deg_to_rad(65.0) * _detour_sign)
	return dir


## The flat direction toward `target`: straight while the way is free, otherwise along a path around the obstacles
## (NavFollower). `_nav.active` says that the path is being followed.
func _path_dir(target: Vector3) -> Vector3:
	if chase_speed <= 0.01 and patrol_speed <= 0.01:       # a rooted creature (the haunted tree) never walks: no path to find
		return _flat(target - global_position).normalized()
	return _nav.direction(global_position, target, NavGrid.clearance_for(0.4 * model_scale), get_physics_process_delta_time())


func _idle_state() -> State:
	return State.MARCH if invader else State.PATROL


## A sleeping creature (boulder, pile of bones) waits until George is near.
func _dormant() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	if _player_alive() and global_position.distance_to(_player.global_position) <= wake_range:
		_wake()


## It stands up and fights, or (with `wake_spawn`) bursts into helpers and is gone.
func _wake() -> void:
	if _state != State.DORMANT:
		return
	if wake_text != "":
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.message.emit(wake_text)
	if wake_spawn != "":
		Sfx.play("skel_aggro", global_position)
		var spawner := get_parent()
		if spawner != null and spawner.has_method("spawn_summon"):
			var first := randf() * TAU
			for i in wake_count:
				var a := first + TAU * float(i) / float(wake_count)
				spawner.spawn_summon(wake_spawn, global_position + Vector3(cos(a), 0.0, sin(a)) * 1.8, null)
		_set_state(State.CHASE)
		_die(Vector3.ZERO)
		return
	Sfx.play(_voice("skel_aggro"), global_position)
	if _rig != null:
		_rig.wake()
	if _tag != null:
		_tag.visible = true
		_bar.visible = true
	_set_state(State.CHASE)
	_cooldown = 0.9


func _patrol(delta: float) -> Vector3:
	if _can_see_player():
		_set_state(State.CHASE)
		_aggro_sound()
		return Vector3.ZERO
	if besiege_target != null and is_instance_valid(besiege_target):
		return _besiege(delta)
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
	var dir := _detour(_path_dir(_patrol_target))
	_face(dir, delta)
	_play(walk_anim, 0.2)
	return dir * patrol_speed


## A skeleton of the ring around a victim (the rescue event): it hits the air in front of the
## target until George comes into view. rescue.gd drains the victim's health.
func is_besieging() -> bool:
	return _state == State.PATROL and besiege_target != null and is_instance_valid(besiege_target)


func _besiege(delta: float) -> Vector3:
	var to_target := _flat(besiege_target.global_position - global_position)
	_face(to_target, delta)
	if to_target.length() > 5.5:                    # pulled away by a chase: walk back to the ring
		_play(walk_anim, 0.2)
		var back := _detour(_path_dir(besiege_target.global_position))
		if _nav.active:
			_face(back, delta)
		return back * patrol_speed
	_besiege_swing -= delta
	if _cooldown <= 0.0:
		_cooldown = attack_cooldown * randf_range(0.9, 1.4)
		_besiege_swing = 0.9
		_play(shoot_anim if ranged else (attack_anim if attack_anim != "" else ATTACKS.pick_random()), 0.08, true)
		if not ranged:
			Sfx.play(_voice("skel_attack"), global_position)
	elif _besiege_swing <= 0.0:
		_play("Idle", 0.2)
	return Vector3.ZERO


## Night invaders run for the well in the middle of the village.
func _march(delta: float) -> Vector3:
	if _can_see_player():
		_set_state(State.CHASE)
		_aggro_sound()
		return Vector3.ZERO
	var to_target := _flat(march_target - global_position)
	if to_target.length() < 6.0:
		_play("Idle", 0.2)   # they have arrived and are tearing at the village
		return Vector3.ZERO
	var dir := _detour(_path_dir(march_target))
	_face(dir, delta)
	_play("Running_A", 0.15)
	return dir * chase_speed * 0.85


## The cry when a skeleton first notices George.
func _aggro_sound() -> void:
	match kind_id:
		"brute":
			Sfx.play("brute_roar", global_position)
		"captain", "king", "giant_skeleton", "malakar", "night_lord", "bandit_chief", "pyrforos":
			Sfx.play("boss_roar", global_position)
		"warlord":
			Sfx.play("warlord_roar", global_position)
		_:
			if not human:
				Sfx.play(_voice("skel_aggro"), global_position, -4.0)


func _chase() -> Vector3:
	if not _player_alive():
		_set_state(_idle_state())
		return Vector3.ZERO
	var to_player := _flat(_player.global_position - global_position)
	var dist := to_player.length()
	var delta := get_physics_process_delta_time()
	if dist > leash_range:
		_set_state(_idle_state())
		_patrol_target = _home
		return Vector3.ZERO
	if need_los:
		if _has_line_of_sight():
			_lost_time = 0.0
		else:
			_lost_time += delta
			if _lost_time > 4.0:         # lost him behind the walls: back to the post
				_lost_time = 0.0
				_set_state(_idle_state())
				_patrol_target = _home
				return Vector3.ZERO
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
	var dir := _detour(_path_dir(_player.global_position))
	if _nav.active:
		_face(dir, delta)       # running around an obstacle: look where he runs
	return dir * chase_speed


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
		var dir := _detour(_path_dir(_player.global_position))
		if _nav.active:
			_face(dir, _delta)
		return dir * chase_speed
	_play("Idle", 0.15)
	if _cooldown <= 0.0:
		_start_attack()
	return Vector3.ZERO


func _start_attack() -> void:
	_set_state(State.ATTACK)
	if not ranged:
		Sfx.play(_voice("skel_attack"), global_position)
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
	if _rig != null:
		_rig.start_attack(_hit_time)


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
				_player.take_damage(scaled_damage(), global_position)
				if stomp_slow > 0.0:
					_player.slow(stomp_slow)
				if steals_gold > 0 and _player.gold > 0:
					var stolen: int = mini(steals_gold, _player.gold)
					_player.gold -= stolen
					_player.inventory_changed.emit(_player.gold, _player.potions)
					_player.message.emit(Strings.MSG_GOLD_STOLEN % stolen)
					Sfx.ui("gold_pickup")
	if _rig != null and _attack_timer >= static_attack_time:      # nothing animated ends the swing of a prop: a timer does
		_rig.end_attack()
		_cooldown = attack_cooldown
		_set_state(State.CHASE if _player_alive() else _idle_state())


func _fire() -> void:
	if not _player_alive() or get_parent() == null:
		return
	var forward := Vector3(sin(_model_root.rotation.y), 0.0, cos(_model_root.rotation.y))
	var muzzle := global_position + Vector3.UP * 1.3 * model_scale + forward * 0.7
	var aim := _player.global_position + Vector3.UP * 1.0 - muzzle
	if projectile_kind == "arrow":
		aim = aim.rotated(Vector3.UP, randf_range(-0.05, 0.05))   # archers are not perfect
	Sfx.play("arrow_shoot" if projectile_kind == "arrow" else "orb_cast", global_position)
	var shot := Projectile.make(projectile_kind, muzzle, aim, projectile_speed, scaled_damage())
	shot.slows = projectile_slows
	get_parent().add_child(shot)


func take_damage(amount: float, from: Vector3, knock: float = 5.0) -> void:
	if _state == State.DEAD:
		return
	if _state == State.DORMANT:               # a blow wakes a sleeper (a heap of bones then bursts and is gone)
		_wake()
		if _state == State.DEAD:
			return
	health -= amount / LevelScaling.health_mult(player_level())   # above level 20 the world is tougher (level_scaling.gd)
	if _bar != null:
		_bar.visible = true
		_update_health_bar()
	var away := _flat(global_position - from)
	if away.length() < 0.01:
		away = Vector3.BACK
	away = away.normalized()
	if health <= 0.0:
		_die(away)
		return
	if enrage_below > 0.0 and not _enraged and health / max_health <= enrage_below:
		_enrage()
	Sfx.play(_voice("skel_hurt"), global_position)
	_set_state(State.HURT)
	_hurt_timer = 0.45
	_cooldown = maxf(_cooldown, 0.5)
	velocity.x = away.x * knock
	velocity.z = away.z * knock
	_play(HITS.pick_random(), 0.05, true)
	if _rig != null:
		_rig.hurt()


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
	remove_from_group("besiegers")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	_bar.visible = false
	Sfx.play(_voice("skel_death"), global_position)
	if _rig != null:
		_rig.die()
	else:
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
	remove_from_group("besiegers")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	_bar.visible = false
	if _rig != null:
		_rig.die()
	else:
		_play("Death_A", 0.05, true)
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(self, "position:y", position.y - 2.5, 1.2)
	tween.tween_callback(queue_free)


func _set_state(s: State) -> void:
	_state = s


func is_dead() -> bool:
	return _state == State.DEAD


## Asleep as a boulder or a heap of bones: the minimap must not give it away.
func is_dormant() -> bool:
	return _state == State.DORMANT


func _can_see_player() -> bool:
	if not _player_alive() or global_position.distance_to(_player.global_position) > aggro_range:
		return false
	return not need_los or _has_line_of_sight()


## True when no wall (collision layer 1) stands between this skeleton and George.
func _has_line_of_sight() -> bool:
	var from := global_position + Vector3.UP * 1.2 * model_scale
	var to := _player.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## The second phase of a boss: faster, hits more often, glows redder and starts calling helpers.
func _enrage() -> void:
	_enraged = true
	chase_speed *= 1.25
	attack_cooldown *= 0.7
	if enrage_summon != "":
		summon_kind = enrage_summon
		_summon_timer = 0.5
	_apply_tint(_model_root, Color(0.85, 0.12, 0.20, 0.42))
	Sfx.play("boss_roar", global_position)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		match kind_id:
			"night_lord":
				player.message.emit(Strings.NIGHT_LORD_ENRAGE)
			"bandit_chief":
				player.message.emit(Strings.BANDIT_CHIEF_ENRAGE)
			"pyrforos":
				player.message.emit(Strings.PYRFOROS_ENRAGE)
			_:
				player.message.emit(Strings.MALAKAR_ENRAGE)


## Calls two helpers from the parent spawner (the necromancer's minions).
func _summon() -> void:
	_summons = _summons.filter(func(e): return is_instance_valid(e) and not e.is_dead())
	var spawner := get_parent()
	if spawner == null or not spawner.has_method("spawn_summon"):
		return
	Sfx.play("orb_cast", global_position)
	for i in 2:
		if _summons.size() >= summon_max:
			return
		var angle := randf() * TAU
		var helper = spawner.spawn_summon(summon_kind, global_position + Vector3(cos(angle), 0.0, sin(angle)) * 3.0, self)
		if helper:
			_summons.append(helper)


## A human is hurt and dies with a human voice, swings a sword instead of rattling bones.
func _voice(skeleton_sound: String) -> String:
	if SOUND_SETS.has(sound_set):
		return SOUND_SETS[sound_set].get(skeleton_sound, skeleton_sound)
	if not human:
		return skeleton_sound
	return "sword_swing" if skeleton_sound == "skel_attack" else "player_hurt"


## George's level (1 when he is not in the tree yet): the enemies scale with it above level 20.
func player_level() -> int:
	var p := _player
	if p == null:
		var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree != null:
			p = tree.get_first_node_in_group("player") as Player
	return p.level if p != null else 1


## The damage of one blow, arrow or orb, scaled by George's level.
func scaled_damage() -> float:
	return attack_damage * LevelScaling.damage_mult(player_level())


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
	if _anim == null:
		return
	var resolved := anim_name
	if not _anim.has_animation(resolved):
		if anim_name == "Idle" and idle_anim != "":
			resolved = idle_anim
		elif anim_name == "Running_A" and run_anim != "":
			resolved = run_anim
		elif (anim_name == "Walking_D_Skeletons" or anim_name == "Walking_A") and walk_anim != "":
			resolved = walk_anim
		elif (anim_name == "Death_A" or anim_name == "Death_B") and death_anim != "":
			resolved = death_anim
		elif anim_name in HITS and hit_anim != "":
			resolved = hit_anim
		elif anim_name in ATTACKS and attack_anim != "":
			resolved = attack_anim
	if not _anim.has_animation(resolved):
		return
	if not restart and _anim.current_animation == resolved and _anim.is_playing():
		return
	_anim.play(resolved, blend)


func _on_animation_finished(anim_name: StringName) -> void:
	if _state == State.ATTACK and String(anim_name) == _current_attack:
		_cooldown = attack_cooldown
		_set_state(State.CHASE if _player_alive() else _idle_state())
