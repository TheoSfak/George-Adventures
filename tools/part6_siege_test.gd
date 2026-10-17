@tool
extends SceneTree

const QuestDataClass := preload("res://scripts/quest_data.gd")
const OrcStrongholdRaidClass := preload("res://scripts/orc_stronghold_raid.gd")
const GuardClass := preload("res://scripts/guard.gd")

var _checks_passed := 0
var _checks_failed := 0

func _assert(condition: bool, msg: String) -> void:
	if condition:
		_checks_passed += 1
		print("  PASS: %s" % msg)
	else:
		_checks_failed += 1
		print("  FAIL: %s" % msg)

func _init() -> void:
	print("==================================================")
	print("Story Part 6: Siege of the Orc Stronghold Test")
	print("==================================================")

	_test_quest_data()
	_test_orc_stronghold_raid()

	print("==================================================")
	print("Results: %d Passed, %d Failed" % [_checks_passed, _checks_failed])
	print("==================================================")
	quit(_checks_failed)

func _test_quest_data() -> void:
	print("\n--- Testing Story Part 6 Quest Data ---")
	_assert(QuestDataClass.QUESTS.has("orc_totems"), "Quest 'orc_totems' exists")
	var q_totems: Dictionary = QuestDataClass.QUESTS.get("orc_totems", {})
	_assert(q_totems.get("giver") == "vasilis", "orc_totems giver is Captain Vasilis")
	_assert(q_totems.get("requires") == ["orc_raid"], "orc_totems requires orc_raid")

	var obj_totems: Array = q_totems.get("objectives", [])
	_assert(obj_totems.size() == 2, "orc_totems has 2 objectives (totems & catapult)")
	if obj_totems.size() == 2:
		_assert(obj_totems[0].get("target") == "warband_totem" and obj_totems[0].get("count") == 3, "Objective 1: 3 Warband Totems")
		_assert(obj_totems[1].get("target") == "orc_catapult" and obj_totems[1].get("count") == 1, "Objective 2: 1 Catapult Sabotage")

	_assert(QuestDataClass.QUESTS.has("orc_siege"), "Quest 'orc_siege' exists")
	var q_siege: Dictionary = QuestDataClass.QUESTS.get("orc_siege", {})
	_assert(q_siege.get("giver") == "vasilis", "orc_siege giver is Captain Vasilis")
	_assert(q_siege.get("requires") == ["orc_totems"], "orc_siege requires orc_totems")
	var obj_siege: Array = q_siege.get("objectives", [])
	_assert(obj_siege.size() == 1 and obj_siege[0].get("target") == "orc_warlord", "orc_siege objective is defeating orc_warlord")

	_assert("warband_totem" in QuestDataClass.NOT_SKELETONS, "warband_totem is in NOT_SKELETONS")
	_assert("orc_catapult" in QuestDataClass.NOT_SKELETONS, "orc_catapult is in NOT_SKELETONS")

func _test_orc_stronghold_raid() -> void:
	print("\n--- Testing Orc Stronghold Raid Controller ---")
	var raid: Node = OrcStrongholdRaidClass.new()
	root.add_child(raid)
	raid._ready()

	_assert(raid != null, "OrcStrongholdRaid instantiates successfully")

	# Check Warband Totems
	var totems: Array = raid.get("_totems")
	_assert(totems.size() == 3, "3 Warband Totems spawned in stronghold courtyard")
	for i in totems.size():
		var t: Node = totems[i]
		_assert(t.is_in_group("breakables"), "Totem %d in 'breakables' group" % (i + 1))
		_assert(t.is_in_group("totems"), "Totem %d in 'totems' group" % (i + 1))
		_assert("Τοτέμ" in str(t.call("interact_prompt")), "Totem %d has Greek destruction prompt" % (i + 1))

	# Test destroying a totem
	var first_totem: Node = totems[0]
	first_totem.call("take_damage", 100.0, Vector3.ZERO)
	_assert(raid.get("totems_destroyed") == 1, "Totem destruction correctly tracked in raid (1/3)")

	# Check Catapult Sabotage Spot
	var cat_spot: Node = raid.get("_catapult_spot")
	_assert(cat_spot != null, "Catapult sabotage spot exists")
	_assert("Καταπέλτη" in str(cat_spot.call("interact_prompt")), "Catapult has sabotage interaction prompt")
	cat_spot.call("interact", null)
	_assert(raid.get("catapult_disabled") == true, "Catapult successfully sabotaged")

	# Check Assault War Horn & Guard Rally
	var horn: Node = raid.get("_horn_spot")
	_assert(horn != null, "Assault War Horn spot exists")
	_assert("Σάλπισμα" in str(horn.call("interact_prompt")), "Horn has assault signal prompt")

	horn.call("interact", null)
	_assert(raid.get("siege_active") == true, "Siege assault is now active")
	var guards: Array = raid.get("_guards")
	_assert(guards.size() == 3, "3 Village Guards rallied for the assault")
	for g in guards:
		_assert(g is GuardClass, "Spawned ally is instance of Guard")
		_assert(g.get("follow_player") == true, "Guard has follow_player enabled for dungeon raid")
		_assert(String(g.get("guard_name")).begins_with("Φρουρός"), "Guard has Greek squad name: %s" % g.get("guard_name"))

	# Test Fortress Liberation on Warlord vanquished
	raid.call("_on_warlord_vanquished")
	_assert(raid.get("warlord_defeated") == true or raid.get("warlord_slain") == true, "Warlord slain flag set on boss defeat")
	var chest: Node = raid.get("_victory_chest")
	_assert(chest != null, "Stronghold Golden War Chest spawned upon liberation")
	if chest != null:
		_assert(chest.get("golden") == true, "Victory chest is golden")
		_assert(int(chest.get("gold_min")) >= 1000, "Victory chest contains 1000+ gold spoils")

	raid.free()
