@tool
extends SceneTree

const BountyDataClass := preload("res://scripts/bounty_data.gd")
const BountyManagerClass := preload("res://scripts/bounty_manager.gd")
const BountyBoardClass := preload("res://scripts/bounty_board.gd")
const BountyWindowClass := preload("res://scripts/bounty_window.gd")
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


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	print("==================================================")
	print("Bounty Board & Hunting Contracts Test Suite")
	print("==================================================")

	_test_bounty_data()
	_test_bounty_manager()
	_test_bounty_board_prop()
	_test_bounty_window_ui()
	_test_save_load()

	print("==================================================")
	print("Results: %d Passed, %d Failed" % [_checks_passed, _checks_failed])
	print("==================================================")
	quit(_checks_failed)


func _test_bounty_data() -> void:
	print("\n--- 1. Testing BountyData ---")
	_assert(BountyDataClass.CONTRACT_TEMPLATES.size() >= 8, "Has at least 8 contract templates (found %d)" % BountyDataClass.CONTRACT_TEMPLATES.size())

	for t in BountyDataClass.CONTRACT_TEMPLATES:
		var has_keys: bool = t.has("id") and t.has("title") and t.has("tier") and t.has("target_kind") and t.has("count") and t.has("reward_gold") and t.has("reward_xp")
		_assert(has_keys, "Template '%s' has all required keys" % t.get("id", ""))
		_assert(int(t.get("count", 0)) > 0, "Template '%s' count > 0" % t.get("id", ""))
		_assert(int(t.get("reward_gold", 0)) > 0, "Template '%s' reward_gold > 0" % t.get("id", ""))

	# Tiers
	_assert(BountyDataClass.TIERS.has("bronze"), "Has bronze tier")
	_assert(BountyDataClass.TIERS.has("silver"), "Has silver tier")
	_assert(BountyDataClass.TIERS.has("gold"), "Has gold tier")

	# Hunter Ranks
	var r0 := BountyDataClass.get_hunter_rank(0)
	_assert("Μισθοφόρος" in String(r0["title"]), "Rank at 0 is Μισθοφόρος του Χωριού: %s" % r0["title"])

	var r4 := BountyDataClass.get_hunter_rank(4)
	_assert("Ιχνηλάτης" in String(r4["title"]), "Rank at 4 is Ιχνηλάτης Αγρίων Θηρίων: %s" % r4["title"])

	var r7 := BountyDataClass.get_hunter_rank(7)
	_assert("Κυνηγός" in String(r7["title"]), "Rank at 7 is Κυνηγός Επικηρυγμένων: %s" % r7["title"])

	var r12 := BountyDataClass.get_hunter_rank(12)
	_assert("Προστάτης" in String(r12["title"]), "Rank at 12 is Προστάτης του Αγίου Βλάση: %s" % r12["title"])

	var r16 := BountyDataClass.get_hunter_rank(16)
	_assert("Θρυλικός" in String(r16["title"]), "Rank at 16 is Θρυλικός Εκτελεστής: %s" % r16["title"])

	# Target matching
	_assert(BountyDataClass.is_target_match("wolf", "wolf"), "Direct target match 'wolf' == 'wolf'")
	_assert(BountyDataClass.is_target_match("spider", "spider"), "Direct target match 'spider' == 'spider'")
	_assert(BountyDataClass.is_target_match("bandit", "bandit_thug"), "Category match 'bandit' matches 'bandit_thug'")
	_assert(BountyDataClass.is_target_match("orc", "orc_warrior"), "Category match 'orc' matches 'orc_warrior'")
	_assert(BountyDataClass.is_target_match("skeleton", "warrior"), "Category match 'skeleton' matches 'warrior'")


func _test_bounty_manager() -> void:
	print("\n--- 2. Testing BountyManager ---")
	var mgr := BountyManagerClass.new()
	root.add_child(mgr)
	mgr._ready()

	_assert(mgr.is_in_group("bounty_manager"), "Manager is in group 'bounty_manager'")
	_assert(mgr.available_bounties.size() == 3, "Manager initialized 3 available contracts (found %d)" % mgr.available_bounties.size())

	# Accept a contract
	var first_bounty: Dictionary = mgr.available_bounties[0]
	var bid: String = first_bounty["id"]
	var target_kind: String = first_bounty["target_kind"]
	var needed_count: int = first_bounty["count"]

	var ok := mgr.accept_bounty(bid)
	_assert(ok == true, "Successfully accepted bounty '%s'" % bid)
	_assert(mgr.is_bounty_active(bid) == true, "Bounty is now active in manager")
	_assert(mgr.available_bounties.size() == 2, "Available board list reduced to 2")

	# Report kills
	var active_contract := mgr.get_active_bounty(bid)
	_assert(int(active_contract.get("progress", 0)) == 0, "Initial progress is 0")

	mgr.report_kill(target_kind)
	active_contract = mgr.get_active_bounty(bid)
	_assert(int(active_contract.get("progress", 0)) == 1, "Progress incremented to 1 after 1 kill")

	# Complete all kills
	for i in range(1, needed_count):
		mgr.report_kill(target_kind)

	active_contract = mgr.get_active_bounty(bid)
	_assert(int(active_contract.get("progress", 0)) == needed_count, "Progress reached needed count %d" % needed_count)
	_assert(bool(active_contract.get("ready", false)) == true, "Contract marked as ready to claim")

	# Claim rewards with player
	var player := PlayerScene.instantiate()
	root.add_child(player)
	player.gold = 100
	player.xp = 0

	var claimed := mgr.claim_bounty(bid, player)
	_assert(claimed == true, "Claimed bounty successfully")
	_assert(player.gold > 100, "Player received reward gold (now %d)" % player.gold)
	_assert(player.xp > 0, "Player received reward XP (now %d)" % player.xp)
	_assert(mgr.completed_count == 1, "Completed count incremented to 1")
	_assert(mgr.is_bounty_active(bid) == false, "Bounty removed from active after claim")
	_assert(mgr.available_bounties.size() == 3, "Board refilled back to 3 available contracts")

	player.free()
	mgr.free()


func _test_bounty_board_prop() -> void:
	print("\n--- 3. Testing 3D BountyBoard Prop ---")
	var board := BountyBoardClass.new()
	root.add_child(board)
	board._ready()

	_assert(board.is_in_group("interactables"), "BountyBoard is in 'interactables' group")
	_assert(board.is_in_group("bounty_board"), "BountyBoard is in 'bounty_board' group")

	var prompt: String = board.interact_prompt()
	_assert("Πίνακας Επικηρύξεων" in prompt, "Prompt mentions Bounty Board: %s" % prompt)
	_assert(board.interact_range() >= 3.0, "Interact range is >= 3.0m (%f)" % board.interact_range())

	var visual: Node = board.get_node_or_null("BoardVisual")
	_assert(visual != null, "Board has BoardVisual hierarchy")

	var lights := board.find_children("*", "OmniLight3D", true, false)
	_assert(lights.size() > 0, "Board has hanging lantern OmniLight3D")

	var cols := board.find_children("*", "CollisionShape3D", true, false)
	_assert(cols.size() > 0, "Board has CollisionShape3D")

	board.free()


func _test_bounty_window_ui() -> void:
	print("\n--- 4. Testing BountyWindow UI ---")
	var mgr := BountyManagerClass.new()
	root.add_child(mgr)
	mgr._ready()

	var win := BountyWindowClass.new()
	root.add_child(win)
	win._ready()

	_assert(win.visible == false, "Window initially hidden")

	var player := PlayerScene.instantiate()
	root.add_child(player)

	win.open(player)
	_assert(win.visible == true, "Window visible after open()")
	_assert(win.is_open() == true, "is_open() returns true")

	# Check child cards
	var cards_container: HBoxContainer = win.get("_cards_container")
	_assert(cards_container != null, "Found cards container")
	_assert(cards_container.get_child_count() == 3, "Window rendered 3 contract cards (found %d)" % cards_container.get_child_count())

	win.close()
	_assert(win.visible == false, "Window hidden after close()")

	player.free()
	win.free()
	mgr.free()


func _test_save_load() -> void:
	print("\n--- 5. Testing Save & Load Roundtrip ---")
	var mgr := BountyManagerClass.new()
	root.add_child(mgr)
	mgr._ready()

	mgr.completed_count = 5
	mgr.available_bounties = [
		{"id": "bounty_wolves", "title": "Test Wolves", "tier": "bronze", "count": 4},
		{"id": "bounty_spiders", "title": "Test Spiders", "tier": "bronze", "count": 5},
	]
	mgr.active_bounties = [
		{"id": "bounty_bandits", "title": "Test Bandits", "tier": "silver", "count": 5, "progress": 3, "ready": false}
	]

	var saved_dict := mgr.save_data()
	_assert(saved_dict.has("completed_count"), "Save data has completed_count")
	_assert(int(saved_dict["completed_count"]) == 5, "completed_count matches 5")
	_assert(saved_dict["active"].size() == 1, "active array saved 1 contract")
	_assert(saved_dict["available"].size() == 2, "available array saved 2 contracts")

	# Load into a fresh manager
	var mgr2 := BountyManagerClass.new()
	root.add_child(mgr2)
	mgr2.load_data(saved_dict)

	_assert(mgr2.completed_count == 5, "Loaded completed_count is 5")
	_assert(mgr2.active_bounties.size() == 1, "Loaded 1 active bounty")
	_assert(mgr2.active_bounties[0]["id"] == "bounty_bandits", "Loaded active bounty id matches")
	_assert(int(mgr2.active_bounties[0]["progress"]) == 3, "Loaded active bounty progress is 3")
	_assert(mgr2.available_bounties.size() == 2, "Loaded 2 available bounties")

	mgr.free()
	mgr2.free()
