extends SceneTree

var passed := 0
var failed := 0

const ParkourCourse = preload("res://scripts/parkour_course.gd")


func _init() -> void:
	print("--- Running Parkour Finish Flow & Return Portal Test ---")
	call_deferred("_run")


func check(desc: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS: %s" % desc)
	else:
		failed += 1
		print("  FAIL: %s" % desc)


func _run() -> void:
	var dummy_hud = Node.new()
	dummy_hud.name = "DummyHud"
	dummy_hud.add_to_group("hud")
	dummy_hud.set_script(GDScript.new())
	root.add_child(dummy_hud)

	# [1] Strings presence
	print("\n[1] Checking Greek Strings for Return Portal & Close Tooltip...")
	check("PARKOUR_NEED_FINISH defined", Strings.PARKOUR_NEED_FINISH != "")
	check("PARKOUR_NEED_CHEST defined", Strings.PARKOUR_NEED_CHEST != "")
	check("PARKOUR_PORTAL_ACTIVE defined", Strings.PARKOUR_PORTAL_ACTIVE != "")
	check("PARKOUR_RETURN_SUCCESS defined", Strings.PARKOUR_RETURN_SUCCESS != "")
	check("PARKOUR_HUD_CLOSE_TOOLTIP defined", Strings.PARKOUR_HUD_CLOSE_TOOLTIP != "")
	check("PARKOUR_COMPLETED_STATUS defined", Strings.PARKOUR_COMPLETED_STATUS != "")

	# [2] Test course instantiation and initial states
	print("\n[2] Checking initial states of return portal and HUD...")
	var course = ParkourCourse.new()
	course.set_process(false)
	course.set_physics_process(false)
	root.add_child(course)

	check("Course starts with portal inactive", not course._return_portal_active)
	check("Course has _return_trigger_area", course._return_trigger_area != null)
	check("Course has _trophy_chest", course._trophy_chest != null)
	check("Course has _hud_panel", course._hud_panel != null)
	check("Return pad beam initially hidden", course._return_pad_beam != null and not course._return_pad_beam.visible)

	var player = Player.new()
	player.set_physics_process(false)
	player.set_process(false)
	course.add_child(player)
	player.global_position = Vector3(100.0, 100.0, 100.0)
	course._player = player

	# [3] Step on return pad before finishing or opening chest
	print("\n[3] Testing return pad blocked when not finished...")
	course.start_course()
	check("Course RUNNING and HUD visible", course.state == ParkourCourse.State.RUNNING and course._hud_panel.visible)
	
	course._on_return_pad_entered(player)
	check("Player NOT teleported home", player.global_position.distance_to(Vector3(0.0, 0.5, 5.0)) > 1.0)
	check("Portal remains inactive", not course._return_portal_active)

	# [4] Reach Checkpoint 6 (finish line) but chest NOT opened
	print("\n[4] Testing finish line reached without opening chest...")
	for i in range(1, 7):
		course._on_checkpoint_reached(i, Vector3.ZERO, 0.0)

	check("Course state is FINISHED", course.state == ParkourCourse.State.FINISHED)
	check("HUD hint shows completed", course._hud_hint_label.text == Strings.PARKOUR_COMPLETED_STATUS)
	check("Portal STILL inactive because chest not opened", not course._return_portal_active)
	check("Pad beam still hidden", not course._return_pad_beam.visible)

	course._on_return_pad_entered(player)
	check("Player STILL NOT teleported home", player.global_position.distance_to(Vector3(0.0, 0.5, 5.0)) > 1.0)

	# [5] Open the trophy chest -> portal activates!
	print("\n[5] Opening trophy chest activates portal...")
	course._trophy_chest.interact(player)
	check("Trophy chest marked opened", course._trophy_chest.opened)
	check("Portal is now ACTIVE", course._return_portal_active)
	check("Pad beam is now VISIBLE", course._return_pad_beam.visible)
	check("Pad light energy is active", course._return_pad_light.light_energy > 1.0)

	# [6] Step on activated return pad -> teleports home safely & closes HUD card!
	print("\n[6] Stepping on activated pad teleports home & closes HUD card...")
	course._on_return_pad_entered(player)
	check("Player teleported to village square", player.global_position.distance_to(Vector3(0.0, 0.5, 5.0)) < 0.1)
	check("HUD panel automatically closed upon teleport", not course._hud_panel.visible)

	# [7] Test Close [X] button
	print("\n[7] Testing close [X] button on HUD panel...")
	course.start_course()
	check("HUD panel visible on new course start", course._hud_panel.visible)
	# Find close button inside HUD panel
	var close_btn: Button = null
	for child in course._hud_panel.find_children("*", "Button", true, false):
		if (child as Button).text == "✕":
			close_btn = child as Button
			break
	check("Close [X] button found in HUD panel", close_btn != null)
	if close_btn != null:
		close_btn.pressed.emit()
		check("Clicking [X] button closes HUD panel immediately", not course._hud_panel.visible)

	# [8] Test reverse order: Open chest FIRST, then touch checkpoint 6
	print("\n[8] Testing reverse order (chest first, then finish CP)...")
	course.start_course()
	player.global_position = Vector3(100.0, 100.0, 100.0)
	check("Portal reset to inactive on restart", not course._return_portal_active)
	check("Chest reset to closed on restart", not course._trophy_chest.opened)
	check("Pad beam hidden on restart", not course._return_pad_beam.visible)

	# Open chest first
	course._trophy_chest.interact(player)
	check("Chest opened", course._trophy_chest.opened)
	check("Portal NOT active yet because finish CP not touched", not course._return_portal_active)

	# Now reach checkpoints 1..6
	for i in range(1, 7):
		course._on_checkpoint_reached(i, Vector3.ZERO, 0.0)

	check("Course FINISHED", course.state == ParkourCourse.State.FINISHED)
	check("Portal activated after finish CP touched with chest already opened", course._return_portal_active)
	check("Pad beam visible", course._return_pad_beam.visible)

	course._on_return_pad_entered(player)
	check("Player teleported home in reverse order flow", player.global_position.distance_to(Vector3(0.0, 0.5, 5.0)) < 0.1)
	check("HUD panel closed", not course._hud_panel.visible)

	print("\n================================================")
	print("Summary: %d Passed, %d Failed" % [passed, failed])
	print("================================================")

	course.free()
	dummy_hud.free()

	if failed > 0:
		quit(1)
	else:
		quit(0)
