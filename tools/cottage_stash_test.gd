@tool
extends SceneTree

const PlayerScene := preload("res://scenes/player.tscn")
const PersonalStashClass := preload("res://scripts/personal_stash.gd")
const CottageGardenClass := preload("res://scripts/cottage_garden.gd")
const TrophyWallClass := preload("res://scripts/trophy_wall.gd")
const StashWindowClass := preload("res://scripts/stash_window.gd")

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
	print("George's Cottage & Stash Test Suite")
	print("==================================================")

	var player: Player = PlayerScene.instantiate()
	root.add_child(player)
	await process_frame

	_test_player_stash(player)
	await _test_personal_stash_prop(player)
	await _test_cottage_garden(player)
	await _test_trophy_wall()
	await _test_stash_window(player)

	player.queue_free()
	await process_frame

	await _test_save_load_roundtrip()

	print("==================================================")
	print("Results: %d Passed, %d Failed" % [_checks_passed, _checks_failed])
	print("==================================================")
	quit(_checks_failed)


func _test_player_stash(player: Player) -> void:
	print("\n--- 1. Testing Player Stash Operations ---")
	_assert(not player.cottage_owned, "Player cottage_owned initially false")
	_assert(player.stash.has("gear") and player.stash.has("junk") and player.stash.has("consumables"), "Player stash has gear, junk, consumables")

	# Prepare items with valid ShopData gear IDs
	player.gear_owned = ["weapon_1", "armor_1", "shield_1", "bow_1", "weapon_2"]
	player.equipped = {"weapon": "weapon_1", "armor": "armor_1", "shield": "shield_1"}
	player.junk = {"trout": 5, "iron_ore": 10, "mountain_herb": 3}
	player.consumables = {"health": 4, "potion": 2}

	var signals := {"stash": 0, "gear": 0}
	player.stash_changed.connect(func(): signals["stash"] += 1)
	player.gear_changed.connect(func(): signals["gear"] += 1)

	# 1. Deposit equipped item fails
	var dep_eq = player.deposit_gear("weapon_1")
	_assert(not dep_eq, "Cannot deposit equipped weapon 'weapon_1'")
	_assert(player.gear_owned.has("weapon_1"), "Equipped weapon remains in gear_owned")

	# 2. Deposit unequipped item succeeds
	var dep_bow = player.deposit_gear("bow_1")
	_assert(dep_bow, "Successfully deposited unequipped 'bow_1'")
	_assert(not player.gear_owned.has("bow_1"), "'bow_1' removed from gear_owned")
	_assert(player.stash["gear"].has("bow_1"), "'bow_1' added to stash['gear']")
	_assert(signals["stash"] > 0, "stash_changed emitted on gear deposit")
	_assert(signals["gear"] > 0, "gear_changed emitted on gear deposit")

	# 3. Withdraw gear
	var with_bow = player.withdraw_gear("bow_1")
	_assert(with_bow, "Successfully withdrew 'bow_1'")
	_assert(player.gear_owned.has("bow_1"), "'bow_1' restored to gear_owned")
	_assert(not player.stash["gear"].has("bow_1"), "'bow_1' removed from stash['gear']")

	# 4. Deposit Junk (fish & materials)
	var dep_fish = player.deposit_junk("trout", 3)
	_assert(dep_fish, "Successfully deposited 3 trout")
	_assert(player.junk["trout"] == 2, "Player remaining trout == 2 (was 5)")
	_assert(player.stash["junk"]["trout"] == 3, "Stash trout == 3")

	var dep_all_fish = player.deposit_junk("trout", 2)
	_assert(dep_all_fish, "Deposited remaining 2 trout")
	_assert(not player.junk.has("trout"), "Trout erased from player junk when 0")
	_assert(player.stash["junk"]["trout"] == 5, "Stash trout now == 5")

	# 5. Withdraw Junk
	var with_fish = player.withdraw_junk("trout", 2)
	_assert(with_fish, "Withdrew 2 trout from stash")
	_assert(player.junk["trout"] == 2, "Player trout restored to 2")
	_assert(player.stash["junk"]["trout"] == 3, "Stash trout remaining == 3")

	# 6. Deposit Consumables
	var dep_pots = player.deposit_consumable("health", 2)
	_assert(dep_pots, "Deposited 2 health potions")
	_assert(player.consumables["health"] == 2, "Player health potions == 2")
	_assert(player.stash["consumables"]["health"] == 2, "Stash health potions == 2")

	# 7. Withdraw Consumables
	var with_pots = player.withdraw_consumable("health", 1)
	_assert(with_pots, "Withdrew 1 health potion from stash")
	_assert(player.consumables["health"] == 3, "Player health potions restored to 3")
	_assert(player.stash["consumables"]["health"] == 1, "Stash health potions remaining == 1")


func _test_personal_stash_prop(player: Player) -> void:
	print("\n--- 2. Testing PersonalStash 3D Prop ---")
	var stash_prop: Node3D = PersonalStashClass.new()
	root.add_child(stash_prop)
	await process_frame

	_assert(stash_prop.is_in_group("interactables"), "PersonalStash in 'interactables' group")
	_assert(stash_prop.is_in_group("personal_stash"), "PersonalStash in 'personal_stash' group")
	_assert("Μπαούλο" in stash_prop.interact_prompt(), "Prompt contains 'Μπαούλο': %s" % stash_prop.interact_prompt())
	_assert(stash_prop.interact_range() >= 3.0, "Interact range is >= 3.0 (got %.1f)" % stash_prop.interact_range())

	stash_prop.queue_free()


func _test_cottage_garden(player: Player) -> void:
	print("\n--- 3. Testing CottageGarden Herb Harvesting ---")
	var garden = CottageGardenClass.new()
	root.add_child(garden)
	await process_frame

	_assert(garden.is_in_group("interactables"), "CottageGarden in 'interactables' group")
	_assert(garden.is_in_group("cottage_garden"), "CottageGarden in 'cottage_garden' group")
	_assert(garden.is_ready_to_harvest(), "Garden is ready to harvest initially")
	_assert("Συγκομιδή" in garden.interact_prompt(), "Harvest prompt ready: %s" % garden.interact_prompt())

	# Initial count of alchemical herbs
	var count_before := 0
	for r in CottageGardenClass.HARVEST_REAGENTS:
		count_before += int(player.junk.get(r, 0))

	# Perform harvest
	garden.interact(player)

	var count_after := 0
	for r in CottageGardenClass.HARVEST_REAGENTS:
		count_after += int(player.junk.get(r, 0))

	_assert(count_after == count_before + 3, "Harvest granted exactly 3 alchemical reagents (before: %d, after: %d)" % [count_before, count_after])
	_assert(not garden.is_ready_to_harvest(), "Garden not ready to harvest immediately after")
	_assert("Αναμονή" in garden.interact_prompt(), "Prompt indicates waiting: %s" % garden.interact_prompt())

	# Test save & load persistence of garden
	var sdata: Dictionary = garden.save_data()
	_assert(sdata.has("last_harvest_day"), "Garden save_data has 'last_harvest_day'")
	var garden2 = CottageGardenClass.new()
	garden2.load_data(sdata)
	_assert(garden2.last_harvest_day == garden.last_harvest_day, "Loaded garden matches last_harvest_day (%d)" % garden2.last_harvest_day)

	garden.queue_free()
	garden2.queue_free()


func _test_trophy_wall() -> void:
	print("\n--- 4. Testing TrophyWall Boss Relics ---")
	var wall: Node3D = TrophyWallClass.new()
	root.add_child(wall)
	await process_frame

	_assert(TrophyWallClass.TROPHIES.size() == 6, "TrophyWall defines 6 boss trophies")
	for t in TrophyWallClass.TROPHIES:
		_assert(t.has("id") and t.has("name") and t.has("boss_kind"), "Trophy '%s' has required fields" % t.get("id", ""))

	_assert(wall.has_node("Mount_king"), "Has Mount_king node")
	_assert(wall.has_node("Mount_bandit_chief"), "Has Mount_bandit_chief node")
	_assert(wall.has_node("Mount_wolf"), "Has Mount_wolf node")
	_assert(wall.has_node("Mount_spider"), "Has Mount_spider node")
	_assert(wall.has_node("Mount_malakar"), "Has Mount_malakar node")
	_assert(wall.has_node("Mount_orc_warlord"), "Has Mount_orc_warlord node")

	wall.queue_free()


func _test_stash_window(player: Player) -> void:
	print("\n--- 5. Testing StashWindow UI Controls ---")
	var win: PanelContainer = StashWindowClass.new()
	root.add_child(win)
	await process_frame

	_assert(not win.is_open(), "StashWindow initially closed")
	win.open(player)
	_assert(win.is_open(), "StashWindow is open after open()")

	# Switch tabs
	win._set_tab("gear")
	_assert(win._tab == "gear", "Tab set to 'gear'")
	win._set_tab("junk")
	_assert(win._tab == "junk", "Tab set to 'junk'")
	win._set_tab("consumables")
	_assert(win._tab == "consumables", "Tab set to 'consumables'")

	win.close()
	_assert(not win.is_open(), "StashWindow closed after close()")

	win.queue_free()


func _test_save_load_roundtrip() -> void:
	print("\n--- 6. Testing SaveGame Roundtrip ---")
	var save_dict := {
		"version": 1,
		"player": {
			"level": 5, "xp": 100, "gold": 250, "health": 150.0,
			"base_max_health": 150.0, "base_damage": 15.0,
			"consumables": {"potion": 2}, "junk": {"iron_ore": 4},
			"gear_owned": ["weapon_1", "armor_1", "shield_1"],
			"equipped": {"weapon": "weapon_1", "armor": "armor_1", "shield": "shield_1"},
			"gear_upgrades": {"weapon": 0, "armor": 0, "shield": 0},
			"talents": {}, "bar": [],
			"position": [0.0, 0.0, 0.0], "heading": 0.0,
			"in_frontier": false,
			"region": "",
			"fish_seen": [],
			"horse_owned": false,
			"cottage_owned": true,
			"stash": {
				"gear": ["weapon_2", "bow_1"],
				"junk": {"iron_ore": 6, "trout": 3},
				"consumables": {"potion": 4}
			},
		},
		"world": {
			"time_of_day": 10.0,
			"day": 2,
			"night": 0,
			"defeated_bosses": [], "opened_chests": [], "collected_items": [], "destroyed_totems": [],
			"stable_rooms": true,
		},
		"cottage_garden": {
			"last_harvest_day": 2
		}
	}

	# Create a fresh player and apply
	var fresh_player: Player = PlayerScene.instantiate()
	root.add_child(fresh_player)
	await process_frame

	_assert(not fresh_player.cottage_owned, "Fresh player cottage_owned is false")
	_assert(fresh_player.stash["gear"].is_empty(), "Fresh player stash is empty")

	SaveGame.apply(save_dict)

	_assert(fresh_player.cottage_owned, "Player cottage_owned restored as true")
	_assert(fresh_player.stash["gear"].has("weapon_2"), "Player stash gear restored")
	_assert(fresh_player.stash["junk"].get("iron_ore") == 6, "Player stash junk restored")
	_assert(fresh_player.stash["consumables"].get("potion") == 4, "Player stash consumables restored")

	fresh_player.queue_free()

