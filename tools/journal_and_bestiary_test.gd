extends SceneTree
## Comprehensive Automated Test for Achievements & Bestiary Lore System (v1.22.0)

const AchievementDataClass := preload("res://scripts/achievement_data.gd")
const BestiaryDataClass := preload("res://scripts/bestiary_data.gd")
const JournalManagerClass := preload("res://scripts/journal_manager.gd")
const JournalWindowClass := preload("res://scripts/journal_window.gd")

func _init() -> void:
	print("=================================================================")
	print("🧪 Starting Automated Verification: Achievements & Bestiary Lore")
	print("=================================================================")

	var ok := true
	ok = _test_achievement_data() and ok
	ok = _test_bestiary_data() and ok
	ok = _test_journal_manager() and ok
	ok = _test_journal_window() and ok

	if ok:
		print("=================================================================")
		print("✅ ALL TESTS PASSED SUCCESSFULLY! (Achievements & Bestiary v1.22.0)")
		print("=================================================================")
		quit(0)
	else:
		printerr("❌ SOME TESTS FAILED!")
		quit(1)


func _test_achievement_data() -> bool:
	print("\n--- Testing AchievementData ---")
	var count := AchievementDataClass.ACHIEVEMENTS.size()
	print("Defined achievements count: %d" % count)
	if count < 30:
		printerr("Fail: Expected at least 30 achievements, got %d" % count)
		return false

	var ids := {}
	for ach in AchievementDataClass.ACHIEVEMENTS:
		var aid: String = ach.get("id", "")
		if aid.is_empty():
			printerr("Fail: Achievement missing id: %s" % str(ach))
			return false
		if ids.has(aid):
			printerr("Fail: Duplicate achievement id: %s" % aid)
			return false
		ids[aid] = true

		for req_key in ["category", "title", "desc", "icon", "stat", "target", "reward"]:
			if not ach.has(req_key):
				printerr("Fail: Achievement %s missing key %s" % [aid, req_key])
				return false

		var cat: String = ach["category"]
		if not AchievementDataClass.CATEGORIES.has(cat):
			printerr("Fail: Invalid category %s in %s" % [cat, aid])
			return false

	print("Categories tested: %s" % str(AchievementDataClass.CATEGORIES.keys()))
	var combat_achs := AchievementDataClass.get_by_category("combat")
	print("Combat achievements count: %d" % combat_achs.size())
	if combat_achs.is_empty():
		printerr("Fail: No combat achievements found!")
		return false

	print("✔ AchievementData passed verification.")
	return true


func _test_bestiary_data() -> bool:
	print("\n--- Testing BestiaryData ---")
	var count := BestiaryDataClass.ENTRIES.size()
	print("Defined bestiary creatures count: %d" % count)
	if count < 35:
		printerr("Fail: Expected at least 35 bestiary entries, got %d" % count)
		return false

	var kinds := {}
	for b in BestiaryDataClass.ENTRIES:
		var kind: String = b.get("kind_id", "")
		if kind.is_empty():
			printerr("Fail: Bestiary entry missing kind_id: %s" % str(b))
			return false
		if kinds.has(kind):
			printerr("Fail: Duplicate bestiary kind_id: %s" % kind)
			return false
		kinds[kind] = true

		for req_key in ["name", "category", "lore", "stats", "drops", "weakness"]:
			if not b.has(req_key):
				printerr("Fail: Bestiary entry %s missing key %s" % [kind, req_key])
				return false

	# Test unlock tier logic
	if BestiaryDataClass.get_unlock_tier(0, false) != BestiaryDataClass.TIER_UNKNOWN:
		printerr("Fail: 0 kills regular should be TIER_UNKNOWN")
		return false
	if BestiaryDataClass.get_unlock_tier(1, false) != BestiaryDataClass.TIER_DISCOVERED:
		printerr("Fail: 1 kill regular should be TIER_DISCOVERED")
		return false
	if BestiaryDataClass.get_unlock_tier(5, false) != BestiaryDataClass.TIER_STUDIED:
		printerr("Fail: 5 kills regular should be TIER_STUDIED")
		return false
	if BestiaryDataClass.get_unlock_tier(15, false) != BestiaryDataClass.TIER_MASTERED:
		printerr("Fail: 15 kills regular should be TIER_MASTERED")
		return false

	# Boss unlock tier logic (1 kill = mastered)
	if BestiaryDataClass.get_unlock_tier(1, true) != BestiaryDataClass.TIER_MASTERED:
		printerr("Fail: 1 kill boss should be TIER_MASTERED")
		return false

	print("✔ BestiaryData passed verification.")
	return true


func _test_journal_manager() -> bool:
	print("\n--- Testing JournalManager ---")
	var mgr := JournalManagerClass.new()
	root.add_child(mgr)

	var player_sc := load("res://scenes/player.tscn") as PackedScene
	var player := player_sc.instantiate() as Node
	root.add_child(player)

	# 1. Test kill reporting
	mgr.report_kill("warrior")
	if mgr.get_kill_count("warrior") != 1:
		printerr("Fail: Kill count for warrior should be 1")
		return false
	if mgr.get_stat("total_kills") != 1:
		printerr("Fail: total_kills should be 1")
		return false
	if mgr.get_stat("skeleton_kills") != 1:
		printerr("Fail: skeleton_kills should be 1")
		return false

	# 2. Check first blood achievement unlock
	if not mgr.is_achievement_unlocked("first_blood"):
		printerr("Fail: first_blood achievement should be unlocked after 1 kill")
		return false
	print("Unlocked 'first_blood' achievement successfully.")

	# 3. Test generic stat reporting
	mgr.report_stat("chests_opened", 10)
	if not mgr.is_achievement_unlocked("chest_finder"):
		printerr("Fail: chest_finder achievement should be unlocked after 10 chests")
		return false
	print("Unlocked 'chest_finder' achievement successfully.")

	# 4. Test serialization
	var saved := mgr.save_data()
	if not saved.has("bestiary_kills") or not saved.has("unlocked_achievements") or not saved.has("stats"):
		printerr("Fail: Incomplete saved dictionary: %s" % str(saved))
		return false

	var mgr2 := JournalManagerClass.new()
	mgr2.load_data(saved)
	if mgr2.get_kill_count("warrior") != 1 or not mgr2.is_achievement_unlocked("first_blood"):
		printerr("Fail: Loaded manager state mismatch")
		return false
	print("Save/Load serialization roundtrip verified.")

	mgr2.queue_free()
	mgr.queue_free()
	player.queue_free()

	print("✔ JournalManager passed verification.")
	return true


func _test_journal_window() -> bool:
	print("\n--- Testing JournalWindow ---")
	var mgr := JournalManagerClass.new()
	root.add_child(mgr)

	var win := JournalWindowClass.new()
	root.add_child(win)

	# Open window and toggle tabs
	win.open(null, "achievements")
	if not win.visible or win._current_tab != "achievements":
		printerr("Fail: JournalWindow failed to open achievements tab")
		return false

	win.open(null, "bestiary")
	if win._current_tab != "bestiary":
		printerr("Fail: JournalWindow failed to switch to bestiary tab")
		return false

	# Test monster selection in bestiary
	win._selected_bestiary_kind = "orc_warlord"
	win._display_bestiary_entry("orc_warlord")
	if win._selected_bestiary_kind != "orc_warlord":
		printerr("Fail: Failed to select orc_warlord in bestiary")
		return false

	win.close()
	if win.visible:
		printerr("Fail: JournalWindow failed to close")
		return false

	win.queue_free()
	mgr.queue_free()
	print("✔ JournalWindow passed verification.")
	return true
