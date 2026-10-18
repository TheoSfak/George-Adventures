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
	print("GLADIATOR ARENA COMPREHENSIVE VERIFICATION SUITE")
	print("==================================================")

	var failed_checks := 0
	var arena: GladiatorArena = null
	for n in root.find_children("*", "GladiatorArena", true, false):
		arena = n as GladiatorArena
		break

	if arena == null:
		print("  FAIL: GladiatorArena node not found!")
		quit(1)
		return
	print("  PASS: GladiatorArena instance found in scene tree.")

	var player: Player = null
	for p in root.find_children("*", "Player", true, false):
		player = p as Player
		break

	if player == null:
		print("  FAIL: Player node not found!")
		quit(1)
		return
	print("  PASS: Player instance found in scene tree.")

	# -------------------------------------------------------------
	# 1. Location & Clear Separation from Castle
	# -------------------------------------------------------------
	var tower_pos := Vector3(95.1, 0.0, -78.7)
	var arena_center := arena.CENTER
	var dist_to_tower := arena_center.distance_to(tower_pos)
	print("\n--- 1. Location & Distance Checks ---")
	print("Arena Center: %s | Watchtower/Castle: %s" % [arena_center, tower_pos])
	print("Distance from Arena to Watchtower: %.2f m" % dist_to_tower)
	if dist_to_tower >= 200.0:
		print("  PASS: Arena is moved far away from castle (> 200m)!")
	else:
		print("  FAIL: Arena is too close to castle!")
		failed_checks += 1

	# -------------------------------------------------------------
	# 2. Verify No Deer or Chests Inside the Arena
	# -------------------------------------------------------------
	print("\n--- 2. Wildlife & Chest Proximity Checks ---")
	var village = main.get_node("Village")
	var chests_in_arena: int = 0
	for c in village.find_children("*", "Chest", true, false):
		var c_node := c as Node3D
		var d: float = arena_center.distance_to(c_node.global_position)
		if d < arena.ARENA_RADIUS + 2.0:
			print("  FAIL: Chest '%s' is inside arena (dist: %.2f m)!" % [c_node.name, d])
			chests_in_arena += 1
	if chests_in_arena == 0:
		print("  PASS: 0 chests found inside the arena (clean sand pit)!")
	else:
		failed_checks += 1

	var deer_in_arena: int = 0
	for d in village.find_children("*", "CharacterBody3D", true, false):
		var scr = d.get_script()
		var scr_path: String = scr.resource_path.to_lower() if scr != null else ""
		if "deer" in d.name.to_lower() or "deer" in scr_path:
			var dist: float = arena_center.distance_to(d.global_position)
			if dist < arena.ARENA_RADIUS + 2.0:
				print("  FAIL: Deer '%s' is inside arena (dist: %.2f m)!" % [d.name, dist])
				deer_in_arena += 1
	if deer_in_arena == 0:
		print("  PASS: 0 deer found inside the arena!")
	else:
		failed_checks += 1

	# -------------------------------------------------------------
	# 3. Gate, Emergency Lever & Approach Passage
	# -------------------------------------------------------------
	print("\n--- 3. Gate, Approach & Emergency Lever Checks ---")
	var space: PhysicsDirectSpaceState3D = main.get_viewport().world_3d.direct_space_state
	var gate_pos := arena.GATE_POS
	var outside_approach := gate_pos + Vector3(8.0, 1.0, 0.0)
	var inside_pit := gate_pos + Vector3(-6.0, 1.0, 0.0)

	# When gate is open (default), ray through gate portal must not hit portcullis collider
	var ray_gate := PhysicsRayQueryParameters3D.create(outside_approach, inside_pit)
	var hit_gate = space.intersect_ray(ray_gate)
	if hit_gate.is_empty():
		print("  PASS: Open gate has unobstructed walkthrough into arena!")
	else:
		print("  FAIL: Open gate obstructed by: %s at %s" % [hit_gate.collider.name, hit_gate.position])
		failed_checks += 1

	var lever = arena.find_child("GateEmergencyLever", true, false)
	if lever != null:
		print("  PASS: Emergency Gate Lever found inside the arena!")
	else:
		print("  FAIL: Emergency Gate Lever not found!")
		failed_checks += 1

	# -------------------------------------------------------------
	# 4. In-Game Wave Progression & Combat Simulation
	# -------------------------------------------------------------
	print("\n--- 4. Wave Progression & Combat Simulation ---")
	player.gold = 500
	player.level = 10

	var started := arena.start_trial("bronze", player)
	if not started:
		print("  FAIL: Could not start bronze trial!")
		failed_checks += 1
		quit(1)
		return
	print("  PASS: Started Bronze Trial successfully!")

	# Verify gate is closed
	await create_timer(0.2).timeout
	var ray_closed := PhysicsRayQueryParameters3D.create(outside_approach, inside_pit)
	var hit_closed = space.intersect_ray(ray_closed)
	if not hit_closed.is_empty():
		print("  PASS: Gate portcullis closed & physical collider engaged during trial!")
	else:
		print("  FAIL: Gate portcullis did not block ray while trial is active!")
		failed_checks += 1

	# Wait for Wave 1 mobs to spawn (1.8s timer in start_trial)
	await create_timer(2.2).timeout
	print("Wave 1 state: current_wave = %d | active_mobs = %d" % [arena.current_wave, arena._active_mobs.size()])
	if arena.current_wave == 1 and arena._active_mobs.size() == 3:
		print("  PASS: Wave 1 spawned exactly 3 recruits!")
	else:
		print("  FAIL: Wave 1 did not spawn expected 3 mobs (got %d)!" % arena._active_mobs.size())
		failed_checks += 1

	# Simulate killing Wave 1 mobs
	print("Simulating George slaying Wave 1 mobs...")
	var w1_mobs = arena._active_mobs.duplicate()
	for m in w1_mobs:
		if is_instance_valid(m):
			m.take_damage(9999.0, m.global_position)

	# Wait for wave transition timer (2.6s)
	await create_timer(3.2).timeout
	print("Wave 2 state: current_wave = %d | active_mobs = %d" % [arena.current_wave, arena._active_mobs.size()])
	if arena.current_wave == 2 and arena._active_mobs.size() == 4:
		print("  PASS: BUG RESOLVED! Wave 1 smoothly transitioned to Wave 2 (4 skeletons spawned)!")
	else:
		print("  FAIL: Wave did NOT advance to Wave 2! Bug persists! (wave=%d, mobs=%d)" % [arena.current_wave, arena._active_mobs.size()])
		failed_checks += 1

	# Simulate killing Wave 2 mobs
	print("Simulating George slaying Wave 2 skeletons...")
	var w2_mobs = arena._active_mobs.duplicate()
	for m in w2_mobs:
		if is_instance_valid(m):
			m.take_damage(9999.0, m.global_position)

	# Wait for wave transition timer (2.6s)
	await create_timer(3.2).timeout
	print("Wave 3 state: current_wave = %d | active_mobs = %d" % [arena.current_wave, arena._active_mobs.size()])
	if arena.current_wave == 3 and arena._active_mobs.size() == 1:
		print("  PASS: Wave 2 smoothly transitioned to Wave 3 (Boss Gorgor spawned)!")
	else:
		print("  FAIL: Wave did NOT advance to Wave 3! (wave=%d, mobs=%d)" % [arena.current_wave, arena._active_mobs.size()])
		failed_checks += 1

	# Simulate slaying the Boss
	print("Simulating George slaying Boss Gorgor...")
	var w3_mobs = arena._active_mobs.duplicate()
	for m in w3_mobs:
		if is_instance_valid(m):
			m.take_damage(9999.0, m.global_position)

	await create_timer(1.0).timeout
	print("Trial state after boss death: active = %s" % str(arena.trial_active))
	if not arena.trial_active and arena.completed_trials.has("bronze"):
		print("  PASS: Bronze trial marked completed in completed_trials!")
	else:
		print("  FAIL: Trial not completed properly!")
		failed_checks += 1

	if is_instance_valid(arena._victory_chest):
		print("  PASS: Golden Champion Victory Chest spawned in arena center!")
	else:
		print("  FAIL: Victory chest was not spawned!")
		failed_checks += 1

	# Verify gate opened after victory (excluding player)
	var ray_open_again := PhysicsRayQueryParameters3D.create(outside_approach, inside_pit)
	ray_open_again.exclude = [player.get_rid()]
	var hit_open_again = space.intersect_ray(ray_open_again)
	if hit_open_again.is_empty():
		print("  PASS: Gate portcullis raised and player can exit freely!")
	else:
		print("  FAIL: Gate is still locked after victory! Collider: %s" % hit_open_again.collider.name)
		failed_checks += 1

	# -------------------------------------------------------------
	# 5. Emergency Gate Lever Test
	# -------------------------------------------------------------
	print("\n--- 5. Emergency Gate Lever Abandon Test ---")
	arena.start_trial("bronze", player)
	await create_timer(0.3).timeout
	if arena.trial_active:
		arena.abandon_or_open_gate(player)
		await create_timer(0.3).timeout
		if not arena.trial_active:
			print("  PASS: Emergency Gate Lever successfully abandoned trial & unlocked gate!")
		else:
			print("  FAIL: Emergency lever failed to abandon active trial!")
			failed_checks += 1

	print("\n==================================================")
	if failed_checks == 0:
		print("ALL 15 COMPREHENSIVE ARENA CHECKS PASSED (100% SUCCESS)!")
		quit(0)
	else:
		print("COMPREHENSIVE ARENA VERIFICATION FAILED (%d errors)!" % failed_checks)
		quit(1)
