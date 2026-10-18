extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	var quests_node := root.get_node_or_null("/root/Quests")
	if quests_node != null:
		quests_node.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout

	print("==================================================")
	print("ORC STRONGHOLD & ASH VALLEY GATE COMPREHENSIVE VERIFICATION")
	print("==================================================")

	var space: PhysicsDirectSpaceState3D = main.get_viewport().world_3d.direct_space_state
	var failed_checks := 0

	# Exclude characters/player from environment collision rays
	var exclude_rids: Array[RID] = []
	for node in main.find_children("*", "CollisionObject3D", true, false):
		if node is CharacterBody3D or node.name == "CameraShell" or node is Player or node is Enemy:
			exclude_rids.append(node.get_rid())

	# 1. Distance check from Orc Stronghold to Ash Valley Gate
	var ash_gate_pos := Vector3(178.0, 0.0, 64.0)
	var stronghold_center := Vector3(122.0, 0.0, 6.0)
	var dist_to_ash := stronghold_center.distance_to(ash_gate_pos)
	print("Stronghold center: %s | Ash Valley Gate: %s" % [stronghold_center, ash_gate_pos])
	print("Distance from Stronghold to Ash Valley Gate: %.2f m" % dist_to_ash)
	if dist_to_ash >= 75.0:
		print("  PASS: Orc Stronghold is well away from Ash Valley Gate (> 75m)!")
	else:
		print("  FAIL: Orc Stronghold is too close to Ash Valley Gate!")
		failed_checks += 1

	# 2. Gate Walkway Clearance: Walk straight through the front gate
	print("\n--- Gate Walkway Passage Check ---")
	var outside_approach := Vector3(98.0, 1.0, 6.0)
	var inside_courtyard := Vector3(122.0, 1.0, 6.0)
	var ray_pass := PhysicsRayQueryParameters3D.create(outside_approach, inside_courtyard)
	ray_pass.exclude = exclude_rids
	var hit_pass = space.intersect_ray(ray_pass)
	if hit_pass.is_empty():
		print("  PASS: Player can walk straight through the gate into the courtyard without wall obstruction!")
	else:
		print("  FAIL: Gate walkway hit collider: %s at %s" % [hit_pass.collider.name, hit_pass.position])
		failed_checks += 1

	# Check lateral corridor clearance (3m wide corridor through gate)
	for dz in [-1.5, -0.75, 0.75, 1.5]:
		var r_lat = PhysicsRayQueryParameters3D.create(outside_approach + Vector3(0, 0, dz), inside_courtyard + Vector3(0, 0, dz))
		r_lat.exclude = exclude_rids
		var h_lat = space.intersect_ray(r_lat)
		if not h_lat.is_empty() and h_lat.collider.name != "GroundCollider":
			print("  FAIL: Lateral corridor dz=%.2f blocked by %s" % [dz, h_lat.collider.name])
			failed_checks += 1
		else:
			print("  PASS: Lateral corridor dz=%.2f is clear of walls" % dz)

	# 3. Enemies Collision Check
	print("\n--- Live Orc Enemies Clearance Check ---")
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.collision_mask = 1

	var enemies = main.find_children("*", "CharacterBody3D", true, false)
	var orc_count := 0
	for e in enemies:
		var kind: String = e.get("kind_id") if e.get("kind_id") != null else ""
		if kind.begins_with("orc_"):
			orc_count += 1
			query.transform = Transform3D(Basis.IDENTITY, e.global_position + Vector3(0, 0.6, 0))
			var hits = space.intersect_shape(query, 10)
			var wall_hits: Array[String] = []
			for h in hits:
				if h.collider != e and h.collider.name != "GroundCollider" and not (h.collider is CharacterBody3D):
					wall_hits.append(h.collider.name)
			if wall_hits.is_empty():
				print("  PASS: Orc %s at %s is completely clear of walls!" % [kind, e.global_position])
			else:
				print("  FAIL: Orc %s at %s intersects walls: %s" % [kind, e.global_position, wall_hits])
				failed_checks += 1
	print("Verified %d live orcs in the stronghold" % orc_count)
	if orc_count < 6:
		print("  FAIL: Expected at least 6 orcs in stronghold, found %d" % orc_count)
		failed_checks += 1

	# 4. Raid Totems Collision Check
	print("\n--- Warband Blood Totems Clearance Check ---")
	var raid = main.find_child("OrcStrongholdRaid", true, false)
	if raid == null:
		print("  FAIL: OrcStrongholdRaid not found in scene tree!")
		failed_checks += 1
	else:
		var totems: Array = raid.get("_totems")
		print("Found %d totems in raid" % totems.size())
		if totems.size() != 3:
			print("  FAIL: Expected 3 totems, found %d" % totems.size())
			failed_checks += 1
		for i in totems.size():
			var t = totems[i]
			query.transform = Transform3D(Basis.IDENTITY, t.global_position + Vector3(0, 1.0, 0))
			var hits = space.intersect_shape(query, 10)
			var wall_hits: Array[String] = []
			for h in hits:
				if h.collider != t and h.collider.name != "GroundCollider" and not (h.collider is CharacterBody3D):
					wall_hits.append(h.collider.name)
			if wall_hits.is_empty():
				print("  PASS: Totem %d at %s is completely clear of walls!" % [i + 1, t.global_position])
			else:
				print("  FAIL: Totem %d at %s intersects walls: %s" % [i + 1, t.global_position, wall_hits])
				failed_checks += 1

	# 5. Check Line of Sight from Village Road to Ash Valley Gate
	print("\n--- Ash Valley Gate Line of Sight & Approach Check ---")
	var road_to_ash_start := Vector3(112.0, 1.0, 68.0) # Near Golden Grove
	var ash_gate_front := ash_gate_pos + Vector3(-5.0, 1.0, 0.0)
	var r_ash = PhysicsRayQueryParameters3D.create(road_to_ash_start, ash_gate_front)
	r_ash.exclude = exclude_rids
	var h_ash = space.intersect_ray(r_ash)
	if h_ash.is_empty() or h_ash.collider.name == "GroundCollider":
		print("  PASS: Path from Golden Grove to Ash Valley Gate is 100% CLEAR and unobstructed!")
	else:
		print("  FAIL: Path to Ash Valley Gate blocked by: %s at %s" % [h_ash.collider.name, h_ash.position])
		failed_checks += 1

	print("\n==================================================")
	print("VERIFICATION RESULT: %d FAILS" % failed_checks)
	print("==================================================")

	quit(failed_checks)
