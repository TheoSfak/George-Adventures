@tool
extends SceneTree

const IslandSouthSeaClass := preload("res://scripts/island_south_sea.gd")
const PirateIslandClass := preload("res://scripts/pirate_island.gd")
const SailingBoatClass := preload("res://scripts/sailing_boat.gd")
const ChestClass := preload("res://scripts/chest.gd")
const NpcClass := preload("res://scripts/npc.gd")
const EnemiesScript := preload("res://scripts/enemies.gd")

var _passed := 0
var _failed := 0
var _quests_mgr: Node = null

func _check(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % msg)
	else:
		_failed += 1
		print("  FAIL: %s" % msg)

func _init() -> void:
	if not root.has_node("Quests"):
		_quests_mgr = (load("res://scripts/quests.gd") as GDScript).new()
		_quests_mgr.name = "Quests"
		root.add_child(_quests_mgr)
	else:
		_quests_mgr = root.get_node("Quests")

	print("--- Running Pirate Island & Captain Babis Quest Test Suite ---")

	_test_quest_and_npc_definitions()
	_test_south_sea_camp_and_npc()
	_test_pirate_island_geography_and_volcano()
	_test_boat_navigation_range()
	_test_chest_and_quest_flow()

	print("==================================================")
	print("Summary: %d Passed, %d Failed" % [_passed, _failed])
	print("==================================================")
	quit(_failed)

func _test_quest_and_npc_definitions() -> void:
	print("\n[1] Testing Quest & NPC Data Definitions...")

	# 1. Quest existence and structure
	_check(QuestData.QUESTS.has("pirate_island"), "Quest 'pirate_island' exists in QuestData")
	if QuestData.QUESTS.has("pirate_island"):
		var q: Dictionary = QuestData.QUESTS["pirate_island"]
		_check(q["giver"] == "babis", "Quest giver is 'babis'")
		_check(q["turn_in"] == "babis", "Quest turn_in is 'babis'")
		_check(q["requires"].has("bell"), "Quest requires 'bell'")

		var objs: Array = q["objectives"]
		_check(objs.size() == 3, "Quest has exactly 3 objectives")

		var has_reach := false
		var has_kill := false
		var has_item := false
		for o in objs:
			if o["type"] == "reach" and o["place"] == "pirate_island":
				has_reach = true
			if o["type"] == "kill" and o["target"] == "pirate_captain":
				has_kill = true
			if o["type"] == "collect" and o["item"] == "pirate_treasure":
				has_item = true

		_check(has_reach, "Objective 1: reach pirate_island")
		_check(has_kill, "Objective 2: kill pirate_captain")
		_check(has_item, "Objective 3: collect pirate_treasure")

	# 2. NPC Babis existence
	_check(QuestData.NPCS.has("babis"), "NPC 'babis' exists in QuestData")
	if QuestData.NPCS.has("babis"):
		var npc_def: Dictionary = QuestData.NPCS["babis"]
		_check("Μπάμπης" in npc_def["name"], "NPC name contains 'Μπάμπης'")
		_check(npc_def.has("idle") and npc_def["idle"].size() > 0, "NPC has Greek idle dialogue entries")

	# 3. Quest items & mobs
	_check(QuestData.ITEMS.has("pirate_treasure"), "Item 'pirate_treasure' exists in QuestData")
	_check("pirate_corsair" in QuestData.NOT_SKELETONS, "pirate_corsair is categorized in NOT_SKELETONS")
	_check("pirate_captain" in QuestData.NOT_SKELETONS, "pirate_captain is categorized in NOT_SKELETONS")

	# 4. Enemies definition
	_check(EnemiesScript.KINDS.has("pirate_corsair"), "Enemy def 'pirate_corsair' exists in EnemiesScript.KINDS")
	_check(EnemiesScript.KINDS.has("pirate_captain"), "Enemy def 'pirate_captain' exists in EnemiesScript.KINDS")
	if EnemiesScript.KINDS.has("pirate_captain"):
		var cap: Dictionary = EnemiesScript.KINDS["pirate_captain"]
		_check(cap.get("max_health", 0) >= 300, "pirate_captain has boss-tier HP (>= 300)")
		_check(cap.get("respawn_after", 0.0) == 60.0, "pirate_captain has 60s boss respawn timer")

func _test_south_sea_camp_and_npc() -> void:
	print("\n[2] Testing South Sea Coast Camp & Captain Babis...")
	var south_sea: Node = IslandSouthSeaClass.new()
	south_sea._ready()

	# Camp existence
	var camp = south_sea.get_node_or_null("CaptainBabisCamp")
	_check(camp != null, "Node 'CaptainBabisCamp' exists under IslandSouthSea")
	_check(camp != null and camp.is_in_group("camp_babis"), "Camp is added to group 'camp_babis'")

	if camp:
		# Find NPC inside camp
		var babis_npc: Npc = null
		for c in camp.get_children():
			if c is Npc and c.npc_id == "babis":
				babis_npc = c
				break
		_check(babis_npc != null, "NPC 'babis' is instantiated inside the beach camp")
		if babis_npc:
			_check(babis_npc.position.distance_to(Vector3(-22.0, 0.0, 92.0)) < 0.1, "Captain Babis is placed at dry beach sand position (-22, 0, 92)")

		# Check Campfire light
		var has_light := false
		for c in camp.get_children():
			if c is OmniLight3D:
				has_light = true
				break
		_check(has_light, "Campfire warm OmniLight3D exists in Babis's camp")

	# Pirate Island existence under South Sea
	var island = south_sea.get_node_or_null("PirateVolcanoIsland")
	_check(island != null, "Node 'PirateVolcanoIsland' is attached to IslandSouthSea")
	_check(island != null and island.is_in_group("pirate_island"), "Pirate Island is in group 'pirate_island'")

	south_sea.free()

func _test_pirate_island_geography_and_volcano() -> void:
	print("\n[3] Testing Non-Flat Procedural Volcanic Island Terrain...")
	var island = PirateIslandClass.new()
	island._ready()

	# Height checks at different radii (Non-flat validation)
	var h_altar: float = island.call("_calc_island_height", 0.0, 0.0)
	var h_caldera_floor: float = island.call("_calc_island_height", 8.0, 0.0)
	var h_crater_rim: float = island.call("_calc_island_height", 14.5, 0.0)
	var h_mid_hill: float = island.call("_calc_island_height", 35.0, 0.0)
	var h_cove_landing: float = island.call("_calc_island_height", 0.0, -35.0)
	var h_deep_ocean: float = island.call("_calc_island_height", 75.0, 0.0)

	_check(h_altar > 15.0, "Central boss altar is high elevated platform (Y=%.2fm > 15m)" % h_altar)
	_check(h_caldera_floor < h_altar and h_caldera_floor > 14.0, "Caldera floor is sunken beneath altar (Y=%.2fm)" % h_caldera_floor)
	_check(h_crater_rim > h_caldera_floor and h_crater_rim >= 18.0, "Crater rim towers above caldera floor (Y=%.2fm >= 18m)" % h_crater_rim)
	_check(h_mid_hill > 3.0 and h_mid_hill < h_crater_rim, "Mid mountain terrain forms steep hillside (Y=%.2fm)" % h_mid_hill)
	_check(h_cove_landing <= 1.8 and h_cove_landing >= 0.0, "Northern cove landing is gently sloped beach at sea level (Y=%.2fm)" % h_cove_landing)
	_check(h_deep_ocean < -1.0, "Outer perimeter drops off into deep sea floor (Y=%.2fm)" % h_deep_ocean)

	# Verify Caldera Lava Lake
	var lava = island.get_node_or_null("CalderaMagma")
	_check(lava != null, "CalderaMagma node exists")
	if lava:
		var has_lava_light := false
		for c in lava.get_children():
			if c is OmniLight3D:
				has_lava_light = true
				break
		_check(has_lava_light, "Caldera has glowing pulsing magma light")

	# Verify Cove Dock and Pier
	var cove = island.get_node_or_null("PirateCove")
	_check(cove != null, "PirateCove landing area exists")

	# Verify Crater Arena & Cursed Chest
	var arena = island.get_node_or_null("CraterArena")
	_check(arena != null, "CraterArena node exists")
	if arena:
		var chest: Chest = null
		for c in arena.get_children():
			if c is ChestClass:
				chest = c
				break
		_check(chest != null, "Cursed Pirate Chest exists on the altar")
		if chest:
			_check(chest.golden == true, "Pirate chest is golden")
			_check(chest.quest_item == "pirate_treasure", "Pirate chest has quest_item = 'pirate_treasure'")

	island.free()

func _test_boat_navigation_range() -> void:
	print("\n[4] Testing Boat Navigation Range into Open Sea...")
	_check(SailingBoatClass.MIN_Z <= 110.0, "Boat MIN_Z allows navigating from mainland pier (MIN_Z=%.1f)" % SailingBoatClass.MIN_Z)
	_check(SailingBoatClass.MAX_Z >= 550.0, "Boat MAX_Z allows free sailing past Pirate Island (MAX_Z=%.1f >= 550)" % SailingBoatClass.MAX_Z)
	_check(SailingBoatClass.OPEN_SEA_MIN_X <= -200.0, "Boat OPEN_SEA_MIN_X allows wide sea exploration (%.1f)" % SailingBoatClass.OPEN_SEA_MIN_X)
	_check(SailingBoatClass.OPEN_SEA_MAX_X >= 150.0, "Boat OPEN_SEA_MAX_X allows wide sea exploration (%.1f)" % SailingBoatClass.OPEN_SEA_MAX_X)

func _test_chest_and_quest_flow() -> void:
	print("\n[5] Testing Chest Quest Item Reporting & Flow...")
	var q = _quests_mgr
	q.reset()

	# Verify Quests state setup
	q.state["pirate_island"] = q.S.ACTIVE
	q.progress["pirate_island"] = [0, 0, 0]

	# Test 1: Reach island reporting
	q.report_reach("pirate_island")
	_check(q.progress["pirate_island"][0] == 1, "report_reach('pirate_island') advanced objective 0 to 1")

	# Test 2: Kill boss reporting
	q.report_kill("pirate_captain")
	_check(q.progress["pirate_island"][1] == 1, "report_kill('pirate_captain') advanced objective 1 to 1")

	# Test 3: Opening chest reports quest item
	q.report_item("pirate_treasure")
	_check(q.progress["pirate_island"][2] == 1, "report_item('pirate_treasure') advanced objective 2 to 1")
	_check(q.state["pirate_island"] == q.S.READY, "Quest transitioned to READY after all 3 objectives completed")

	# Test 4: Marker for Babis
	var marker: String = q.marker_for("babis")
	_check(marker == "?", "Quest turn-in marker for Captain Babis is '?' when ready (got '%s')" % marker)
