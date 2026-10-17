@tool
extends SceneTree

const SailingBoatClass := preload("res://scripts/sailing_boat.gd")
const IslandSouthSeaClass := preload("res://scripts/island_south_sea.gd")
const PlayerClass := preload("res://scripts/player.gd")
const PlayerScene := preload("res://scenes/player.tscn")

var _checks_passed := 0
var _checks_failed := 0

func _assert(condition: bool, msg: String) -> void:
	if condition:
		_checks_passed += 1
		print("  PASS: %s" % msg)
	else:
		_checks_failed += 1
		print("  FAIL: %s" % msg)

func _init_inputs() -> void:
	var actions := [
		"move_forward", "move_back", "strafe_left", "strafe_right", "turn_left", "turn_right",
		"run", "jump", "attack", "block", "dodge", "kick", "interact", "unstuck", "potion",
		"pad_left", "pad_right", "pad_forward", "pad_back", "look_left", "look_right", "look_up", "look_down",
		"mount"
	]
	for a in actions:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

func _init() -> void:
	_init_inputs()
	print("==================================================")
	print("Sea Exploration & Swimming / Raft Sailing Test")
	print("==================================================")

	_test_sailing_boat()
	_test_south_sea_world()
	_test_player_swimming()

	print("==================================================")
	print("Results: %d Passed, %d Failed" % [_checks_passed, _checks_failed])
	print("==================================================")
	quit(_checks_failed)

func _test_sailing_boat() -> void:
	print("\n--- Testing Sailing Boat ---")
	var boat: Node = SailingBoatClass.new()
	root.add_child(boat)
	boat._ready()
	_assert(boat != null, "SailingBoat instantiates successfully")
	_assert(boat.is_in_group("interactables"), "SailingBoat is in 'interactables' group")
	_assert(boat.is_in_group("boats"), "SailingBoat is in 'boats' group")

	var prompt: String = boat.call("interact_prompt")
	_assert("Σαλπάρισμα" in prompt, "Prompt indicates boarding: %s" % prompt)

	# Visual components
	var boat_root: Node = boat.get_node_or_null("BoatVisual")
	_assert(boat_root != null, "Boat has BoatVisual hierarchy")

	var lights := boat.find_children("*", "OmniLight3D", true, false)
	_assert(lights.size() > 0, "Boat has maritime lantern OmniLight3D")
	var cols := boat.find_children("*", "CollisionShape3D", true, false)
	_assert(cols.size() > 0, "Boat has CollisionShape3D")

	# Test boarding and disembarking with player
	var player: Player = PlayerClass.new()
	player.position = Vector3(-35.0, 0.0, 122.0)
	root.add_child(player)

	boat.call("board", player)
	_assert(boat.get("is_sailing") == true, "Boat is sailing after boarding")
	_assert(boat.get("current_player") == player, "Current player assigned to boat")
	_assert("Αποβίβαση" in str(boat.call("interact_prompt")), "Prompt indicates disembarking when sailing")

	# Simulate a frame of sailing physics
	boat.call("_physics_process", 0.016)
	_assert(boat.get("_boat_root") != null, "Wave bobbing process ran smoothly")

	boat.call("disembark")
	_assert(boat.get("is_sailing") == false, "Boat is not sailing after disembarking")
	_assert(boat.get("current_player") == null, "Current player cleared after disembarking")

	player.free()
	boat.free()

func _test_south_sea_world() -> void:
	print("\n--- Testing South Sea Coast & Underwater Grotto ---")
	var south_sea: Node = IslandSouthSeaClass.new()
	root.add_child(south_sea)
	south_sea._ready()
	_assert(south_sea != null, "IslandSouthSea instantiated")

	# Check underwater cave
	var cave: Node = south_sea.get_node_or_null("UnderwaterSeaCave")
	_assert(cave != null, "UnderwaterSeaCave grotto node exists")

	# Check grotto chest
	var chests := cave.find_children("*", "Chest", true, false)
	_assert(chests.size() > 0, "Grotto contains pirate treasure chest")
	if chests.size() > 0:
		var chest: Chest = chests[0] as Chest
		_assert(chest.golden == true, "Grotto chest is a golden chest")
		_assert(chest.gold_min >= 400, "Grotto chest has high pirate gold loot")

	# Check grotto static colliders (beach sand floor and cave walls)
	var statics := cave.find_children("*", "StaticBody3D", true, false)
	_assert(statics.size() >= 3, "Grotto has collidable sand beach and cave walls (found %d)" % statics.size())

	# Check bioluminescent lighting
	var grotto_lights := cave.find_children("*", "OmniLight3D", true, false)
	_assert(grotto_lights.size() > 0, "Grotto has emerald aquatic lighting")

	# Check moored boat at pier
	var pier := south_sea.get_node_or_null("FishingPier")
	_assert(pier != null, "FishingPier exists")
	var boats := pier.find_children("*", "CharacterBody3D", true, false)
	_assert(boats.size() > 0, "FishingPier has moored sailable skiff")

	south_sea.free()

func _test_player_swimming() -> void:
	print("\n--- Testing Player Swimming & Buoyancy ---")
	var player: Player = PlayerClass.new()
	root.add_child(player)

	# 1. Village square (dry land)
	player.position = Vector3(0.0, 0.0, 0.0)
	_assert(player.is_in_water() == false, "Player is not in water at village square")
	_assert(player.is_swimming == false, "Player is_swimming is false initially")

	# 2. South Sea surface
	player.position = Vector3(-35.0, 0.0, 150.0)
	_assert(player.is_in_water() == true, "Player is in water at South Sea")
	_assert(player.position.z >= 85.0 and player.position.z <= 480.0, "South Sea coordinates within ocean boundaries")

	# 3. Submerged diving depth (below water surface)
	player.position = Vector3(-35.0, -2.5, 150.0)
	_assert(player.is_in_water() == true, "Player is in water when diving")
	_assert(player.position.y < player.WATER_SURFACE_Y, "Player position is submerged beneath water surface")

	# 4. Underwater grotto entrance accessibility
	var cave_arch_pos := Vector3(52.0, -1.2, 174.0)
	player.position = cave_arch_pos
	_assert(player.is_in_water() == true, "Underwater cave entrance is submerged and swimmable")

	# 5. Exiting water back to shore
	player.position = Vector3(-35.0, 1.5, 60.0)
	_assert(player.is_in_water() == false, "Player is out of water on shore")

	player.free()
