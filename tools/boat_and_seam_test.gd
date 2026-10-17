@tool
extends SceneTree

const SailingBoatClass := preload("res://scripts/sailing_boat.gd")
const IslandSouthSeaClass := preload("res://scripts/island_south_sea.gd")
const PlayerClass := preload("res://scripts/player.gd")
const GameMenuClass := preload("res://scripts/game_menu.gd")

var _passed := 0
var _failed := 0

func _check(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % msg)
	else:
		_failed += 1
		print("  FAIL: %s" % msg)

func _init_inputs() -> void:
	var actions := [
		"ui_cancel", "interact", "unstuck", "move_forward", "move_back",
		"strafe_left", "strafe_right", "turn_left", "turn_right", "run", "potion"
	]
	for a in actions:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

func _init() -> void:
	_init_inputs()
	print("--- Running Boat Interaction, Unstuck & Beach Seam Test Suite ---")

	_test_beach_seam_geometry()
	_test_boat_dismount_and_anti_reboard()
	_test_boat_esc_and_unstuck()
	_test_boat_rotation_and_heading_invariance()

	print("==================================================")
	print("Summary: %d Passed, %d Failed" % [_passed, _failed])
	print("==================================================")
	quit(_failed)

func _test_beach_seam_geometry() -> void:
	print("\n[1] Testing Beach Seam & Tucking Geometry...")
	var south_sea: Node = IslandSouthSeaClass.new()
	root.add_child(south_sea)
	south_sea._ready()

	# Check beach tuck height at northern seam
	var y_z83: float = south_sea.call("_calc_beach_height", 0.0, 83.0)
	var y_z84: float = south_sea.call("_calc_beach_height", 0.0, 84.0)
	var y_z85: float = south_sea.call("_calc_beach_height", 0.0, 85.0)
	var y_z88: float = south_sea.call("_calc_beach_height", 0.0, 88.0)

	_check(y_z83 < -0.05, "Beach mesh at Z=83 is tucked below meadow (Y=%.3f <= -0.05)" % y_z83)
	_check(y_z84 < -0.01 and y_z84 > -0.05, "Beach mesh at Z=84 is smoothly rising under meadow (Y=%.3f)" % y_z84)
	_check(absf(y_z85) < 0.001, "Beach mesh reaches exactly Y=0.0 at seam Z=85 (Y=%.3f)" % y_z85)
	_check(absf(y_z88) < 0.001, "Dry beach sand continues flat at Y=0.0 across bay (Y=%.3f)" % y_z88)

	# Check west bluff tapering at the seam
	var y_west_seam: float = south_sea.call("_calc_beach_height", -180.0, 83.5)
	var y_west_dune: float = south_sea.call("_calc_beach_height", -180.0, 110.0)
	_check(y_west_seam <= 0.0, "West bluff at northern seam does not protrude above meadow (Y=%.3f <= 0.0)" % y_west_seam)
	_check(y_west_dune > 2.0, "West bluff elevates smoothly south of seam (Y=%.3f > 2.0)" % y_west_dune)

	# Verify shader file contains aligned clipping condition
	var shader_file := FileAccess.open("res://shaders/ground.gdshader", FileAccess.READ)
	_check(shader_file != null, "Opened ground.gdshader successfully")
	if shader_file:
		var code := shader_file.get_as_text()
		_check("wpos.z >= 85.0 && wpos.x >= -195.0 && wpos.x <= 55.5" in code, "ground.gdshader clips meadow precisely at Z>=85 and X in [-195, 55.5]")

	south_sea.free()

func _test_boat_dismount_and_anti_reboard() -> void:
	print("\n[2] Testing Boat Dismount & Debounce Protection...")
	var boat: Node = SailingBoatClass.new()
	root.add_child(boat)
	boat._ready()

	var player: Player = PlayerClass.new()
	player.position = Vector3(-35.0, 0.0, 122.0)
	root.add_child(player)

	# Board boat
	boat.call("board", player)
	_check(boat.get("is_sailing") == true, "Player successfully boarded boat")
	_check(player.sailing == true, "Player sailing flag is true")
	_check(player.boat == boat, "Player boat reference is set")
	_check(player.busy == true, "Player busy flag is true while sailing")

	# Dismount boat
	boat.call("disembark")
	_check(boat.get("is_sailing") == false, "Boat is_sailing is false after disembark")
	_check(player.sailing == false, "Player sailing flag cleared after disembark")
	_check(player.boat == null, "Player boat reference cleared after disembark")
	_check(player.busy == false, "Player busy flag cleared after disembark")

	# Check debounce cooldowns
	var boat_cd: float = float(boat.get("_board_cooldown"))
	var player_swallow: float = float(player.get("_interact_swallow"))
	_check(boat_cd >= 0.4, "Boat board cooldown is active (%.2fs >= 0.4s)" % boat_cd)
	_check(player_swallow >= 0.3, "Player interact swallow is active (%.2fs >= 0.3s)" % player_swallow)

	# Attempt immediate re-embarking during cooldown (simulating duplicate input in same frame)
	boat.call("interact", player)
	_check(boat.get("is_sailing") == false, "Duplicate interact ignored during cooldown; player did NOT re-embark")
	_check(str(boat.call("interact_prompt")) == "", "Boat interact prompt is hidden during cooldown")

	# Simulate cooldown expiring
	boat.set("_board_cooldown", 0.0)
	_check("Σαλπάρισμα" in str(boat.call("interact_prompt")), "Boat interact prompt reappears once cooldown finishes")

	player.free()
	boat.free()

func _test_boat_esc_and_unstuck() -> void:
	print("\n[3] Testing Boat ESC Pause Menu & Unstuck Integration...")
	var boat: Node = SailingBoatClass.new()
	root.add_child(boat)
	boat._ready()

	var player: Player = PlayerClass.new()
	player.position = Vector3(-35.0, 0.0, 122.0)
	player._spawn_point = Vector3(0.0, 0.0, 0.0)
	root.add_child(player)

	boat.call("board", player)
	_check(player.sailing == true and player.busy == true, "Player on boat: sailing=true and busy=true")

	# Test 1: GameMenu ESC handling while player is sailing
	var menu: GameMenu = GameMenuClass.new()
	root.add_child(menu)
	menu.call("_build_root")
	menu.set("_player", player)

	var esc_event := InputEventAction.new()
	esc_event.action = "ui_cancel"
	esc_event.pressed = true

	menu._unhandled_input(esc_event)
	_check(menu.get("_open") == true, "ESC key successfully opened pause menu while player is sailing (not blocked by busy)")

	# Test 2: Unstuck while sailing decouples boat and teleports player to village
	player.unstuck()
	_check(player.sailing == false, "Unstuck cleared player sailing flag")
	_check(player.boat == null, "Unstuck cleared player boat reference")
	_check(player.busy == false, "Unstuck cleared player busy flag")
	_check(boat.get("is_sailing") == false, "Unstuck cleanly disembarked the boat")
	_check(boat.get("current_player") == null, "Boat current_player is null")
	var p_pos: Vector3 = player.global_position if player.is_inside_tree() else player.position
	_check(p_pos.distance_to(player._spawn_point) < 1.0, "Player teleported safely to village spawn point (X=%.1f, Z=%.1f)" % [p_pos.x, p_pos.z])

	menu.free()
	player.free()
	boat.free()

func _test_boat_rotation_and_heading_invariance() -> void:
	print("\n[4] Testing Boat Rotation, Heading Invariance & Walk Direction...")
	var boat: SailingBoat = SailingBoatClass.new()
	root.add_child(boat)
	boat._ready()

	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	player.position = Vector3(-24.0, 0.0, 112.0)
	root.add_child(player)

	# 1. Player starts on foot
	_check(player.rotation == Vector3.ZERO, "Player starts with exact Vector3.ZERO rotation")
	_check(absf(player.get_heading() - PI) < 0.01, "Player starts with heading PI (facing -Z)")

	# 2. Board boat facing South (_yaw = PI, towards Pirate Island)
	boat.set("_yaw", PI)
	boat.rotation.y = PI
	boat.call("board", player)

	_check(player.sailing == true, "Player is sailing on the boat")
	_check(player.rotation == Vector3.ZERO, "Player CharacterBody3D rotation remains Vector3.ZERO after boarding")
	# Boat forward is +Z, so player heading facing forward should be _yaw + PI = 2*PI == 0.0
	var h_south: float = player.get_heading()
	_check(absf(sin(h_south)) < 0.01 and cos(h_south) > 0.99, "Player heading faces boat bow along +Z (sin=%.2f, cos=%.2f)" % [sin(h_south), cos(h_south)])

	# 3. Simulate sailing physics tick on the boat
	boat._physics_process(0.016)
	_check(player.rotation == Vector3.ZERO, "Player rotation is preserved as Vector3.ZERO during sailing physics process")

	# 4. Disembark on the Pirate Island
	boat.call("disembark")
	_check(player.sailing == false, "Player disembarked onto island")
	_check(player.rotation == Vector3.ZERO, "Player rotation is strictly Vector3.ZERO after disembarking on island (NOT backwards!)")
	var h_island: float = player.get_heading()
	_check(absf(sin(h_island)) < 0.01 and cos(h_island) > 0.99, "Player disembarks facing forward (cos=%.2f > 0.99)" % cos(h_island))

	# 5. Simulate player forward movement on island: verify velocity direction matches facing
	var facing := Vector3(sin(player.get_heading()), 0.0, cos(player.get_heading()))
	_check(facing.z > 0.99, "Facing vector points forward along +Z (z=%.2f)" % facing.z)

	# 6. Re-board boat and steer diagonally (e.g. returning to Agios Vlasis at 45 degree angle)
	boat.set("_board_cooldown", 0.0)
	boat.set("_yaw", 0.785398) # 45 degrees diagonal
	boat.rotation.y = 0.785398
	boat.call("board", player)
	_check(player.rotation == Vector3.ZERO, "Player rotation remains Vector3.ZERO while boarding diagonally")

	boat._physics_process(0.016)
	_check(player.rotation == Vector3.ZERO, "Player rotation remains Vector3.ZERO during diagonal sailing")

	# 7. Disembark at Agios Vlasis dock
	boat.call("disembark")
	_check(player.rotation == Vector3.ZERO, "Player rotation remains strictly Vector3.ZERO after disembarking at Agios Vlasis (NO diagonal drift!)")

	# 8. Unstuck safeguard test
	player.rotation.y = 1.57 # intentionally perturb
	player.unstuck()
	_check(player.rotation == Vector3.ZERO, "Player unstuck forces rotation back to Vector3.ZERO")

	player.free()
	boat.free()

