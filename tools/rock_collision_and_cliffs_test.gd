extends SceneTree
## Test driver for v1.16.1: Rock Collision Boundaries & South-East Sea Cliffs

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(desc: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS: %s" % desc)
	else:
		failed += 1
		printerr("  FAIL: %s" % desc)

func _run() -> void:
	# Ensure autoloads or mocks exist
	if not root.has_node("Quests"):
		var quests_node = load("res://scripts/quests.gd").new()
		quests_node.name = "Quests"
		root.add_child(quests_node)

	print("--- Running Rock Collision & Sea Cliffs Test Suite ---")

	# 1. Village Rock Collisions
	print("\n[1] Testing Village Rock Colliders...")
	var village_gd = load("res://scripts/village.gd") as GDScript
	var v: Node3D = village_gd.new()
	root.add_child(v)
	v._ready()

	# Quarry rocks
	var quarry: Node3D = v.get_node_or_null("Quarry")
	check("Village has Quarry node", quarry != null)
	if quarry:
		var quarry_rocks := 0
		var min_height: float = 999.0
		for child in quarry.get_children():
			if child.name.contains("rock_single") or child.name.contains("resource_stone"):
				var sb_list = child.find_children("*", "StaticBody3D", true, false)
				if sb_list.size() > 0:
					quarry_rocks += 1
					var cs: CollisionShape3D = sb_list[0].get_child(0) as CollisionShape3D
					if cs and cs.shape is BoxShape3D:
						var bs: BoxShape3D = cs.shape
						min_height = minf(min_height, bs.size.y)
		check("Quarry rocks & props have dedicated colliders (found >= 15)", quarry_rocks >= 15)
		check("Quarry rock colliders have full protective height (>= 2.2m)", min_height >= 2.2)

	# Pond rocks
	var pond_rocks_node: Node3D = v.get_node_or_null("PondRocks")
	check("Village has PondRocks node", pond_rocks_node != null)
	if pond_rocks_node:
		var pond_rocks_count := 0
		var pond_rock_min_h: float = 999.0
		for child in pond_rocks_node.get_children():
			var sb_list = child.find_children("*", "StaticBody3D", true, false)
			if sb_list.size() > 0:
				pond_rocks_count += 1
				var cs: CollisionShape3D = sb_list[0].get_child(0) as CollisionShape3D
				if cs and cs.shape is BoxShape3D:
					var bs: BoxShape3D = cs.shape
					pond_rock_min_h = minf(pond_rock_min_h, bs.size.y)
		check("Pond rocks have colliders (found >= 5)", pond_rocks_count >= 5)
		check("Pond rock collider height is at least 2.2m", pond_rock_min_h >= 2.2)

	# Scatter rocks
	var scatter_rocks := 0
	var scatter_unshrunk := true
	for child in v.find_children("Visual", "Node3D", true, false):
		var p_node: Node = child.get_parent()
		if p_node and p_node != quarry and p_node.get_parent() != pond_rocks_node:
			if p_node.name.contains("rock_single"):
				var sb_list = p_node.find_children("*", "StaticBody3D", false, false)
				if sb_list.size() > 0:
					scatter_rocks += 1
					var cs: CollisionShape3D = sb_list[0].get_child(0) as CollisionShape3D
					if cs and cs.shape is BoxShape3D:
						var bs: BoxShape3D = cs.shape
						if bs.size.y < 2.2:
							scatter_unshrunk = false
	check("Scatter rocks have colliders across island (found >= 30)", scatter_rocks >= 30)
	check("Scatter rock colliders maintain protective height >= 2.2m", scatter_unshrunk)

	v.queue_free()

	# 2. Great Tree Rock Collisions
	print("\n[2] Testing Great Tree Rock Colliders...")
	var gt_gd = load("res://scripts/great_tree.gd") as GDScript
	var gt: Node3D = gt_gd.new()
	root.add_child(gt)
	gt._ready()
	var gt_rocks := 0
	var gt_rock_min_h: float = 999.0
	for child in gt.find_children("rock_single*", "Node3D", true, false):
		var sb_list = child.find_children("*", "StaticBody3D", false, false)
		if sb_list.size() > 0:
			gt_rocks += 1
			var cs: CollisionShape3D = sb_list[0].get_child(0) as CollisionShape3D
			if cs and cs.shape is BoxShape3D:
				var bs: BoxShape3D = cs.shape
				gt_rock_min_h = minf(gt_rock_min_h, bs.size.y)
	check("Great Tree lake shore rocks have colliders (found >= 5)", gt_rocks >= 5)
	check("Great Tree rock colliders have protective height >= 2.2m", gt_rock_min_h >= 2.2)
	gt.queue_free()

	# 3. South Sea Beach Rocks & South-East Sea Cliffs
	print("\n[3] Testing South-East Sea Cliffs & Beach Rocks...")
	var sea_gd = load("res://scripts/island_south_sea.gd") as GDScript
	var sea: Node3D = sea_gd.new()
	root.add_child(sea)
	sea._ready()

	# Beach rocks
	var beach: Node3D = sea.get_node_or_null("Beach")
	check("Beach node exists", beach != null)
	if beach:
		var beach_rock_models := 0
		var beach_rock_colliders := 0
		for child in beach.get_children():
			if child.name.begins_with("rock_single"):
				beach_rock_models += 1
				var sbs = child.find_children("*", "StaticBody3D", false, false)
				if sbs.size() > 0:
					beach_rock_colliders += 1
		check("Beach rocks use true KayKit rock models (>= 10)", beach_rock_models >= 10)
		check("Beach rocks all have static body colliders (>= 10)", beach_rock_colliders >= 10)

	# South-East Sea Cliffs
	var cliffs: Node3D = sea.get_node_or_null("SoutheastCliffs")
	check("SoutheastCliffs node exists", cliffs != null)
	if cliffs:
		var cliff_bodies := 0
		var sea_stacks := 0
		var cliff_trees := 0
		var signpost_found := false
		var bench_found := false

		for child in cliffs.get_children():
			if child is StaticBody3D:
				cliff_bodies += 1
			elif child.name.begins_with("rock_single") or child.name.begins_with("mountain_"):
				sea_stacks += 1
				var sbs = child.find_children("*", "StaticBody3D", false, false)
				check("Sea stack '%s' has rock collider" % child.name, sbs.size() > 0)
			elif child.name.begins_with("tree_") or child.name.begins_with("trees_"):
				cliff_trees += 1
			elif child.name.contains("bench"):
				bench_found = true
			elif child.find_children("*", "Label3D", true, false).size() > 0:
				signpost_found = true

		check("Promontory cliff tiers & stairs bodies exist (>= 12)", cliff_bodies >= 12)
		check("Sea stacks anchored in coastal water (>= 5)", sea_stacks >= 5)
		check("Coastal cliff pines exist (>= 5)", cliff_trees >= 5)
		check("Scenic lookout bench exists on cliff top", bench_found)
		check("Signpost 'Νότιοι Γκρεμοί' exists", signpost_found)

	sea.queue_free()

	# 4. Physical Penetration Simulation Test
	print("\n[4] Testing Physical Penetration: Player vs Rock...")
	# Verify that when a player CharacterBody3D walks into a rock, penetration is zero (diff <= 0.0)
	var test_rock: Node3D = Node3D.new()
	root.add_child(test_rock)
	var rock_scene: PackedScene = load("res://assets/world/decoration/nature/rock_single_A.gltf")
	var vis: Node3D = rock_scene.instantiate()
	vis.name = "Visual"
	vis.scale = Vector3.ONE * 10.0
	test_rock.add_child(vis)
	test_rock.position = Vector3(0, 0, 0)

	# Apply village _add_rock_collider logic
	var dummy_village = village_gd.new()
	dummy_village._add_rock_collider(test_rock)
	dummy_village.free()

	var player_body := CharacterBody3D.new()
	player_body.collision_layer = 2
	player_body.collision_mask = 1
	var col_shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.9
	col_shape.shape = cap
	col_shape.position = Vector3(0, 0.95, 0)
	player_body.add_child(col_shape)
	player_body.position = Vector3(0, 0, -6.0)
	root.add_child(player_body)

	for step in 60:
		player_body.velocity = Vector3(0, 0, 6.0)
		player_body.move_and_slide()

	# Measure distance to visual mesh boundary
	var mi: MeshInstance3D = vis.find_children("*", "MeshInstance3D", true, false)[0]
	var aabb_z_min: float = (mi.get_aabb().position.z) * vis.scale.z
	var player_front_z: float = player_body.position.z + 0.45
	var penetration: float = player_front_z - aabb_z_min

	print("  Player final front Z: %f, Rock visual boundary Z: %f, Penetration: %f" % [player_front_z, aabb_z_min, penetration])
	check("Player stopped completely outside rock mesh (penetration <= 0.001m)", penetration <= 0.001)

	test_rock.queue_free()
	player_body.queue_free()

	# 5. Minimap and Greek Strings
	print("\n[5] Testing Minimap & Greek Localization...")
	var minimap_script = load("res://scripts/minimap.gd")
	var strings_script = load("res://scripts/strings_el.gd")
	var places_has_cliffs := false
	for p in minimap_script.PLACES:
		if p[0] == "cliffs":
			places_has_cliffs = true
			break
	check("Minimap.PLACES has 'cliffs'", places_has_cliffs)
	check("Strings.MAP_PLACES has 'cliffs'", strings_script.MAP_PLACES.has("cliffs"))

	print("\n--- Summary: %d passed, %d failed ---" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED!")
	quit(0 if failed == 0 else 1)
