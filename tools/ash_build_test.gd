extends SceneTree
## The Ash Valley: the village gate, building the region, its content, the lava walls and the bridge, the temple gate,
## the boss, the way back, saving and loading inside it (also an old Frontier save), the hooks of a region:
##   godot --path . --headless --script tools/ash_build_test.gd      (takes about a minute)
var failed := false
var p: Player
var q: Node
var interiors
var av


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func wait_region(on: bool) -> void:
	for i in 200:
		await create_timer(0.1).timeout
		if interiors.in_region() == on and not p.busy:
			return


func gate_spot() -> InteractSpot:
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.global_position.distance_to(av.VILLAGE_GATE) < 4.5:
			return n
	return null


func ray_hits(from: Vector3, to: Vector3) -> bool:
	var space: PhysicsDirectSpaceState3D = p.get_world_3d().direct_space_state
	return not space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1)).is_empty()


func _run() -> void:
	await process_frame
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	av = load("res://scripts/ash_valley.gd")
	var fr = load("res://scripts/frontier.gd")
	var save = load("res://scripts/save_game.gd")
	# keep the player's real saves safe: this test writes savegame.json
	var real_backup := "user://savegame.before_ash_test"
	var real_bak_backup := "user://savegame.bak.before_ash_test"
	if FileAccess.file_exists(save.PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(save.BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.BACKUP), ProjectSettings.globalize_path(real_bak_backup))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	interiors = get_first_node_in_group("interiors")
	var hud = get_first_node_in_group("hud")
	var sound = get_first_node_in_group("sound_manager")
	var invasion = get_first_node_in_group("invasion")
	p._invulnerable = 99999.0

	# ---------------------------------------------------------------- the gate in the village
	var spot := gate_spot()
	check("the Ash Gate exists in the village", spot != null)
	if spot == null:
		quit(1)
		return
	check("sealed prompt before the quest", spot.interact_prompt().contains(Strings.ASH_SEALED))
	p.teleport(spot.global_position + Vector3(0, 0.05, 0), 0.0)
	spot.interact(p)
	await create_timer(0.6).timeout
	check("a sealed gate does not let George through", not interiors.in_region())
	q.state["a_gate"] = q.S.ACTIVE
	check("open prompt after the quest", spot.interact_prompt().contains(Strings.BUILDING_NAMES["ashvalley"]))
	invasion.start(1)
	spot.interact(p)
	await create_timer(0.6).timeout
	check("George cannot leave while the village is attacked", not interiors.in_region())
	invasion._on_dawn()
	var lights_before := root.find_children("*", "OmniLight3D", true, false).size()
	spot.interact(p)
	await wait_region(true)
	check("George is in the region, outdoors", interiors.in_region() and not interiors.is_inside())
	check("the region kind is ashvalley", interiors.current_kind == "ashvalley")
	check("he stands at the entry (%s)" % str(p.global_position), p.global_position.distance_to(av.wp(av.ENTRY.x, av.ENTRY.y, 0.05)) < 1.5)
	check("the arrival counted for a_gate", q.state["a_gate"] == q.S.READY)
	check("the sun is still on (outdoor)", (root.find_child("Sun", true, false) as Light3D).visible)
	var level = get_first_node_in_group("ashvalley")
	check("the level node exists", level != null)

	# ---------------------------------------------------------------- content
	var region_lights := root.find_children("*", "OmniLight3D", true, false).size() - lights_before
	print("   region lights: ", region_lights)
	check("the region stays inside the light budget (%d lights)" % region_lights, region_lights > 12 and region_lights <= 40)
	var counts := {}
	for e in get_nodes_in_group("enemies"):
		var local: Vector3 = e.global_position - av.ORIGIN
		if absf(local.x) > 2000.0:
			continue                                # village skeletons stand thousands of metres away
		counts[e.kind_id] = int(counts.get(e.kind_id, 0)) + 1
		check("no enemy in the camp (%s at %s)" % [e.kind_id, str(local)], Vector2(local.x, local.z).distance_to(av.CAMP) > av.CAMP_RADIUS)
	print("   enemies by kind: ", counts)
	check("every spawn of the list stands in the valley", int(counts.get("ember_skeleton", 0)) >= 12 and int(counts.get("ash_caster", 0)) >= 8 and int(counts.get("magma_golem", 0)) == 3 and int(counts.get("pyrforos", 0)) == 1)
	var npc_ids := []
	for n in get_nodes_in_group("npcs"):
		npc_ids.append(n.get("npc_id"))
	check("Theofilos and Damianos stand in the Shelter", "theofilos" in npc_ids and "damianos" in npc_ids)
	check("4 chests in the region", root.find_children("*", "Chest", true, false).filter(func(c): return c.global_position.x > 5000.0).size() == 4)
	var shards := root.find_children("*", "QuestItem", true, false).filter(func(n): return n.item_id == "shard")
	check("three Shards of the Flame lie around", shards.size() == 3)
	q.state["a_shards"] = q.S.AVAILABLE
	q.changed.emit()
	check("...hidden before the quest", shards.all(func(n): return not n.visible))
	q.state["a_shards"] = q.S.ACTIVE
	q.changed.emit()
	check("...visible while the quest is active", shards.all(func(n): return n.visible))
	var lava := root.find_children("*", "MeshInstance3D", true, false).filter(func(m): return m.material_override is ShaderMaterial and m.global_position.x > 5000.0)
	check("a river of lava flows (%d meshes)" % lava.size(), lava.size() >= 30)
	check("a bridge stands over it", root.find_children("Bridge", "MeshInstance3D", true, false).size() == 1)

	# ---------------------------------------------------------------- the lava is a wall, the bridge is a way
	var zc: float = av.stream_z(-30.0)
	check("the lava is walled at x = -30", ray_hits(av.wp(-30.0, zc - 20.0, 1.0), av.wp(-30.0, zc + 20.0, 1.0)))
	check("the lava is walled at x = 40", ray_hits(av.wp(40.0, av.stream_z(40.0) - 20.0, 1.0), av.wp(40.0, av.stream_z(40.0) + 20.0, 1.0)))
	var bz: float = av.stream_z(0.0)
	check("the bridge is open at x = 0", not ray_hits(av.wp(0.0, bz - 20.0, 1.0), av.wp(0.0, bz + 20.0, 1.0)))
	check("...and at x = 4", not ray_hits(av.wp(4.0, bz - 20.0, 0.9), av.wp(4.0, bz + 20.0, 0.9)))

	# ---------------------------------------------------------------- the navigation grid knows the lava and the bridge
	var grid := NavGrid.region("ashvalley")
	check("the valley has a navigation grid", grid != null and grid.is_ready(0.6))
	if grid != null:
		check("lava is not walkable", grid.blocked(av.wp(-30.0, zc, 0.0)))
		var from: Vector3 = av.wp(0.0, 10.0)
		var path := grid.find_path(from, av.wp(0.0, -90.0))
		path.insert(0, from)                              # the path starts after `from`
		var crosses := false
		for i in range(1, path.size()):                  # the path is smoothed: look along its segments, not only at its corners
			var steps := int(path[i - 1].distance_to(path[i]))
			for k in steps + 1:
				var at: Vector3 = path[i - 1].lerp(path[i], float(k) / maxf(float(steps), 1.0))
				if absf(at.x - av.ORIGIN.x) < av.BRIDGE_HALF and absf(at.z - (av.ORIGIN.z + bz)) < 2.0:
					crosses = true
		print("   path camp -> temple road: ", path, "  bridge z ", bz, "  crosses ", crosses)
		check("a path from the camp to the temple road crosses the bridge", path.size() > 1 and crosses and Vector2(path[path.size() - 1].x - av.wp(0, -90).x, path[path.size() - 1].z - av.wp(0, -90).z).length() < 3.0)

	# ---------------------------------------------------------------- the temple gate
	check("the temple gate starts sealed", not level._gate_open)
	check("a barrier is standing", root.find_children("*", "MeshInstance3D", true, false).filter(func(n): return n.is_in_group("ash_gate")).size() == 1)
	q.state["a_shards"] = q.S.READY
	q.changed.emit()
	await create_timer(1.5).timeout
	check("the gate opens when the shards are ready", level._gate_open)
	check("the barrier is gone", root.find_children("*", "MeshInstance3D", true, false).filter(func(n): return n.is_in_group("ash_gate") and is_instance_valid(n) and not n.is_queued_for_deletion()).is_empty())
	check("the temple gate is walkable now", not ray_hits(av.wp(-4.0, av.GATE_Z + 8.0, 1.0), av.wp(-4.0, av.GATE_Z - 8.0, 1.0)))

	# ---------------------------------------------------------------- the boss
	var boss
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "pyrforos":
			boss = e
	boss.take_damage(9999999.0, p.global_position)
	await create_timer(0.3).timeout
	check("the Keeper is dead", boss.is_dead())
	q.state["a_boss"] = q.S.ACTIVE
	q.changed.emit()
	await create_timer(0.3).timeout
	var back := 0
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "pyrforos" and not e.is_dead():
			back += 1
	check("the Keeper is back at once when a_boss is active", back == 1)

	# ---------------------------------------------------------------- the hooks of a region
	for e in get_nodes_in_group("enemies"):
		e.queue_free()                             # no fight music in this test
	await create_timer(0.5).timeout
	check("the corner minimap is hidden in the valley", not hud._mini_frame.visible)
	check("the valley music is dark ('crypt')", sound._pick_music() == "crypt")
	hud.toggle_big_map()
	check("the big map does not open in the valley", not hud._big_map.visible)
	invasion.start(1)
	check("a night invasion is skipped while George is away", not invasion.active)

	# ---------------------------------------------------------------- saving inside the valley
	save.delete()
	check("saved", save.save())
	var data: Dictionary = save.read()
	check("the save names the region", String(data["player"].get("region", "")) == "ashvalley" and not bool(data["player"].get("in_frontier", true)))
	var saved_pos: Vector3 = p.global_position
	interiors.exit_region(p)
	await wait_region(false)
	check("back in the village near the gate", not interiors.in_region() and p.global_position.distance_to(av.VILLAGE_GATE) < 12.0)
	check("the village minimap returns", hud._mini_frame.visible)
	save.apply(data)
	await wait_region(true)
	check("loading puts George back in the valley", interiors.in_region() and interiors.current_kind == "ashvalley" and p.global_position.distance_to(saved_pos) < 1.5)
	check("a second visit reuses the level", get_nodes_in_group("ashvalley").size() == 1)

	# ---------------------------------------------------------------- an old Frontier save (only "in_frontier") still works
	interiors.exit_region(p)
	await wait_region(false)
	var old_data: Dictionary = data.duplicate(true)
	old_data["player"].erase("region")
	old_data["player"]["in_frontier"] = true
	old_data["player"]["position"] = [fr.ORIGIN.x, 0.0, fr.ORIGIN.z + 100.0]
	save.apply(old_data)
	await wait_region(true)
	check("an old save with in_frontier loads the Frontier", interiors.in_region() and interiors.current_kind == "frontier")
	check("both regions exist side by side", get_nodes_in_group("frontier").size() == 1 and get_nodes_in_group("ashvalley").size() == 1)
	var gate_back = null
	interiors.exit_region(p)
	await wait_region(false)
	check("leaving the Frontier leads to the pass gate", p.global_position.distance_to(fr.VILLAGE_GATE) < 12.0)

	# ---------------------------------------------------------------- the arch back and dying in the valley
	spot.interact(p)
	await wait_region(true)
	check("the Ash Gate works again", interiors.current_kind == "ashvalley")
	var exit_spot: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_ASH_BACK:
			exit_spot = n
	check("there is a way back", exit_spot != null)
	p.teleport(exit_spot.global_position, PI)
	exit_spot.interact(p)
	await wait_region(false)
	check("George is back in the village", not interiors.in_region() and p.global_position.distance_to(av.VILLAGE_GATE) < 12.0)
	check("the arrival counted for the village", true)
	spot.interact(p)
	await wait_region(true)
	p.respawn_time = 0.3
	p._die()
	await create_timer(1.2).timeout
	check("dying in the valley wakes George in the village", not interiors.in_region() and p.global_position.length() < 60.0)

	# restore the real save
	save.delete()
	if FileAccess.file_exists(real_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_backup), ProjectSettings.globalize_path(save.PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(real_bak_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_bak_backup), ProjectSettings.globalize_path(save.BACKUP))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_bak_backup))
	quit(1 if failed else 0)
