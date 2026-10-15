extends SceneTree

var passed := 0
var failed := 0


func _init() -> void:
	print("--- Running second_action_bar_test ---")
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

	# 1. Strings
	check("Strings defines SET_SECOND_ACTION_BAR", Strings.SET_SECOND_ACTION_BAR == "Δεύτερη μπάρα δεξιοτήτων")

	# 2. SkillData.DEFAULT_BAR size is 24
	check("SkillData.DEFAULT_BAR has 24 slots", SkillData.DEFAULT_BAR.size() == 24)

	# 3. GameSettings persistence & toggle
	GameSettings.ensure_loaded()
	var prev_setting := GameSettings.second_action_bar
	GameSettings.set_second_action_bar(true)
	check("GameSettings.second_action_bar toggled to true", GameSettings.second_action_bar == true)
	GameSettings.load_file()
	check("GameSettings loaded persisted second_action_bar=true", GameSettings.second_action_bar == true)
	GameSettings.set_second_action_bar(prev_setting)

	# 4. InputMap actions for slot_1 .. slot_24
	for i in 24:
		var act := "slot_%d" % (i + 1)
		check("InputMap has action %s" % act, InputMap.has_action(act))

	# 5. GameSettings REBINDABLE entries for slot_1 .. slot_24
	var rebind_actions: Array[String] = []
	for r in GameSettings.REBINDABLE:
		rebind_actions.append(r[0])
	for i in 24:
		var act := "slot_%d" % (i + 1)
		check("REBINDABLE contains %s" % act, rebind_actions.has(act))

	# 6. Player bar initialization with 24 slots
	var player = load("res://scenes/player.tscn").instantiate() as Player
	root.add_child(player)
	await process_frame

	check("Player bar has 24 slots", player.bar.size() == 24)

	# 7. Drag and assign into secondary bar slots (indices 12 to 23)
	player.assign_slot(12, "thunder_strike")
	check("Slot 13 (index 12) assigned thunder_strike", player.bar[12] == "thunder_strike")
	player.assign_slot(13, "battle_cry")
	check("Slot 14 (index 13) assigned battle_cry", player.bar[13] == "battle_cry")
	player.assign_slot(23, "sanctuary")
	check("Slot 24 (index 23) assigned sanctuary", player.bar[23] == "sanctuary")

	# 8. HUD source verification (ActionBarCol, Row1, Row2, refresh_action_bars)
	var hud_src := FileAccess.get_file_as_string("res://scripts/hud.gd")
	check("HUD creates VBoxContainer ActionBarCol", hud_src.contains("ActionBarCol"))
	check("HUD creates Row1 and Row2", hud_src.contains("Row1") and hud_src.contains("Row2"))
	check("HUD implements refresh_action_bars()", hud_src.contains("func refresh_action_bars() -> void:"))

	# 9. GameMenu source verification (SET_SECOND_ACTION_BAR checkbox)
	var menu_src := FileAccess.get_file_as_string("res://scripts/game_menu.gd")
	check("GameMenu creates second_bar checkbox", menu_src.contains("second_bar") and menu_src.contains("SET_SECOND_ACTION_BAR"))

	# 10. SaveGame padding verification
	var save_src := FileAccess.get_file_as_string("res://scripts/save_game.gd")
	check("SaveGame pads bar to DEFAULT_BAR.size()", save_src.contains("while player.bar.size() < SkillData.DEFAULT_BAR.size():"))

	player.queue_free()
	inputs.queue_free()
	sound_mgr.queue_free()
	quests.queue_free()

	print("\n--- second_action_bar_test Results: %d passed, %d failed ---" % [passed, failed])
	if failed == 0:
		print("ALL PASS")
		quit(0)
	else:
		print("TESTS FAILED")
		quit(1)
