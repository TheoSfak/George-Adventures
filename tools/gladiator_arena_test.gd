extends SceneTree

const ArenaDataClass := preload("res://scripts/arena_data.gd")
const GladiatorArenaClass := preload("res://scripts/gladiator_arena.gd")
const ArenaWindowClass := preload("res://scripts/arena_window.gd")

func _init() -> void:
	print("--- Running Gladiator Arena & Proving Grounds Test Suite ---")
	var failures := 0

	# -------------------------------------------------------------
	# 1. ArenaData & Trials Validation
	# -------------------------------------------------------------
	assert_test(ArenaDataClass.TRIALS.size() == 5, "ArenaData must define exactly 5 trial tiers", failures)
	var expected_ids := ["bronze", "silver", "gold", "heroic", "mythic"]
	for i in expected_ids.size():
		var t_id: String = expected_ids[i]
		var trial := ArenaDataClass.get_trial(t_id)
		assert_test(not trial.is_empty(), "Trial %s must exist in ArenaData" % t_id, failures)
		assert_test(trial.has("waves") and (trial["waves"] as Array).size() == 3, "Trial %s must have 3 waves" % t_id, failures)
		assert_test(trial.has("reward"), "Trial %s must have a reward" % t_id, failures)
		var rew: Dictionary = trial["reward"]
		assert_test(rew.has("gold") and rew["gold"] > 0, "Trial %s must reward gold" % t_id, failures)
		assert_test(rew.has("xp") and rew["xp"] > 0, "Trial %s must reward xp" % t_id, failures)
		assert_test(rew.has("trophy"), "Trial %s must reward a trophy" % t_id, failures)
		var trophy_id: String = rew["trophy"]
		assert_test(ShopData.JUNK.has(trophy_id), "Trophy %s must exist in ShopData.JUNK" % trophy_id, failures)

	# Mythic reward must grant legendary armor
	var mythic := ArenaDataClass.get_trial("mythic")
	assert_test(mythic["reward"].get("gear") == "armor_gladiator_champion", "Mythic trial must reward armor_gladiator_champion", failures)
	assert_test(ShopData.GEAR.has("armor_gladiator_champion"), "armor_gladiator_champion must exist in ShopData.GEAR", failures)
	assert_test(ShopData.GEAR["armor_gladiator_champion"]["tier"] == 10, "Gladiator armor must be Tier 10", failures)

	# -------------------------------------------------------------
	# 2. Progression & Unlock Checks
	# -------------------------------------------------------------
	var completed: Array = []
	assert_test(ArenaDataClass.is_unlocked("bronze", completed) == true, "Bronze trial must be unlocked by default", failures)
	assert_test(ArenaDataClass.is_unlocked("silver", completed) == false, "Silver trial must be locked initially", failures)

	var chk_bronze_nofee := ArenaDataClass.can_start("bronze", 5, 10, completed)
	assert_test(chk_bronze_nofee["ok"] == false, "Cannot start bronze trial without fee", failures)

	var chk_bronze_ok := ArenaDataClass.can_start("bronze", 5, 100, completed)
	assert_test(chk_bronze_ok["ok"] == true, "Can start bronze trial with sufficient gold", failures)

	completed.append("bronze")
	assert_test(ArenaDataClass.is_unlocked("silver", completed) == true, "Silver trial unlocks after bronze", failures)
	assert_test(ArenaDataClass.is_unlocked("gold", completed) == false, "Gold trial stays locked until silver is done", failures)

	completed.append("silver")
	assert_test(ArenaDataClass.is_unlocked("gold", completed) == true, "Gold trial unlocks after silver", failures)

	completed.append("gold")
	assert_test(ArenaDataClass.is_unlocked("heroic", completed) == true, "Heroic trial unlocks after gold", failures)

	completed.append("heroic")
	assert_test(ArenaDataClass.is_unlocked("mythic", completed) == true, "Mythic trial unlocks after heroic", failures)

	# -------------------------------------------------------------
	# 3. Enemy KINDS & Bosses Check
	# -------------------------------------------------------------
	var arena_mobs := ["gladiator_recruit", "gladiator_skeleton", "arena_gorgor", "arena_drake", "arena_vorgthul", "arena_titan", "arena_balthazar"]
	var EnemiesClass := load("res://scripts/enemies.gd")
	for m in arena_mobs:
		assert_test(EnemiesClass.KINDS.has(m), "Enemies.KINDS must define %s" % m, failures)

	var arena_bosses := ["arena_gorgor", "arena_drake", "arena_vorgthul", "arena_titan", "arena_balthazar"]
	for b in arena_bosses:
		assert_test(EnemiesClass.BOSSES.has(b), "Enemies.BOSSES must contain %s" % b, failures)

	# -------------------------------------------------------------
	# 4. NPC & Map Integration
	# -------------------------------------------------------------
	assert_test(QuestData.NPCS.has("kassandros"), "QuestData.NPCS must define kassandros", failures)
	assert_test(QuestData.NPCS["kassandros"].get("arena") == "gladiator_arena", "Kassandros must have arena property", failures)
	assert_test(Strings.MAP_PLACES.has("arena"), "Strings.MAP_PLACES must define arena", failures)
	var found_map_place := false
	for p in Minimap.PLACES:
		if p[0] == "arena":
			found_map_place = true
			break
	assert_test(found_map_place, "Minimap.PLACES must contain arena landmark", failures)

	# -------------------------------------------------------------
	# 5. 3D GladiatorArena Scene Node & Hierarchy
	# -------------------------------------------------------------
	var arena := GladiatorArenaClass.new()
	root.add_child(arena)
	arena._ready()

	if arena.is_in_group("gladiator_arena"):
		print("  [PASS] GladiatorArena must be in group gladiator_arena")
	else:
		printerr("  [FAIL] GladiatorArena must be in group gladiator_arena")
		failures += 1

	if arena.has_node("ArenaVisuals"):
		print("  [PASS] Arena must have ArenaVisuals child")
	else:
		printerr("  [FAIL] Arena must have ArenaVisuals child")
		failures += 1

	if arena.has_node("ArenaWallColliders"):
		print("  [PASS] Arena must have ArenaWallColliders child")
	else:
		printerr("  [FAIL] Arena must have ArenaWallColliders child")
		failures += 1

	if arena.has_node("ArenaVisuals/Portcullis"):
		print("  [PASS] Arena must have Portcullis child")
	else:
		printerr("  [FAIL] Arena must have Portcullis child")
		failures += 1

	if arena.has_node("ArenaVisuals/Portcullis/PortcullisCollider"):
		print("  [PASS] Portcullis must have PortcullisCollider child")
	else:
		printerr("  [FAIL] Portcullis must have PortcullisCollider child")
		failures += 1

	if arena.has_node("ArenaVisuals/Stand_North"):
		print("  [PASS] Arena must have North spectator stand")
	else:
		printerr("  [FAIL] Arena must have North spectator stand")
		failures += 1

	if arena.has_node("ArenaVisuals/Stand_South"):
		print("  [PASS] Arena must have South spectator stand")
	else:
		printerr("  [FAIL] Arena must have South spectator stand")
		failures += 1

	# Save/Load round trip
	arena.completed_trials = ["bronze", "silver"]
	var s_data := arena.save_data()
	if s_data.has("completed_trials") and s_data["completed_trials"].size() == 2:
		print("  [PASS] save_data must store completed_trials")
	else:
		printerr("  [FAIL] save_data must store completed_trials")
		failures += 1

	var arena2 := GladiatorArenaClass.new()
	arena2.load_data(s_data)
	if arena2.completed_trials.size() == 2 and arena2.completed_trials.has("silver"):
		print("  [PASS] load_data must restore completed trials")
	else:
		printerr("  [FAIL] load_data must restore completed trials")
		failures += 1

	# -------------------------------------------------------------
	# 6. ArenaWindow UI Component
	# -------------------------------------------------------------
	var win := ArenaWindowClass.new()
	root.add_child(win)
	win._ready()
	if win.name == "ArenaWindow":
		print("  [PASS] ArenaWindow node name must be ArenaWindow")
	else:
		printerr("  [FAIL] ArenaWindow node name must be ArenaWindow")
		failures += 1

	print("-------------------------------------------------------------")
	if failures == 0:
		print("ALL GLADIATOR ARENA TESTS PASSED (100% OK)")
		quit(0)
	else:
		print("FAILURES DETECTED: %d" % failures)
		quit(1)

func assert_test(cond: bool, msg: String, failures_ref: int) -> void:
	if cond:
		print("  [PASS] %s" % msg)
	else:
		printerr("  [FAIL] %s" % msg)
