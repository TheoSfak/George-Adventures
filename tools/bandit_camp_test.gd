extends SceneTree
## The hideout and the bandits in the world: camp pieces, chest, creatures, a fight:
##   godot --path . --headless --script tools/bandit_camp_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _bandits() -> Array:
	return get_nodes_in_group("enemies").filter(func(e): return String(e.kind_id).begins_with("bandit") and not e.is_dead())


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var camp := main.get_node("Village").get_node_or_null("BanditCamp")
	check("the camp exists", camp != null)
	var tents := 0                              # duplicate names become "@Node3D@N", so count the ring 14 m from the centre
	for c in camp.get_children():
		if c is Node3D and not c is OmniLight3D and Vector2(c.position.x + 140.0, c.position.z + 90.0).length() > 12.0 and Vector2(c.position.x + 140.0, c.position.z + 90.0).length() < 16.0:
			tents += 1
	check("five tents in a ring around the fire", tents == 5)
	check("a fire lights at night", camp.get_children().any(func(c): return c is OmniLight3D and c.is_in_group("night_lights")))
	var centre := Vector3(-140.0, 0.0, -90.0)
	var chest = null
	for c in get_nodes_in_group("chests"):
		if c.global_position.distance_to(Vector3(-135, 0, -95)) < 1.0:
			chest = c
	check("a golden chest stands in the camp", chest != null and chest.golden and chest.gold_min == 150)

	var inside := _bandits().filter(func(e): return e.global_position.distance_to(centre) < 30.0)
	check("seven bandits in the camp (chief, 3 thugs, 2 archers, a thief)", inside.size() == 7)
	check("one of them is the chief", inside.any(func(e): return e.kind_id == "bandit_chief"))
	check("twelve patrol pairs and camp: 13 bandits in all", _bandits().size() == 13)
	var skeletons_near := get_nodes_in_group("enemies").filter(func(e): return not String(e.kind_id).begins_with("bandit") and e.global_position.distance_to(centre) < 40.0)
	check("no skeleton lives near the hideout", skeletons_near.is_empty())

	# a fight: a lone thug on the east road goes for George
	p.max_health = 1000.0
	p.health = 1000.0
	var thug = _bandits().filter(func(e): return e.kind_id == "bandit_thug" and e.global_position.distance_to(Vector3(140, 0, 10)) < 8.0)[0]
	var archer = _bandits().filter(func(e): return e.kind_id == "bandit_archer" and e.global_position.distance_to(Vector3(143, 0, 12)) < 8.0)[0]
	p.teleport(thug.global_position + Vector3(9, 0.05, 0), PI / 2.0)
	await create_timer(5.0).timeout
	check("the bandits noticed George and came or shot", thug.global_position.distance_to(p.global_position) < 7.0 or p.health < 1000.0)
	check("George was hurt by a human blow or arrow", p.health < 1000.0)
	thug.take_damage(9999.0, thug.global_position + Vector3.RIGHT)
	archer.take_damage(9999.0, archer.global_position + Vector3.RIGHT)
	await create_timer(0.3).timeout
	check("they can be killed", thug.is_dead() and archer.is_dead())
	quit(1 if failed else 0)
