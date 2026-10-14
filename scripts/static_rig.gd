class_name StaticRig
extends Node
## The body language of a creature made from props (a pumpkin, a tree, a boulder, a chest: no skeleton, no
## AnimationPlayer), made in code. An Enemy with `static_mob` owns one and calls it: tick() every physics frame,
## start_attack(), hurt(), die(), wake(). It only moves the Enemy's model root (height, scale, tilt, a small lunge),
## never the body, so collisions and the navigation grid are not affected.
## Spec: docs/superpowers/specs/2026-10-14-more-mobs-design.md

const SQUASH_LIMIT := 0.3

var model: Node3D                       # the Enemy's model root: its y rotation (facing) belongs to the Enemy
var base_scale := Vector3.ONE           # the creature's size (Enemy.model_scale)
var hop_height := 0.0                   # 0 = no hopping gait
var hop_rate := 2.4                     # hops per second when running
var sway := 0.0                         # radians of rocking for rooted or standing creatures
var lid: Node3D                         # the lid of a mimic, flapped while it chases and bites
var rise := 1.0                         # 0.55 asleep (squashed) .. 1 awake

var _t := randf() * 10.0
var _phase := 0.0
var _attack_t := -1.0                   # seconds since the attack began, -1 = none
var _attack_hit := 0.5
var _shake := 0.0
var _dead := false
var _rise_tween: Tween


func setup(model_root: Node3D, size: float, hop: float, rate: float, rock: float) -> void:
	model = model_root
	base_scale = Vector3.ONE * size
	hop_height = hop
	hop_rate = rate
	sway = rock
	lid = model_root.find_child("*_lid", true, false) as Node3D


## Every physics frame. `speed01`: how fast the creature is moving (0 still, 1 full chase speed).
func tick(delta: float, speed01: float, dormant: bool) -> void:
	if _dead or model == null:
		return
	_t += delta
	var squash := 0.0
	var y := 0.0
	var tilt_z := 0.0
	var tilt_x := 0.0
	var forward := 0.0
	var flap := 0.0
	if dormant:
		squash = 0.0
		rise = 0.55
	elif _attack_t >= 0.0:
		_attack_t += delta
		var u := clampf(_attack_t / maxf(_attack_hit, 0.05), 0.0, 1.0)
		if _attack_t < _attack_hit:
			squash = 0.22 * u * u                       # crouching to spring
			flap = 1.0 * u                              # the lid opens wide
			tilt_x = -0.18 * u
		else:
			var after := _attack_t - _attack_hit
			var snap := clampf(1.0 - after / 0.28, 0.0, 1.0)
			squash = -0.18 * snap                       # stretched out
			forward = 0.55 * snap
			tilt_x = 0.3 * snap
			flap = 1.0 - clampf(after / 0.12, 0.0, 1.0)  # the lid snaps shut
			if after > 0.45:
				squash = 0.0
	else:
		if hop_height > 0.0 and speed01 > 0.08:
			_phase += delta * hop_rate * (0.55 + 0.9 * speed01)
			var arc := absf(sin(_phase * PI))
			y = arc * hop_height
			squash = 0.16 * (1.0 - arc) - 0.06 * arc    # squashed on landing, stretched in the air
			flap = 0.45 + 0.35 * sin(_phase * TAU * 2.0)
		else:
			squash = 0.02 * sin(_t * 2.1)               # breathing
		if sway > 0.0:
			tilt_z = sway * sin(_t * (1.6 + speed01))
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 2.4, 0.0)
		tilt_z += sin(_t * 46.0) * 0.16 * _shake
	squash = clampf(squash, -SQUASH_LIMIT, SQUASH_LIMIT)
	model.position = Vector3(0.0, y, forward)
	model.scale = Vector3(base_scale.x * (1.0 + squash * 0.5), base_scale.y * rise * (1.0 - squash), base_scale.z * (1.0 + squash * 0.5))
	model.rotation.x = tilt_x
	model.rotation.z = tilt_z
	if lid != null:
		lid.rotation.x = deg_to_rad(-70.0) * clampf(flap, 0.0, 1.0)


## The blow lands `hit_time` seconds after this call (the crouch lasts until then).
func start_attack(hit_time: float) -> void:
	_attack_t = 0.0
	_attack_hit = hit_time


func end_attack() -> void:
	_attack_t = -1.0


func hurt() -> void:
	_shake = 1.0


## A sleeping creature stands up over 0.8 s (golem) with a shudder.
func wake() -> void:
	_shake = 1.0
	if _rise_tween != null:
		_rise_tween.kill()
	_rise_tween = model.create_tween()
	_rise_tween.tween_property(self, "rise", 1.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The model shrinks and falls over in 0.6 s; the Enemy sinks the body afterwards.
func die() -> void:
	_dead = true
	var tween := model.create_tween().set_parallel(true)
	tween.tween_property(model, "scale", base_scale * 0.05, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(model, "rotation:z", 1.3, 0.6)
	tween.tween_property(model, "position:y", 0.0, 0.3)
	if lid != null:
		tween.tween_property(lid, "rotation:x", deg_to_rad(-80.0), 0.2)
