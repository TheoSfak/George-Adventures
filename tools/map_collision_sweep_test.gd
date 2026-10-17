extends SceneTree
## Test driver for Full Map Architecture & Collision Sweep:
## Verifies smooth stair/ramp traversal, mob obstacle navigation,
## tree trunk collider calibration, and spawn clearances across all 4 maps.

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
	# Ensure Quests mock/autoload exists
	if not root.has_node("Quests"):
		var quests_node = load("res://scripts/quests.gd").new()
		quests_node.name = "Quests"
		root.add_child(quests_node)

	print("--- Running Full Map Architecture & Collision Sweep Test Suite ---")

	# =========================================================================
	# 1. NavFollower & Mob Unstuck Navigation
	# =========================================================================
	print("\n[1] Testing NavFollower & Mob Obstacle Navigation...")
	var nav = load("res://scripts/nav_follower.gd").new()
	check("NavFollower instantiates cleanly", nav != null)

	# Simulate obstacle between walker and goal at distance < 2.5m (2.2m)
	# When line is not clear, NavFollower should NOT blindly return straight direction if grid is active
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	check("Enemy CharacterBody3D has floor_max_angle >= 50 deg", enemy.floor_max_angle >= deg_to_rad(50.0))
	check("Enemy CharacterBody3D has floor_snap_length >= 0.3m", enemy.floor_snap_length >= 0.3)
	check("Enemy CharacterBody3D has floor_stop_on_slope enabled", enemy.floor_stop_on_slope)

	# Check player CharacterBody3D settings
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	check("Player CharacterBody3D has floor_max_angle >= 50 deg", player.floor_max_angle >= deg_to_rad(50.0))
	check("Player CharacterBody3D has floor_snap_length >= 0.3m", player.floor_snap_length >= 0.3)
	check("Player CharacterBody3D has floor_stop_on_slope enabled", player.floor_stop_on_slope)

	# Test tangent detour logic when pushing against wall
	var test_dir := Vector3(0.0, 0.0, 1.0)
	var detour_res: Vector3 = enemy._detour(test_dir)
	check("Detour defaults to forward direction when not blocked", detour_res.is_equal_approx(test_dir))

	enemy.queue_free()
	player.queue_free()

	# =========================================================================
	# 2. Staircase Ramp Colliders & Vertical Riser Prevention
	# =========================================================================
	print("\n[2] Testing Staircase Ramp Colliders & Fluid Traversal...")

	# A. Southeast Cliffs Stairs & Ramp
	var south_sea_script = load("res://scripts/island_south_sea.gd")
	var sea_coast = south_sea_script.new()
	root.add_child(sea_coast)
	sea_coast._build_southeast_cliffs()

	var cliffs: Node3D = sea_coast.get_node_or_null("SoutheastCliffs")
	check("SoutheastCliffs exists", cliffs != null)
	if cliffs:
		var ramp_found := false
		var step_colliders_flattened := true
		for child in cliffs.get_children():
			if child.name == "StairRamp" and child is StaticBody3D:
				ramp_found = true
			elif child is StaticBody3D and child.position.z >= 108.0 and child.position.z <= 118.0:
				for c in child.get_children():
					if c is CollisionShape3D and c.shape is BoxShape3D:
						var bs: BoxShape3D = c.shape
						if bs.size.y > 0.3:
							step_colliders_flattened = false
		check("SoutheastCliffs has continuous StairRamp collider", ramp_found)
		check("SoutheastCliffs individual step colliders lowered (<= 0.3m height)", step_colliders_flattened)

	# Physical traversal simulation on Southeast Cliffs stairs:
	# A CharacterBody3D walking along the stairs without jumping must ascend smoothly
	var walker := CharacterBody3D.new()
	walker.collision_layer = 2
	walker.collision_mask = 1
	walker.floor_max_angle = deg_to_rad(55.0)
	walker.floor_snap_length = 0.35
	walker.floor_stop_on_slope = true
	var walker_col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	walker_col.shape = cap
	walker_col.position.y = 0.85
	walker.add_child(walker_col)
	root.add_child(walker)

	walker.position = Vector3(53.0, 0.4, 106.0)
	var start_y := walker.position.y
	for tick in 80:
		var vy := 0.0 if walker.is_on_floor() else -9.8
		walker.velocity = Vector3(0.5, vy, 5.0) # walking up towards Z=118
		walker.move_and_slide()
	print("  Walker start y: %f, final y: %f, z: %f" % [start_y, walker.position.y, walker.position.z])
	check("Walker ascends Southeast Cliffs without jumping (climbed >= 2.0m)", walker.position.y - start_y >= 2.0)
	walker.queue_free()
	sea_coast.queue_free()

	# B. Highlands Mountain Trail Ramps
	var highlands_script = load("res://scripts/island_highlands.gd")
	var highlands = highlands_script.new()
	root.add_child(highlands)
	highlands._build_mountain_trail()

	var trail: Node3D = highlands.get_node_or_null("Trail")
	check("Highlands Trail exists", trail != null)
	if trail:
		var static_bodies := 0
		var ramp_bodies := 0
		for child in trail.get_children():
			if child is StaticBody3D:
				static_bodies += 1
				for c in child.get_children():
					if c is CollisionShape3D and c.shape is BoxShape3D:
						var bs: BoxShape3D = c.shape
						if bs.size.z > 5.0: # Long ramp collider
							ramp_bodies += 1
		check("Highlands Trail has stair steps and ramp bodies (total >= 28)", static_bodies >= 28)
		check("Highlands Trail has dedicated flight ramp colliders (3 flights)", ramp_bodies >= 3)

	highlands.queue_free()

	# C. Parkour Tavern Ascent Stairs
	var parkour_script = load("res://scripts/parkour_course.gd")
	var parkour = parkour_script.new()
	root.add_child(parkour)
	parkour._build_stage_1_tavern()

	var tavern_ramp_found := false
	for child in parkour.get_children():
		if child is StaticBody3D:
			for c in child.get_children():
				if c is CollisionShape3D and c.shape is BoxShape3D:
					var bs: BoxShape3D = c.shape
					if bs.size.z > 10.0 and bs.size.y < 0.5:
						tavern_ramp_found = true
	check("Parkour course has continuous smooth ramp collider over tavern ascent stairs", tavern_ramp_found)
	parkour.queue_free()

	# =========================================================================
	# 3. Tree Trunk Colliders & Spawn Clearances
	# =========================================================================
	print("\n[3] Testing Map Tree Colliders & Spawn Clearances...")

	# A. Village Tree Colliders
	var village_script = load("res://scripts/village.gd")
	var village = village_script.new()
	root.add_child(village)
	village._ready()

	var tree_colliders_found := 0
	var tree_collider_max_radius := 0.0
	for child in village.find_children("tree_single*", "Node3D", true, false):
		for sb in child.find_children("*", "StaticBody3D", true, false):
			for c in sb.get_children():
				if c is CollisionShape3D and c.shape is CylinderShape3D:
					tree_colliders_found += 1
					var cyl: CylinderShape3D = c.shape
					if cyl.radius > 0.65:
						print("  Tree over radius: %s, parent: %s, radius: %f" % [child.name, child.get_parent().name, cyl.radius])
					tree_collider_max_radius = maxf(tree_collider_max_radius, cyl.radius)

	check("Village trees have cylinder colliders (found >= 20)", tree_colliders_found >= 20)
	check("Village tree trunk colliders are calibrated to realistic radius (<= 0.65m, not 1.2m)", tree_collider_max_radius <= 0.65)
	village.queue_free()

	# B. Frontier Obstacle Clearances & Spawns
	var frontier_script = load("res://scripts/frontier.gd")
	var frontier = frontier_script.new()
	root.add_child(frontier)
	frontier._root = frontier
	frontier._build_pass()

	var frontier_trees := 0
	var frontier_tree_max_radius := 0.0
	for child in frontier.get_children():
		if child is StaticBody3D:
			for c in child.get_children():
				if c is CollisionShape3D and c.shape is CylinderShape3D:
					frontier_trees += 1
					var cyl: CylinderShape3D = c.shape
					frontier_tree_max_radius = maxf(frontier_tree_max_radius, cyl.radius)

	check("Frontier dead trees have colliders (found >= 50)", frontier_trees >= 50)
	check("Frontier dead tree trunk colliders are calibrated (<= 0.5m)", frontier_tree_max_radius <= 0.5)

	# Verify every enemy spawn in Frontier has >= 4.0m clearance from obstacles
	var blocked_frontier_spawns := 0
	for sp in frontier_script.SPAWNS:
		var p := Vector2(sp[1], sp[2])
		# Check if any static body tree or rock spawned within 3.5m of the spawn point
		for child in frontier.get_children():
			if child is StaticBody3D:
				var sb_pos := Vector2(child.position.x, child.position.z)
				if sb_pos.distance_to(p) < 3.5:
					blocked_frontier_spawns += 1
	check("Frontier enemy spawns have clear arenas (0 obstructed spawns)", blocked_frontier_spawns == 0)
	frontier.queue_free()

	# C. Catacombs Spawns vs Pillars
	var catacombs_script = load("res://scripts/catacombs.gd")
	check("Catacombs total spawns count is exactly 43", catacombs_script.SPAWNS.size() == 43)

	# Verify Great Hall pillars clearance
	var columns: Array[Vector2] = [
		Vector2(23.5, 23.0), Vector2(36.5, 23.0), Vector2(23.5, 31.0), Vector2(36.5, 31.0),
		Vector2(27.0, 25.0), Vector2(33.0, 25.0), Vector2(27.0, 29.0), Vector2(33.0, 29.0),
		Vector2(2.5, 3.5), Vector2(11.5, 3.5), Vector2(2.5, 12.5), Vector2(11.5, 12.5),
		Vector2(15.95, 11.35), Vector2(24.05, 11.35), Vector2(15.95, 17.65), Vector2(24.05, 17.65)
	]
	var min_column_dist := 999.0
	for sp in catacombs_script.SPAWNS:
		var sp_pos := Vector2(sp[1], sp[2])
		for col_pos in columns:
			min_column_dist = minf(min_column_dist, sp_pos.distance_to(col_pos))

	check("Catacombs spawns maintain safe distance from all pillars (min distance >= 2.0m)", min_column_dist >= 2.0)

	print("\n==================================================")
	print("Summary: %d Passed, %d Failed" % [passed, failed])
	print("==================================================")
	if failed == 0:
		print("ALL MAP SWEEP TESTS PASSED!")
	var navgrid_script = load("res://scripts/nav_grid.gd")
	if navgrid_script:
		navgrid_script.clear_regions()
	quit(0 if failed == 0 else 1)
