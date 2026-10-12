extends SceneTree
## Villagers go home at dusk and return at dawn:  godot --path . --resolution 1280x720 --script tools/shelter.gd
func _initialize() -> void:
	_run()
func hidden() -> String:
	var n := 0
	var talk := 0
	var all := get_nodes_in_group("villagers")
	for v in all:
		if not v.visible: n += 1
		if v.is_in_group("interactables"): talk += 1
	return "%d/%d hidden, %d talkable" % [n, all.size(), talk]
func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.0).timeout
	for e in get_nodes_in_group("enemies"): e.queue_free()
	var dn := get_first_node_in_group("daynight")
	dn.day_length_seconds = 120.0   # 1 hour = 5 s
	dn.set_time(19.3)
	print("day:   ", hidden())
	await create_timer(12.0).timeout
	print("dusk/night (t=", snappedf(dn.time_of_day, 0.1), "): ", hidden())
	dn.set_time(5.3)
	await create_timer(12.0).timeout
	print("dawn/day (t=", snappedf(dn.time_of_day, 0.1), "): ", hidden())
	quit()
