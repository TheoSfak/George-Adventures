class_name Chest
extends Node3D
## A treasure chest. Press R next to it: the lid opens and gold (maybe a potion) pops out.
## Set the contents before adding it to the scene.

const WOOD := "res://assets/items/chest.glb"
const GOLDEN := "res://assets/items/chest_gold.glb"

var golden := false
var gold_min := 5
var gold_max := 15
var potions := 0
var opened := false

var _lid: Node3D


func _ready() -> void:
	add_to_group("interactables")
	var visual := Node3D.new()
	visual.scale = Vector3.ONE * 0.8
	add_child(visual)
	var model := (load(GOLDEN if golden else WOOD) as PackedScene).instantiate() as Node3D
	visual.add_child(model)
	_lid = model.find_child("*_lid", true, false) as Node3D

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 0.9, 1.1)
	shape.shape = box
	shape.position = Vector3(0, 0.45, 0)
	body.add_child(shape)
	add_child(body)


func interact_prompt() -> String:
	return "" if opened else Strings.PROMPT_OPEN


func interact_range() -> float:
	return 3.2


func interact(_player: Player) -> void:
	if opened:
		return
	opened = true
	Sfx.play("chest_open", global_position)
	if _lid:
		# The lid hinges at the back of the chest: tilt it up and open.
		create_tween().tween_property(_lid, "rotation:x", deg_to_rad(-115.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.35).timeout
	Sfx.play("chest_coins", global_position)
	var parent := get_parent()
	var amount := randi_range(gold_min, gold_max)
	var pieces := clampi(amount / 5 + 1, 1, 4)
	for i in pieces:
		var share := amount / pieces + (1 if i < amount % pieces else 0)
		_drop(Pickup.make("gold", share), parent)
	if potions > 0:
		_drop(Pickup.make("potion", potions), parent)
	# chests sometimes hold a buff potion, golden ones more often
	if randf() < (0.75 if golden else 0.35):
		_drop(Pickup.make(["power_potion", "speed_potion"][randi() % 2], 1), parent)


func _drop(pickup: Pickup, parent: Node) -> void:
	# Parents (the world's "Chests" node and every room) sit at the origin, so local = global.
	pickup.position = global_position + Vector3(0, 1.0, 0)
	parent.add_child(pickup)
