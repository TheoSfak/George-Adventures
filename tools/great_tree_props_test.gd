extends SceneTree
## The tree, houses, props, lights and the chest of the Great Tree area:
##   godot --path . --headless --script tools/great_tree_props_test.gd
var failed := false
var gt


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	gt = load("res://scripts/great_tree.gd")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var area := main.get_node_or_null("Village/GreatTree")
	if area == null:
		check("the GreatTree node exists", false)
		quit(1)
		return

	# --- the tree
	var tree := area.get_node_or_null("Tree") as MeshInstance3D
	check("the great tree stands on the plateau (%s)" % (str(tree.position) if tree != null else "missing"), tree != null and tree.position.is_equal_approx(gt.TREE_POS))
	check("its trunk has a collider", area.get_node_or_null("TreeTrunk") != null)
	# a capsule walking at the trunk stops before it
	var body := CharacterBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 1
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	body.add_child(shape)
	root.add_child(body)
	var trunk_world: Vector3 = gt.to_world(gt.TREE_POS)
	body.global_position = trunk_world + Vector3(7.0, 0.3, 0.0)
	for i in 150:
		await physics_frame
		var dir := Vector3(trunk_world.x - body.global_position.x, 0.0, trunk_world.z - body.global_position.z).normalized()
		body.velocity = Vector3(dir.x * 5.0, body.velocity.y - 22.0 / 60.0, dir.z * 5.0)
		body.move_and_slide()
	var dist := Vector2(body.global_position.x - trunk_world.x, body.global_position.z - trunk_world.z).length()
	check("a walker is stopped by the trunk (%.1f m from its axis, y %.1f)" % [dist, body.global_position.y], dist > 3.0 and dist < 5.0 and body.global_position.y > 6.5)
	body.queue_free()

	# --- houses, deck, lanterns
	for i in 2:
		var house := area.get_node_or_null("House_%d" % i) as Node3D
		check("house %d stands on the plateau and has a collider" % i, house != null and absf(house.position.y - 7.0) < 0.05 and house.find_children("*", "StaticBody3D", true, false).size() > 0)
	check("the deck ring around the trunk", area.get_node_or_null("DeckRing") != null)
	check("lantern posts and glowing heads", area.get_node_or_null("LanternPosts") != null and area.get_node_or_null("LanternHeads") != null)
	var heads := area.get_node("LanternHeads") as MeshInstance3D
	var mat := heads.material_override as StandardMaterial3D
	check("the lantern heads glow (emissive material)", mat != null and mat.emission_enabled)

	# --- lights: at most three real lights in the whole area
	var lights := 0
	for l in get_nodes_in_group("night_lights"):
		var p := (l as Node3D).global_position
		if Vector2(p.x - 172.0, p.z + 40.0).length() < 44.0:
			lights += 1
	check("exactly three night lights in the area (found %d)" % lights, lights == 3)

	# --- umbrella trees, bench, flowers, pads, dressing
	var umbrellas := 0
	for c in area.get_children():
		if str(c.name).begins_with("Umbrella_") and c is MeshInstance3D:
			umbrellas += 1
	check("six umbrella trees (%d)" % umbrellas, umbrellas == 6)
	check("a bench", area.get_node_or_null("Bench") != null)
	var flowers := 0
	for c in area.get_children():
		if str(c.name).begins_with("Flowers_"):
			flowers += 1
	check("flowers on every island (%d)" % flowers, flowers == 5)
	check("lily pads on the lake", area.get_node_or_null("LilyPads") != null)
	var dressing := area.get_node_or_null("Dressing")
	check("rocks and trees around the shore (%d)" % (dressing.get_child_count() if dressing != null else 0), dressing != null and dressing.get_child_count() >= 14)

	# --- the chest on the south island
	var found: Node3D = null
	for c in get_nodes_in_group("chests"):
		var p := (c as Node3D).global_position
		if p.y > 4.5 and Vector2(p.x - 172.0, p.z + 40.0).length() < 44.0:
			found = c
	check("a chest on the south island at its height", found != null and absf(found.global_position.y - float(gt.CHEST_POS.y)) < 0.05)
	if found != null:
		check("it is golden, closed and can be opened with R", found.golden and not found.opened and found.interact_prompt() != "")

	# --- the budget: draw calls and triangles stay small
	var meshes := area.find_children("*", "MeshInstance3D", true, false)
	var tris := 0
	for m in meshes:
		tris += ((m as MeshInstance3D).mesh.get_faces().size() / 3)
	check("%d meshes (under 90) and %d triangles (under 90000)" % [meshes.size(), tris], meshes.size() < 90 and tris < 90000)
	quit(1 if failed else 0)
