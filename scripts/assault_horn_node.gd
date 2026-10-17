extends Node3D
## Interactive assault horn at the staging post outside the Orc Stronghold.

func interact_prompt() -> String:
	var parent := get_parent()
	if parent != null and parent.get("siege_active") == true:
		return "Η Έφοδος είναι σε εξέλιξη!"
	return "[R] Σάλπισμα Εφόδου Φρουρών"

func interact_range() -> float:
	return 3.5

func interact(player: Player) -> void:
	var parent := get_parent()
	if parent != null and parent.has_method("start_assault"):
		parent.call("start_assault", player)
