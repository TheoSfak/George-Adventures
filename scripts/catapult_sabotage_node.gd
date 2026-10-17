extends Node3D
## Interactive catapult sabotage spot in the ruined fortress.

var is_sabotaged := false

func interact_prompt() -> String:
	if is_sabotaged:
		return ""
	return "[R] Δολιοφθορά Καταπέλτη Όρκ"

func interact_range() -> float:
	return 4.0

func interact(player: Player) -> void:
	if is_sabotaged:
		return
	is_sabotaged = true
	var parent := get_parent()
	if parent != null and parent.has_method("sabotage_catapult"):
		parent.call("sabotage_catapult", player)
