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

	# 4x Island radius check
	_check(PirateIslandClass.ISLAND_RADIUS >= 140.0, "Island radius is 4x expanded (RADIUS=%.1fm >= 140m)" % PirateIslandClass.ISLAND_RADIUS)

	# Height checks at different radii (Non-flat validation)
	var h_altar: float = island.call("_calc_island_height", 0.0, 0.0)
	var h_caldera_floor: float = island.call("_calc_island_height", 10.0, 0.0)
	var h_crater_rim: float = island.call("_calc_island_height", 23.5, 0.0)
	var h_mid_hill: float = island.call("_calc_island_height", 65.0, 0.0)
	var h_cove_landing: float = island.call("_calc_island_height", 0.0, -125.0)
	var h_deep_ocean: float = island.call("_calc_island_height", 150.0, 0.0)

	_check(h_altar > 18.0, "Central boss altar is high elevated platform (Y=%.2fm > 18m)" % h_altar)
	_check(h_caldera_floor < h_altar and h_caldera_floor >= 16.5, "Caldera floor is sunken beneath altar (Y=%.2fm)" % h_caldera_floor)
	_check(h_crater_rim > h_caldera_floor and h_crater_rim >= 24.0, "Crater rim towers above caldera floor (Y=%.2fm >= 24m)" % h_crater_rim)
	_check(h_mid_hill > 3.0 and h_mid_hill < h_crater_rim, "Mid mountain terrain forms rolling hillside (Y=%.2fm)" % h_mid_hill)
	_check(h_cove_landing <= 3.0 and h_cove_landing >= 0.0, "Northern cove landing is gently sloped beach near sea level (Y=%.2fm)" % h_cove_landing)
	_check(h_deep_ocean < -1.0, "Outer perimeter drops off into deep sea floor (Y=%.2fm)" % h_deep_ocean)

	# Verify Highland Lake
	var lake = island.get_node_or_null("HighlandLake")
	_check(lake != null, "HighlandLake node exists")
	if lake:
		var has_bridge := false
		for c in lake.get_children():
			if c is StaticBody3D:
				has_bridge = true
				break
		_check(has_bridge, "Highland lake has crossing footbridge")

	# Verify Island Forest (Trees with collision, boulders, flora)
	var forest = island.get_node_or_null("IslandForest")
	_check(forest != null, "IslandForest node exists")
	if forest:
		var prop_count := forest.get_child_count()
		_check(prop_count >= 100, "Island forest has abundant nature (%d nature items >= 100)" % prop_count)

	# Verify Wildlife: Majestic Grand Deer & Highland Pasture Cattle
	var wildlife = island.get_node_or_null("IslandWildlife")
	_check(wildlife != null, "IslandWildlife node exists")
	if wildlife:
		var animal_count := wildlife.get_child_count()
		_check(animal_count >= 10, "Island wildlife has abundant roaming fauna (%d animals >= 10)" % animal_count)
		var deer_found := 0
		var cow_found := 0
		var large_scale_ok := true
		for a in wildlife.get_children():
			if a is VillageDeer:
				deer_found += 1
				if a.scale.x < 2.0:
					large_scale_ok = false
			elif a is VillageCow:
				cow_found += 1
				if a.scale.x < 1.5:
					large_scale_ok = false
		_check(deer_found >= 6, "Island has 6+ majestic wild deer (found %d)" % deer_found)
		_check(cow_found >= 2, "Island has 2+ highland pasture cattle (found %d)" % cow_found)
		_check(large_scale_ok, "Island animals are scaled large (deer >= 2.0x, cattle >= 1.5x)")

	# Verify Buried Pirate Chests
	var buried = island.get_node_or_null("BuriedChests")
	_check(buried != null, "BuriedChests node exists under PirateIsland")
	if buried:
		var spot_count := buried.get_child_count()
		_check(spot_count == 5, "Island has exactly 5 buried pirate treasure caches (found %d)" % spot_count)
		var valid_chests := 0
		var has_shovels := 0
		for spot in buried.get_children():
			for sc in spot.get_children():
				if sc is ChestClass:
					valid_chests += 1
					_check(sc.is_in_group("buried_chests"), "Buried chest is in 'buried_chests' group")
					_check(sc.gold_min >= 300, "Buried chest has rich loot (min gold >= 300)")
				elif sc.name.begins_with("@") or sc is Node3D:
					if sc.get_child_count() >= 3: # Handle, Grip, Blade of shovel
						has_shovels += 1
		_check(valid_chests == 5, "All 5 buried spots contain functional Chest instances")
		_check(has_shovels >= 5, "All 5 buried spots feature iron excavation shovels")

	# Verify Secret Smuggler's Grotto & Hidden Treasure
	var grotto = island.get_node_or_null("SecretSmugglersGrotto")
	_check(grotto != null, "SecretSmugglersGrotto node exists")
	if grotto:
		var secret_chest: Chest = null
		var has_glow := false
		for c in grotto.get_children():
			if c is ChestClass:
				secret_chest = c
			if c is OmniLight3D:
				has_glow = true
		_check(secret_chest != null, "Hidden chest exists in secret grotto")
		if secret_chest:
			_check(secret_chest.golden == true, "Hidden chest is golden")
			_check(secret_chest.gold_min >= 800, "Hidden chest has massive gold stash (min >= 800)")
			_check(secret_chest.potions >= 5, "Hidden chest contains 5 potions")
		_check(has_glow, "Secret grotto has mystical emerald glow")

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

	# Verify Mob Positions: None in the sea!
	var mob_positions: Array[Vector3] = [
		PirateIslandClass.DOCK_GATE_POS,
		PirateIslandClass.LOWER_CAMP_POS,
		PirateIslandClass.LAKE_CAMP_POS,
		PirateIslandClass.LOOKOUT_POS,
		PirateIslandClass.ALTAR_POS
	]
	var all_mobs_dry := true
	for p in mob_positions:
		if p.y < 2.5:
			all_mobs_dry = false
	_check(all_mobs_dry, "All mob outpost locations are on dry elevated land (Y >= 2.5m, zero mobs in water)")

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
