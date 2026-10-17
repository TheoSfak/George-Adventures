class_name VillageCow
extends CharacterBody3D
## Friendly pasture cow with full 3D skeletal animations (Idle, Eating, Walk).
## Grazes in the farm paddocks of Agios Vlasis.

var _model: Node3D
var _anim: AnimationPlayer
var _idle_timer := 4.0 + randf() * 5.0
var _eating := false


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("animals")
	collision_layer = 16
	collision_mask = 1

	var scene := load("res://assets/animals/Cow.glb") as PackedScene
	if scene:
		_model = scene.instantiate() as Node3D
		_model.scale = Vector3.ONE * 0.45
		add_child(_model)
		_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if _anim:
			_anim.play("AnimalArmature|Idle")

	# Add physical collider matching natural cow proportions
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 2.0, 3.4)
	col.shape = box
	col.position = Vector3(0.0, 1.0, 0.0)
	add_child(col)


func _physics_process(delta: float) -> void:
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_idle_timer = 5.0 + randf() * 7.0
		_eating = not _eating
		if _anim:
			var anim_name := "AnimalArmature|Eating" if _eating else "AnimalArmature|Idle"
			if _anim.has_animation(anim_name):
				_anim.play(anim_name, 0.4)


func interact_range() -> float:
	return 3.8


func interact_prompt() -> String:
	return "Χάιδεψε την αγελάδα"


func interact(player: Player) -> void:
	if player:
		player.message.emit("Η αγελάδα μασάει νωχελικά το γρασίδι και σε κοιτάζει ήρεμα.")
		Sfx.play("dog_whimper", global_position, -3.0, 0.6)  # gentle low friendly sound

