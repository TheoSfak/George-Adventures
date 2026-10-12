class_name InteractSpot
extends Node3D
## An invisible "press R here" spot (doors etc.). The player's interaction system
## (player.gd) finds it through the group "interactables".

var label := ""
var radius := 3.5
var action := Callable()
var prompt_func := Callable()   # optional: builds the prompt text each time (for changing prices)


static func make(text: String, callback: Callable, range_m: float = 3.5) -> InteractSpot:
	var s := InteractSpot.new()
	s.label = text
	s.action = callback
	s.radius = range_m
	return s


func _ready() -> void:
	add_to_group("interactables")


func interact_prompt() -> String:
	if prompt_func.is_valid():
		return prompt_func.call()
	return label


func interact_range() -> float:
	return radius


func interact(player: Player) -> void:
	if action.is_valid():
		action.call(player)
