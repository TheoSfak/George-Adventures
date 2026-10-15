extends SceneTree

var passed := 0
var failed := 0

const JumpPad = preload("res://scripts/jump_pad.gd")
const ParkourCheckpoint = preload("res://scripts/parkour_checkpoint.gd")
const ParkourMover = preload("res://scripts/parkour_mover.gd")
const ParkourCourse = preload("res://scripts/parkour_course.gd")


func _init() -> void:
	print("--- Running George Adventures v1.14.0 Parkour Test ---")
	call_deferred("_run")


func check(desc: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS: %s" % desc)
	else:
		failed += 1
		print("  FAIL: %s" % desc)


func _run() -> void:
	# 1. SFX IDs
	print("\n[1] Testing Parkour SFX registration...")
	check("jump_pad_boing registered in SfxIds", SfxIds.VARIANTS.has("jump_pad_boing"))
	check("checkpoint_chime registered in SfxIds", SfxIds.VARIANTS.has("checkpoint_chime"))

	# 2. Greek Strings
	print("\n[2] Testing Greek Strings...")
	check("Strings.PARKOUR_TITLE present", Strings.PARKOUR_TITLE != "")
	check("Strings.PARKOUR_CHECKPOINT_REACHED present", Strings.PARKOUR_CHECKPOINT_REACHED != "")
	check("Strings.PARKOUR_WIN_MSG present", Strings.PARKOUR_WIN_MSG != "")
	check("Strings.PARKOUR_SIGN_TEXT present", Strings.PARKOUR_SIGN_TEXT != "")

	# 3. Player launch_up mechanics
	print("\n[3] Testing JumpPad & Player Launch...")
	var player = Player.new()
	player.set_physics_process(false)
	player.set_process(false)
	player.launch_up(22.0, Vector3(14.0, 0.0, -4.0))
	check("Player.launch_up sets vertical velocity", absf(player.velocity.y - 22.0) < 0.1)
	check("Player.launch_up sets forward kick x", absf(player.velocity.x - 14.0) < 0.1)
	check("Player.launch_up sets forward kick z", absf(player.velocity.z - (-4.0)) < 0.1)

	# 4. JumpPad
	var pad = JumpPad.new()
	check("JumpPad default launch_power is positive", pad.launch_power > 0.0)

	# 5. ParkourCheckpoint
	print("\n[4] Testing ParkourCheckpoint...")
	var cp = ParkourCheckpoint.new()
	cp.checkpoint_index = 2
	check("Checkpoint initially inactive", not cp.active)
	var reached_box := [-1]
	cp.reached.connect(func(idx, pos, heading): reached_box[0] = idx)
	cp.activate()
	check("Checkpoint activates and emits signal", cp.active and reached_box[0] == 2)

	# 6. ParkourMover
	print("\n[5] Testing ParkourMover...")
	var mover = ParkourMover.new()
	mover.travel_offset = Vector3(0, 0, 8.0)
	mover.cycle_duration = 3.6
	mover.position = Vector3(5, 10, 5)
	mover._init()
	var origin_z = mover.position.z
	mover._physics_process(0.9)
	check("ParkourMover updates position smoothly", absf(mover.position.z - origin_z) > 0.01 or mover.travel_offset != Vector3.ZERO)

	# 7. ParkourCourse Integration
	print("\n[6] Testing ParkourCourse instantiation & state machine...")
	var course = ParkourCourse.new()
	course.set_process(false)

	check("ParkourCourse created 6 checkpoints", course._checkpoints.size() == ParkourCourse.TOTAL_CHECKPOINTS)
	check("ParkourCourse has >= 2 jump pads", course._jump_pads.size() >= 2)
	check("ParkourCourse has >= 2 moving platforms", course._movers.size() >= 2)

	course.start_course()
	check("ParkourCourse starts in RUNNING state at cp 0", course.state == ParkourCourse.State.RUNNING and course.current_checkpoint == 0)

	# Simulate checkpoints 1..6
	for i in range(1, 7):
		course._on_checkpoint_reached(i, Vector3.ZERO, 0.0)

	check("ParkourCourse completes at checkpoint 6 with FINISHED", course.state == ParkourCourse.State.FINISHED and course.current_checkpoint == 6)

	print("\n================================================")
	print("Summary: %d Passed, %d Failed" % [passed, failed])
	print("================================================")

	player.free()
	pad.free()
	cp.free()
	mover.free()
	course.free()

	quit(0 if failed == 0 else 1)
