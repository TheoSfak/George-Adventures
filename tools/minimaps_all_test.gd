extends SceneTree

func _init() -> void:
	print("--- BEGIN MINIMAP VERIFICATION TEST ---")
	var success := true

	# 1. Test Region Configurations
	print("\n[1] Testing REGION_DATA...")
	var regions = ["", "frontier", "ashvalley"]
	for reg in regions:
		if not Minimap.REGION_DATA.has(reg):
			print("FAIL: Missing region '%s'" % reg)
			success = false
			continue
		var data: Dictionary = Minimap.REGION_DATA[reg]
		print("  Region '%s': name='%s', half=%f, origin=%s, places=%d, shops=%d, boss_areas=%d" % [
			reg, data.get("name", ""), data.get("half", 0.0), str(data.get("origin", Vector3.ZERO)),
			data.get("places", []).size(), data.get("shops", []).size(), data.get("boss_areas", {}).size()
		])
		if data.get("name", "").is_empty():
			print("FAIL: Region '%s' has empty name" % reg)
			success = false
		if data.get("half", 0.0) <= 0.0:
			print("FAIL: Region '%s' has invalid half size" % reg)
			success = false

	# 2. Test Places and Strings.MAP_PLACES
	print("\n[2] Testing PLACES and Greek Localization...")
	for reg in regions:
		var places: Array = Minimap.REGION_DATA[reg].get("places", [])
		for p in places:
			var key: String = p[0]
			if not Strings.MAP_PLACES.has(key):
				print("FAIL: Missing Greek name in Strings.MAP_PLACES for key '%s' (region: '%s')" % [key, reg])
				success = false
			else:
				var label: String = Strings.MAP_PLACES[key]
				# print("    Place '%s' -> '%s' (x=%f, z=%f)" % [key, label, p[1], p[2]])

	# 3. Test Shops and Icons
	print("\n[3] Testing SHOPS...")
	var village_shops: Array = Minimap.REGION_DATA[""].get("shops", [])
	print("  Village shops count: %d" % village_shops.size())
	if village_shops.size() < 5:
		print("FAIL: Expected at least 5 shops on the main island (Market, Smith, Archery, Alchemy, Stable)")
		success = false

	# 4. Test Quest Objective Coverage
	print("\n[4] Testing Quests & Objective Targets...")
	var objective_types := {}
	var kill_targets := {}
	var collect_items := {}
	var reach_places := {}

	for qid in QuestData.QUESTS:
		var q: Dictionary = QuestData.QUESTS[qid]
		for obj in q.get("objectives", []):
			var t: String = obj.get("type", "")
			objective_types[t] = objective_types.get(t, 0) + 1
			match t:
				"kill":
					var target: String = obj.get("target", "")
					kill_targets[target] = kill_targets.get(target, 0) + 1
				"collect":
					var item: String = obj.get("item", "")
					collect_items[item] = collect_items.get(item, 0) + 1
				"reach":
					var pl: String = obj.get("place", "")
					reach_places[pl] = reach_places.get(pl, 0) + 1

	print("  Objective types tally: %s" % str(objective_types))
	print("  Kill targets: %s" % str(kill_targets))
	print("  Collect items: %s" % str(collect_items))
	print("  Reach places: %s" % str(reach_places))

	# Verify every kill target has either boss_areas fallback or specific handling
	print("\n[5] Checking Boss Area fallbacks for kill targets...")
	var all_boss_areas := {}
	for reg in regions:
		var ba: Dictionary = Minimap.REGION_DATA[reg].get("boss_areas", {})
		for k in ba:
			all_boss_areas[k] = true

	for target in kill_targets:
		var covered = all_boss_areas.has(target) or target in ["skeleton", "totem", "warband_totem", "orc_catapult"]
		if not covered:
			print("WARNING: Kill target '%s' does not have a boss_areas fallback!" % target)
		else:
			print("  Target '%s' is covered (has fallback or special handler)" % target)

	# 6. Test Minimap Node Instantiation and drawing methods
	print("\n[6] Testing Minimap node instantiation & coordinate transforms...")
	var mini = Minimap.new()
	mini.size = Vector2(188, 188)
	mini.big = false

	var big_map = Minimap.new()
	big_map.size = Vector2(560, 560)
	big_map.big = true

	# Test zoom levels
	var init_zoom = Minimap.zoom_index
	Minimap.zoom(1) # zoom in
	if Minimap.zoom_index != clampi(init_zoom - 1, 0, Minimap.ZOOM_LEVELS.size() - 1):
		print("FAIL: zoom in calculation incorrect")
		success = false
	Minimap.zoom(-1) # zoom out
	Minimap.zoom(-1) # zoom out again

	print("  Zoom levels (%d steps): %s, current half: %f" % [
		Minimap.ZOOM_LEVELS.size(), str(Minimap.ZOOM_LEVELS), Minimap.view_half()
	])

	# 7. Test Declutter border logic
	print("\n[7] Testing Border Declutter...")
	var center = Vector2(94, 94)
	var lim = 83.0
	var pos1 = center + Vector2(lim, 0)
	mini._placed_border_markers.clear()
	var d1 = mini._declutter_border_pos(pos1, center, lim)
	mini._placed_border_markers.append(d1)
	var d2 = mini._declutter_border_pos(pos1, center, lim)
	mini._placed_border_markers.append(d2)
	print("  Border marker 1: %s, Border marker 2 (decluttered): %s" % [str(d1), str(d2)])
	if d1.distance_to(d2) < 15.0:
		print("FAIL: Declutter did not adequately space border markers!")
		success = false
	else:
		print("  Border declutter spacing OK: dist = %f" % d1.distance_to(d2))

	mini.free()
	big_map.free()

	if success:
		print("\n>>> ALL MINIMAP TESTS PASSED SUCCESSFULLY! <<<")
	else:
		print("\n>>> MINIMAP TESTS COMPLETED WITH FAILURES! <<<")

	quit(0 if success else 1)
