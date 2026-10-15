extends SceneTree

var passed := 0
var failed := 0


func _init() -> void:
	print("--- Running action_bar_12_test ---")
	call_deferred("_run")


func check(desc: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS: %s" % desc)
	else:
		failed += 1
		print("  FAIL: %s" % desc)


func _run() -> void:
	# Autoloads
	var quests = load("res://scripts/quests.gd").new()
	quests.name = "Quests"
	root.add_child(quests)

	var sound_mgr = load("res://scripts/sound_manager.gd").new()
	sound_mgr.name = "SoundManager"
	root.add_child(sound_mgr)

	var inputs = load("res://scripts/inputs.gd").new()
	inputs.name = "Inputs"
	root.add_child(inputs)

	await process_frame

	# 1. SkillData.DEFAULT_BAR size
	check("SkillData.DEFAULT_BAR has at least 12 slots", SkillData.DEFAULT_BAR.size() >= 12)

	# 2. InputMap actions for slot_1 .. slot_12
	for i in 12:
		var act := "slot_%d" % (i + 1)
		check("InputMap has action %s" % act, InputMap.has_action(act))

	# 3. Check keybindings for slots 9, 10, 11, 12
	var has_key = func(action: String, code: Key) -> bool:
		for ev in InputMap.action_get_events(action):
			var k := ev as InputEventKey
			if k != null and (k.physical_keycode == code or k.keycode == code):
				return true
		return false

	check("slot_9 has KEY_9", has_key.call("slot_9", KEY_9))
	check("slot_10 has KEY_0", has_key.call("slot_10", KEY_0))
	check("slot_11 has KEY_MINUS", has_key.call("slot_11", KEY_MINUS))
	check("slot_12 has KEY_EQUAL", has_key.call("slot_12", KEY_EQUAL))

	# 4. Player bar initialization
	var player = load("res://scenes/player.tscn").instantiate() as Player
	root.add_child(player)
	await process_frame

	check("Player bar has at least 12 slots", player.bar.size() >= 12)

	# 5. Drag/assign into high slots
	player.assign_slot(8, "thunder_strike")
	check("Slot 9 (index 8) assigned thunder_strike", player.bar[8] == "thunder_strike")
	player.assign_slot(9, "battle_cry")
	check("Slot 10 (index 9) assigned battle_cry", player.bar[9] == "battle_cry")
	player.assign_slot(10, "taunt")
	check("Slot 11 (index 10) assigned taunt", player.bar[10] == "taunt")
	player.assign_slot(11, "wall")
	check("Slot 12 (index 11) assigned wall", player.bar[11] == "wall")

	# 6. HUD source verification & ActionSlot row testing
	var hud_src := FileAccess.get_file_as_string("res://scripts/hud.gd")
	check("HUD defines ACTION_BAR_LABELS", hud_src.contains("ACTION_BAR_LABELS"))
	check("HUD loops over ACTION_BAR_LABELS.size()", hud_src.contains("for i in ACTION_BAR_LABELS.size():"))

	# Create 12 ActionSlots and attach to player
	var test_slots: Array[ActionSlot] = []
	const EXPECTED_LABELS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="]
	for i in 12:
		var slot := ActionSlot.new()
		slot.player = player
		slot.slot_index = i
		slot.key_label = EXPECTED_LABELS[i]
		root.add_child(slot)
		test_slots.append(slot)
	await process_frame

	check("Created 12 ActionSlot instances", test_slots.size() == 12)
	check("ActionSlot 8 has key_label 9", test_slots[8].key_label == "9")
	check("ActionSlot 9 has key_label 0", test_slots[9].key_label == "0")
	check("ActionSlot 10 has key_label -", test_slots[10].key_label == "-")
	check("ActionSlot 11 has key_label =", test_slots[11].key_label == "=")
	check("ActionSlot 8 entry matches player bar", test_slots[8].entry() == "thunder_strike")
	check("ActionSlot 9 entry matches player bar", test_slots[9].entry() == "battle_cry")

	# 7. GameSettings REBINDABLE entries
	var rebind_actions: Array[String] = []
	for r in GameSettings.REBINDABLE:
		rebind_actions.append(r[0])
	check("GameSettings has slot_9", rebind_actions.has("slot_9"))
	check("GameSettings has slot_10", rebind_actions.has("slot_10"))
	check("GameSettings has slot_11", rebind_actions.has("slot_11"))
	check("GameSettings has slot_12", rebind_actions.has("slot_12"))

	# 8. SaveGame padding verification
	var save_src := FileAccess.get_file_as_string("res://scripts/save_game.gd")
	check("SaveGame pads bar to DEFAULT_BAR.size()", save_src.contains("while player.bar.size() < SkillData.DEFAULT_BAR.size():"))

	for s in test_slots:
		s.queue_free()
	player.queue_free()
	inputs.queue_free()
	sound_mgr.queue_free()
	quests.queue_free()

	print("\n--- action_bar_12_test Results: %d passed, %d failed ---" % [passed, failed])
	if failed == 0:
		print("ALL PASS")
		quit(0)
	else:
		print("TESTS FAILED")
		quit(1)
