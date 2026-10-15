extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	var av_script = load("res://scripts/ash_valley.gd")
	var candidate_crystals: Array = av_script.CRYSTALS
	print("\n--- Testing AshValley.CRYSTALS Positions ---")
	for i in range(candidate_crystals.size()):
		var c: Vector2 = candidate_crystals[i]
		var sz: float = av_script.stream_z(c.x)
		var dist_to_center: float = absf(c.y - sz)
		var dist_to_lava_edge: float = dist_to_center - av_script.STREAM_WIDTH * 0.5
		var dist_to_rim_edge: float = dist_to_center - (av_script.STREAM_WIDTH * 0.5 + 1.5)
		var bank: String = "South" if c.y > sz else "North"
		print("Crystal %d at (%s, %s): stream_z=%.2f, dist_to_center=%.2f, dist_to_lava=%.2f, dist_to_rim=%.2f, Bank=%s" % [
			i + 1, c.x, c.y, sz, dist_to_center, dist_to_lava_edge, dist_to_rim_edge, bank
		])
		if dist_to_lava_edge < 0.0:
			print("  [ERROR] Inside lava!")
		elif dist_to_rim_edge < 0.0:
			print("  [WARNING] On lava rim!")
		else:
			print("  [OK] Safely on dry ground bank.")

	# Now build Ash Valley and check NavGrid and actual collisions
	print("\n--- Building AshValley in scene ---")
	var root := Node3D.new()
	get_root().add_child(root)
	
	var av = av_script.new()
	root.add_child(av)
	await av.build()
	
	for frame in range(10):
		await process_frame
	
	var grid: NavGrid = null
	for i in range(25):
		await create_timer(0.2).timeout
		grid = NavGrid.region("ashvalley")
		if grid != null and grid.is_ready(0.6):
			break
			
	if grid == null or not grid.is_ready(0.6):
		print("[ERROR] NavGrid for ashvalley not found or not ready!")
		quit(1)
		return
		
	var camp_pos: Vector3 = av_script.wp(av_script.CAMP.x, av_script.CAMP.y)
	print("\n--- Checking Old Crystal Positions ---")
	for old_c in [Vector2(-28.0, -52.0), Vector2(26.0, -50.0), Vector2(-12.0, -70.0), Vector2(32.0, -68.0)]:
		var wpos: Vector3 = av_script.wp(old_c.x, old_c.y)
		var blocked: bool = grid.blocked(wpos)
		var path := grid.find_path(camp_pos, wpos)
		print("Old crystal (%s, %s): grid.blocked=%s, reachable=%s" % [old_c.x, old_c.y, blocked, path.size() > 0])
	
	var all_reachable := true
	for i in range(candidate_crystals.size()):
		var c: Vector2 = candidate_crystals[i]
		var wpos: Vector3 = av_script.wp(c.x, c.y)
		var blocked: bool = grid.blocked(wpos)
		print("Crystal %d local (%s, %s) world %s: grid.blocked=%s" % [i + 1, c.x, c.y, wpos, blocked])
		
		var path := grid.find_path(camp_pos, wpos)
		var reachable := path.size() > 0
		print("  Path from Camp to Crystal %d: length=%d points, reachable=%s" % [i + 1, path.size(), reachable])
		if path.size() > 0:
			var end_dist: float = path[-1].distance_to(wpos)
			print("  End point distance to crystal: %.2fm" % end_dist)
			if end_dist > 2.0:
				print("  [WARNING] Path did not reach close enough to crystal! end_dist=%.2f" % end_dist)
				all_reachable = false
		else:
			all_reachable = false
			
	if all_reachable:
		print("\nALL CRYSTALS ARE 100% REACHABLE ON FOOT FROM CAMP!")
	else:
		print("\nSOME CRYSTALS ARE NOT REACHABLE!")
		
	root.queue_free()
	quit(0 if all_reachable else 1)
