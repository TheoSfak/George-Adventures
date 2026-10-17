extends StaticBody3D
## Warband Blood Totem interactive node.
## Can be struck with melee/arrows or interacted with [R] to destroy it.

var health := 85.0
var max_health := 85.0
var is_destroyed := false

func interact_prompt() -> String:
	if is_destroyed:
		return ""
	return "[R] Καταστροφή Τοτέμ Όρκ"

func interact_range() -> float:
	return 3.5

func interact(player: Player) -> void:
	if is_destroyed:
		return
	destroy_totem()

func take_damage(amount: float, _from: Vector3, _knock: float = 0.0) -> void:
	if is_destroyed:
		return
	health -= amount
	# Brief red flash
	var light := find_child("*", true, false)
	if light is OmniLight3D:
		(light as OmniLight3D).light_energy = 4.0
	if health <= 0.0:
		destroy_totem()

func destroy_totem() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	collision_layer = 0
	collision_mask = 0
	remove_from_group("breakables")
	remove_from_group("interactables")
	Sfx.play("explosion", global_position if is_inside_tree() else position)

	var parent := get_parent()
	if parent != null and parent.has_method("on_totem_destroyed"):
		parent.call("on_totem_destroyed", self)

	var tween := create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector3(1.2, 0.1, 1.2), 0.35).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_callback(queue_free)
	else:
		queue_free()
