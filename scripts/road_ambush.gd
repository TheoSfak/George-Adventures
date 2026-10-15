class_name RoadAmbush
extends Node
## Dynamic roadside encounters: at night, if George travels the forest trails or wilderness,
## a sudden bandit ambush can spring from the trees once per night, complete with alert
## sound, banner, and combat!

var _last_ambush_day := -1
var _check_timer := 3.0


func _ready() -> void:
	name = "RoadAmbush"


func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = 2.5

	var tree := get_tree()
	if tree == null:
		return

	var daynight: DayNight = tree.get_first_node_in_group("daynight") as DayNight
	if daynight == null or daynight.darkness() < 0.62:
		return

	if _last_ambush_day == daynight.day_count:
		return

	var invasion = tree.get_first_node_in_group("invasion")
	if invasion != null and invasion.get("active") == true:
		return

	var interiors = tree.get_first_node_in_group("interiors")
	if interiors != null and (interiors.call("is_inside") or interiors.call("in_region")):
		return

	var player := tree.get_first_node_in_group("player") as CharacterBody3D
	if player == null or player.get("is_dead") == true:
		return

	var flat := Vector2(player.global_position.x, player.global_position.z)
	var dist := flat.length()

	# Only in the wilderness / trails (outside the village lights, between 75m and 150m)
	if dist < 75.0 or dist > 150.0:
		return

	# Trigger ambush!
	_last_ambush_day = daynight.day_count
	_trigger_ambush(player)


func _trigger_ambush(player: CharacterBody3D) -> void:
	var enemies := get_tree().get_first_node_in_group("enemies") as Node
	if enemies == null:
		return

	Sfx.ui("rescue_alert")
	get_tree().call_group("hud", "show_banner", "⚠️ Ενέδρα Ληστών στο μονοπάτι!", 3.5)

	var p_pos := player.global_position
	var facing := -player.transform.basis.z.normalized()
	facing.y = 0.0
	if facing.length() < 0.1:
		facing = Vector3(1, 0, 0)

	var side := Vector3(-facing.z, 0.0, facing.x)
	var kinds := ["bandit_thug", "bandit_thief"]

	for i in kinds.size():
		var offset := facing * 12.0 + side * ((-4.0) if i == 0 else 4.0)
		var spawn_pos := p_pos + offset
		spawn_pos.y = 0.0

		if enemies.has_method("spawn_extra"):
			var e: Enemy = enemies.call("spawn_extra", kinds[i], spawn_pos) as Enemy
			if e != null:
				e.aggro_range = 35.0
				e.gold_min += 25
				e.gold_max += 40
				e.potion_chance = 1.0
				# Aggro player immediately
				e.set("_target", player)
				e.set("_state", 2)  # CHASE
