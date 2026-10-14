extends SceneTree
## Counts the static colliders of the village (what a navigation grid has to read):
##   godot --path . --headless --script tools/nav_probe.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var village := get_first_node_in_group("village")
	if village == null:
		village = main.get_node("Village")
	var kinds := {}
	var bodies := 0
	var layers := {}
	var ymin := 1e9
	var ymax := -1e9
	var tall := 0
	for body in village.find_children("*", "StaticBody3D", true, false):
		bodies += 1
		layers[(body as StaticBody3D).collision_layer] = int(layers.get((body as StaticBody3D).collision_layer, 0)) + 1
		for c in body.get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape != null:
				var k: String = (c as CollisionShape3D).shape.get_class()
				kinds[k] = int(kinds.get(k, 0)) + 1
	print("static bodies under Village: ", bodies)
	print("shape kinds: ", kinds)
	print("collision layers: ", layers)
	var non_static := {}
	for n in village.find_children("*", "CollisionObject3D", true, false):
		if not (n is StaticBody3D):
			non_static[n.get_class()] = int(non_static.get(n.get_class(), 0)) + 1
	print("other collision objects: ", non_static)
	quit(0)
