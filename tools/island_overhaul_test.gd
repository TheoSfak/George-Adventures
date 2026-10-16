extends SceneTree

var _passed := 0
var _failed := 0


func _init() -> void:
	print("--- Running Island Overhaul Test Suite ---")
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: %s" % msg)
	else:
		_failed += 1
		printerr("  FAIL: %s" % msg)


func _run() -> void:
	# 1. Instantiate Village
	var village = (load("res://scripts/village.gd") as GDScript).new()
	village.name = "Village"
	root.add_child(village)

	# Allow ready to complete
	await process_frame
	await process_frame

	# --- Test 1: IslandSouthSea ---
	print("\n[1] Testing South Sea Coast...")
	var sea = village.get_node_or_null("SouthSeaCoast")
	_check(sea != null, "SouthSeaCoast node exists in Village")

	var ocean = sea.get_node_or_null("Ocean")
	_check(ocean != null, "Ocean node exists")

	var beach = sea.get_node_or_null("Beach")
	_check(beach != null, "Beach node exists")

	var lighthouse = sea.get_node_or_null("Lighthouse")
	_check(lighthouse != null, "Lighthouse node exists")
	if lighthouse:
		var has_chest := false
		var has_beacon := false
		for child in lighthouse.get_children():
			if child is Chest and child.golden:
				has_chest = true
			if child.name == "LanternRoom" or child is SpotLight3D:
				has_beacon = true
			for sub in child.get_children():
				if sub is SpotLight3D:
					has_beacon = true
		_check(has_chest, "Lighthouse Keeper's golden chest exists")
		_check(has_beacon, "Lighthouse rotating beacon light exists")

	var pier = sea.get_node_or_null("FishingPier")
	_check(pier != null, "Fishing Pier node exists")

	var shipwreck = sea.get_node_or_null("Shipwreck")
	_check(shipwreck != null, "Shipwreck node exists")
	if shipwreck:
		var has_wreck_chest := false
		for child in shipwreck.get_children():
			if child is Chest and child.golden:
				has_wreck_chest = true
		_check(has_wreck_chest, "Sunken shipwreck golden chest exists")

	# --- Test 2: IslandRiver ---
	print("\n[2] Testing River & Waterfall System...")
	var river = village.get_node_or_null("IslandRiver")
	_check(river != null, "IslandRiver node exists in Village")

	var waterfall = river.get_node_or_null("Waterfall")
	_check(waterfall != null, "Waterfall node exists")

	var cave = river.get_node_or_null("SecretWaterfallCave")
	_check(cave != null, "Secret Waterfall Cave node exists")
	if cave:
		var has_cave_chest := false
		for child in cave.get_children():
			if child is Chest and child.golden:
				has_cave_chest = true
		_check(has_cave_chest, "Secret cave golden chest exists behind the waterfall")

	var channel = river.get_node_or_null("Channel")
	_check(channel != null, "River channel segments exist")

	var bridges = river.get_node_or_null("Bridges")
	_check(bridges != null, "River bridges exist")
	if bridges:
		var bridge_count := 0
		for child in bridges.get_children():
			if child.name.begins_with("building_bridge") or child.name.begins_with("@Node3D"):
				bridge_count += 1
		_check(bridge_count >= 2, "At least 2 arched bridges placed across river")

	# --- Test 3: IslandHighlands ---
	print("\n[3] Testing North Highlands & Eagle's Vista...")
	var highlands = village.get_node_or_null("IslandHighlands")
	_check(highlands != null, "IslandHighlands node exists in Village")

	var terraces = highlands.get_node_or_null("Terraces")
	_check(terraces != null, "Highlands terraces exist")

	var trail = highlands.get_node_or_null("Trail")
	_check(trail != null, "Mountain switchback trail exists")

	var shrine = highlands.get_node_or_null("SummitShrine")
	_check(shrine != null, "Summit shrine & Eagle's Vista exist")
	if shrine:
		var has_summit_chest := false
		var has_bell_spot := false
		for child in shrine.get_children():
			if child is Chest and child.golden:
				has_summit_chest = true
			if child is InteractSpot:
				has_bell_spot = true
		_check(has_summit_chest, "Golden summit trophy chest exists at Eagle's Vista")
		_check(has_bell_spot, "Interactive mountain bell ringer spot exists")

	# --- Test 4: RollingHills ---
	print("\n[4] Testing Lowland Rolling Hills...")
	var hills = village.get_node_or_null("RollingHills")
	_check(hills != null, "RollingHills node exists in Village")
	if hills:
		_check(hills.get_child_count() >= 6, "At least 6 rolling hill formations placed across pastures")

	# --- Test 5: Border Opening ---
	print("\n[5] Testing Border Opening for Ocean Horizon...")
	var border = village.get_node_or_null("Border")
	_check(border != null, "Border node exists")
	var south_blocked := false
	if border:
		for child in border.get_children():
			var pos: Vector3 = child.position
			if pos.z > 95.0 and pos.x >= -140.0 and pos.x <= 40.0:
				south_blocked = true
				break
	_check(not south_blocked, "Southern border mountains/forests successfully cleared for open sea")

	# --- Test 6: Minimap & Greek Localization ---
	print("\n[6] Testing Minimap & Greek Strings...")
	var expected_places := ["lighthouse", "harbor", "waterfall", "bridge_meadow", "highlands", "shipwreck"]
	var minimap_keys: Array[String] = []
	for entry in Minimap.PLACES:
		minimap_keys.append(entry[0])
	for p in expected_places:
		_check(minimap_keys.has(p), "Minimap.PLACES has entry for '%s'" % p)
		_check(Strings.MAP_PLACES.has(p), "Strings.MAP_PLACES has Greek name for '%s'" % p)

	print("\n==================================================")
	print("Island Overhaul Summary: %d Passed, %d Failed" % [_passed, _failed])
	print("==================================================")

	village.queue_free()
	await process_frame
	quit(1 if _failed > 0 else 0)
