class_name Horse
extends Node3D
## The riding horse: the Quaternius "Farm Animals Animated" horse (CC0, assets/animals/Horse.fbx),
## sized to a believable length, standing on y = 0 with its nose toward +Z (like the KayKit
## characters), with Idle / Walk / Run / Jump picked by the speed the rider gives it.

const MODEL := "res://assets/animals/Horse.fbx"
const TARGET_LENGTH := 2.5          # nose to tail in metres after scaling
const SEAT_HEIGHT := 1.35           # how high George's model sits above the ground while riding (tuned by eye in mountshot)
const FACING_FLIP := false          # true if the model's head points toward -Z
const WALK_MAX := 11.0              # up to this speed (m/s) the horse walks, above it it runs

var length_m := 0.0
var height_m := 0.0

var _model: Node3D
var _anim: AnimationPlayer
var _names := {}                    # kind ("idle", "walk", "run", "jump") -> animation name in the model
var _kind := ""
var _standing := false


func _ready() -> void:
	_model = (load(MODEL) as PackedScene).instantiate() as Node3D
	add_child(_model)
	var raw := _box()
	# the longest horizontal side is nose to tail: turn the model so that it lies along Z
	if raw.size.x > raw.size.z:
		_model.rotation.y = PI / 2.0
	if FACING_FLIP:
		_model.rotation.y += PI
	var rotated := _box()
	var s := TARGET_LENGTH / maxf(rotated.size.z, 0.01)
	_model.scale = Vector3.ONE * s
	var fitted := _box()
	# feet on the ground, centred on x and z
	_model.position -= Vector3(fitted.get_center().x, fitted.position.y, fitted.get_center().z)
	var final := _box()
	length_m = final.size.z
	height_m = final.size.y
	_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim != null:
		for kind in ["idle", "walk", "run", "jump"]:
			_names[kind] = _find(kind)
		for kind in ["idle", "walk", "run"]:
			if _names[kind] != "":
				_anim.get_animation(_names[kind]).loop_mode = Animation.LOOP_LINEAR
	_play("idle")


## The model's mesh box in this node's own frame.
func _box() -> AABB:
	var inv := global_transform.affine_inverse()
	var box := AABB()
	var have := false
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (inv * (mi as MeshInstance3D).global_transform) * (mi as MeshInstance3D).get_aabb()
		box = a if not have else box.merge(a)
		have = true
	return box


func feet_y() -> float:
	return _box().position.y


## The animation of this kind ("" when the model has none). The match is by the end of the name,
## so "Armature|Run" and "Run" both work, and "Walk" does not match "WalkSlow".
func animation_for(kind: String) -> String:
	return _names.get(kind, "")


func current_kind() -> String:
	return _kind


func _find(kind: String) -> String:
	for n in _anim.get_animation_list():
		if String(n).to_lower().ends_with(kind):
			return String(n)
	return ""


## The rider's horizontal speed and whether he is on the ground.
func set_motion(speed: float, on_floor: bool) -> void:
	if _standing or _anim == null:
		return
	if not on_floor and _names.get("jump", "") != "":
		_play("jump")
	elif speed < 0.3:
		_play("idle")
	elif speed <= WALK_MAX:
		_play("walk")
		_anim.speed_scale = clampf(speed / 9.0, 0.8, 1.4)
	else:
		_play("run")
		_anim.speed_scale = clampf(speed / 16.0, 0.8, 1.3)


## For the stable: idle forever, whatever the rider does.
func stand() -> void:
	_standing = true
	_play("idle")


func _play(kind: String) -> void:
	if _anim == null or _kind == kind:
		return
	var anim_name: String = _names.get(kind, "")
	if anim_name == "":
		return
	_kind = kind
	if kind == "idle":
		_anim.speed_scale = 1.0
	_anim.play(anim_name, 0.2)
