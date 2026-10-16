class_name VillageDeer
extends CharacterBody3D
## Wild graceful deer with full 3D skeletal animations.
## Roams the quiet meadows and highland forest glades of Agios Vlasis.

var _model: Node3D
var _anim: AnimationPlayer
var _cycle_timer := 3.5 + randf() * 4.0
var _grazing := false


func _ready() -> void:
	add_to_group("animals")
	collision_layer = 16
	collision_mask = 1

	var scene := load("res://assets/animals/Deer.glb") as PackedScene
	if scene:
		_model = scene.instantiate() as Node3D
		_model.scale = Vector3.ONE * 0.28
		add_child(_model)
		_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if _anim:
			_anim.play("AnimalArmature|Idle")

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 1.2, 1.2)
	col.shape = box
	col.position = Vector3(0.0, 0.6, 0.0)
	add_child(col)


func _physics_process(delta: float) -> void:
	_cycle_timer -= delta
	if _cycle_timer <= 0.0:
		_cycle_timer = 4.0 + randf() * 6.0
		_grazing = not _grazing
		if _anim:
			var anim_name := "AnimalArmature|Eating" if _grazing else "AnimalArmature|Idle"
			if _anim.has_animation(anim_name):
				_anim.play(anim_name, 0.35)
