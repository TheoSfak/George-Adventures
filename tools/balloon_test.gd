extends SceneTree
## Four balloons drift over the lake, one is moored on the entry island:
##   godot --path . --headless --script tools/balloon_test.gd
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
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var balloons := get_nodes_in_group("balloons")
	check("five balloons (%d)" % balloons.size(), balloons.size() == 5)
	var drifting: Array = []
	var moored: Node3D = null
	for b in balloons:
		if b.moored:
			moored = b
		else:
			drifting.append(b)
	check("four drifting and one moored", drifting.size() == 4 and moored != null)
	if moored == null or drifting.size() != 4:
		quit(1)
		return
	var before := {}
	for b in drifting:
		before[b] = (b as Node3D).global_position
	var moored_before := moored.global_position
	await create_timer(3.0).timeout
	var moved := true
	var high := true
	var clear_of_tree := true
	for b in drifting:
		var p := (b as Node3D).global_position
		if p.distance_to(before[b]) < 0.5:
			moved = false
		if p.y < 25.0 or p.y > 45.0:
			high = false
		if Vector2(p.x - 176.0, p.z - (-41.0)).length() < 26.0:
			clear_of_tree = false
	check("they drift (every one moved at least 0.5 m in 3 s)", moved)
	check("they float between 25 and 45 m above the lake", high)
	check("and keep clear of the canopy (26 m or more from the tree axis)", clear_of_tree)
	check("the moored balloon stays put on the entry island (y %.1f)" % moored.global_position.y, moored.global_position.distance_to(moored_before) < 0.01 and absf(moored.global_position.y - 3.0) < 0.05)
	var mi := (drifting[0] as Node3D).get_child(0) as MeshInstance3D
	check("a balloon is one mesh with the shared vertex-colour material", mi != null and mi.material_override == TreeMeshes.material())
	quit(1 if failed else 0)
