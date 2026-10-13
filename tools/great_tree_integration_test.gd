extends SceneTree
## The Great Tree area fits the rest of the map: nothing in its way, signpost, map label, sounds, scatter:
##   godot --path . --headless --script tools/great_tree_integration_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	# --- the data moved out of the lake (read from the source: the scripts mention autoloads)
	var village_src := FileAccess.get_file_as_string("res://scripts/village.gd")
	check("the quest barrel moved to (124, -26)", village_src.contains('["keg", 124.0, -26.0]') and not village_src.contains('["keg", 143.0, -29.0]'))
	var enemies_src := FileAccess.get_file_as_string("res://scripts/enemies.gd")
	check("its two skeleton spawns moved with it", enemies_src.contains('["minion", 112.0, -22.0]') and enemies_src.contains('["warrior", 110.0, -38.0]') and not enemies_src.contains('["minion", 138.0, -22.0]'))
	check("the signpost is in the village data", village_src.contains("Το Μεγάλο Δέντρο  →"))
	var mini_src := FileAccess.get_file_as_string("res://scripts/minimap.gd")
	check("the big map names the place", mini_src.contains('["bigtree", 172.0, -40.0]') and Strings.MAP_PLACES.has("bigtree") and Strings.MAP_PLACES["bigtree"] == "Η Λίμνη του Αιωνόβιου")
	var sound_src := FileAccess.get_file_as_string("res://scripts/sound_manager.gd")
	check("two positional loops at the lake", sound_src.contains('"water_loop", Vector3(GreatTree.CENTER.x') and sound_src.contains('"wind_loop", Vector3(GreatTree.CENTER.x'))

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var village := main.get_node("Village")
	# --- no skeletons in or next to the area
	var close := 0
	for e in get_nodes_in_group("enemies"):
		var p := (e as Node3D).global_position
		if Vector2(p.x - 172.0, p.z + 40.0).length() < 44.0:
			close += 1
	check("no skeleton starts within 44 m of the lake centre (%d)" % close, close == 0)
	# --- nothing scattered inside the area
	var inside := true
	for a in 16:
		var ang := TAU * float(a) / 16.0
		for r in [5.0, 20.0, 38.0, 43.0]:
			if not village._is_occupied(172.0 + cos(ang) * r, -40.0 + sin(ang) * r, 0.5):
				inside = false
	check("the whole area is registered as occupied (no grass, forests or rocks scattered in it)", inside)
	check("but the village side is free again further out", not village._is_occupied(172.0 - 70.0, -40.0, 0.5))
	# --- the signpost exists as a 3D label near (112, -44)
	var sign_found := false
	for l in village.find_children("*", "Label3D", true, false):
		var lab := l as Label3D
		if lab.text.contains("Μεγάλο Δέντρο") and Vector2(lab.global_position.x - 112.0, lab.global_position.z + 44.0).length() < 6.0:
			sign_found = true
	check("the signpost 'Το Μεγάλο Δέντρο' stands near (112, -44)", sign_found)
	# --- the sound manager made the loops
	var sm = get_first_node_in_group("sound_manager")
	var loops := 0
	for n in sm.get_children():
		if n is AudioStreamPlayer3D and Vector2(n.global_position.x - 172.0, n.global_position.z + 40.0).length() < 1.0:
			loops += 1
	check("the sound manager has two loops at the lake (%d)" % loops, loops == 2)
	quit(1 if failed else 0)
