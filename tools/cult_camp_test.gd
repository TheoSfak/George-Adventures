extends SceneTree
## The cult's ritual circle, the pumpkin patch and where the new creatures stand in the real village:
##   godot --path . --headless --script tools/cult_camp_test.gd
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
	await create_timer(4.0).timeout
	var village := main.get_node("Village")
	var enemies = load("res://scripts/enemies.gd")

	# --- the places
	var site := village.get_node_or_null("CultSite")
	check("the ritual circle was built", site != null)
	check("with 16 candles, 4 skull posts, 2 banners and an altar light", site != null and site.find_children("candle_triple*", "", true, false).size() >= 16 and site.find_children("*", "OmniLight3D", true, false).size() == 1)
	var patch := village.get_node_or_null("PumpkinPatch")
	check("the pumpkin patch was built with a good many pumpkins", patch != null and patch.get_child_count() >= 15)
	var sign_found := false
	for l in village.find_children("*", "Label3D", true, false):
		if (l as Label3D).text.contains("Ξέφωτο της Σέκτας"):
			sign_found = true
	check("a signpost points the way to the cult", sign_found)
	var space := main.get_viewport().world_3d.direct_space_state
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1

	# --- where the creatures were put
	var cult_ok := true
	var priest_at := Vector2.ZERO
	var far_from_others := 999.0
	var counts := {}
	for s in enemies.SPAWNS:
		counts[s[0]] = int(counts.get(s[0], 0)) + 1
		var at := Vector2(float(s[1]), float(s[2]))
		if s[0] == "cultist" or s[0] == "cult_priest":
			cult_ok = cult_ok and at.distance_to(CultSite.CENTER) < CultSite.RADIUS * 0.6
			if s[0] == "cult_priest":
				priest_at = at
		elif at.distance_to(CultSite.CENTER) < 40.0:   # (an archer of the road stands 32 m away: the probe found no farther open ground)
			far_from_others = minf(far_from_others, at.distance_to(CultSite.CENTER))
	check("the cultists and the priest stand inside the circle", cult_ok)
	check("no other creature spawns within 30 m of it (nearest %.0f m)" % far_from_others, far_from_others >= 30.0)
	check("the priest stands behind the altar", priest_at.distance_to(CultSite.ALTAR) < 8.0)
	var patch_ok := true
	for s in enemies.SPAWNS:
		if s[0] == "pumpkin":
			patch_ok = patch_ok and Vector2(float(s[1]), float(s[2])).distance_to(CultSite.PATCH) < CultSite.PATCH_RADIUS + 3.0
	check("the five living pumpkins are in the patch", patch_ok)

	# --- the world after the spawns ran
	var alive := {}
	var dormant_hidden := true
	for e in get_nodes_in_group("enemies"):
		alive[e.kind_id] = int(alive.get(e.kind_id, 0)) + 1
		if e.kind_id == "golem" or e.kind_id == "bone_heap":
			dormant_hidden = dormant_hidden and e._state == Enemy.State.DORMANT and not e._bar.visible
	check("every new creature has been spawned (pumpkins %d, trees %d, golems %d, heaps %d, cultists %d, priest %d)" % [alive.get("pumpkin", 0), alive.get("haunted_tree", 0), alive.get("golem", 0), alive.get("bone_heap", 0), alive.get("cultist", 0), alive.get("cult_priest", 0)],
			alive.get("pumpkin", 0) == 5 and alive.get("haunted_tree", 0) == 3 and alive.get("golem", 0) == 3 and alive.get("bone_heap", 0) == 4 and alive.get("cultist", 0) == 5 and alive.get("cult_priest", 0) == 1)
	check("golems and bone heaps sleep and show no health bar", dormant_hidden)
	var on_free_ground := true
	for e in get_nodes_in_group("enemies"):
		if e.kind_id in ["pumpkin", "haunted_tree", "golem", "bone_heap", "cultist", "cult_priest"]:
			query.transform = Transform3D(Basis.IDENTITY, e.global_position + Vector3.UP * 1.2)
			# the creature's own body is not layer 1, so any hit is a prop or a wall
			if not space.intersect_shape(query, 1).is_empty():
				on_free_ground = false
				print("  inside something: ", e.kind_id, " at ", e.global_position)
	check("none of them stands inside a tree, house or prop", on_free_ground)

	# --- the way there
	var grid := NavGrid.region("village")
	var waited := 0.0
	while grid != null and not grid.is_ready(0.6) and waited < 20.0:
		await create_timer(0.1).timeout
		waited += 0.1
	var path := grid.find_path(Vector3(-62, 0, -110), Vector3(CultSite.CENTER.x, 0, CultSite.CENTER.y))
	check("a path leads from the road to the circle", not path.is_empty() and Vector2(path[path.size() - 1].x, path[path.size() - 1].z).distance_to(CultSite.CENTER) < 3.0)

	# --- the map
	var minimap = load("res://scripts/minimap.gd")
	var named := false
	for pl in minimap.PLACES:
		named = named or pl[0] == "cult"
	check("the big map names the place and points quests at it", named and minimap.BOSS_AREAS.has("cult_priest") and minimap.BOSS_AREAS.has("cultist"))
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
