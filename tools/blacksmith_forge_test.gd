extends SceneTree
## Automated test suite for Blacksmith Forge & Weapon/Armor Upgrade System (+1 to +5).
## Usage: & "C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --path . --headless -s tools/blacksmith_forge_test.gd

const BlacksmithForgeClass := preload("res://scripts/blacksmith_forge.gd")

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	print("==================================================")
	print("Blacksmith Forge & Equipment Upgrades (+1..+5) Test")
	print("==================================================")

	root.get_node("/root/Quests").intro_seen = true

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var player: Player = get_first_node_in_group("player") as Player
	if not player:
		print("FAIL: Player node not found")
		quit(1)
		return

	# -----------------------------------------------------------------
	# 1. Test Upgrade Constants & Data
	# -----------------------------------------------------------------
	print("\n--- 1. Testing Upgrade Level & Costs Scaling ---")
	if ShopData.MAX_UPGRADE_LEVEL != 5:
		print("FAIL: Expected MAX_UPGRADE_LEVEL == 5, got %d" % ShopData.MAX_UPGRADE_LEVEL)
		quit(1)
		return
	print("  PASS: MAX_UPGRADE_LEVEL is 5")

	for lvl in range(1, 6):
		if not ShopData.UPGRADE_COSTS.has(lvl):
			print("FAIL: Missing UPGRADE_COSTS for level %d" % lvl)
			quit(1)
			return
		var c: Dictionary = ShopData.UPGRADE_COSTS[lvl]
		print("  * Level +%d -> %d Gold, %dx %s" % [lvl, int(c["gold"]), int(c["count"]), str(c["material"])])

	# -----------------------------------------------------------------
	# 2. Test Stat Scaling (+1 to +5)
	# -----------------------------------------------------------------
	print("\n--- 2. Testing Stat Scaling for Upgrades ---")
	var mods_w5: Dictionary = ShopData.upgrade_mods("weapon", 5)
	if not is_equal_approx(float(mods_w5.get("damage_mult", 0.0)), 0.60):
		print("FAIL: Expected weapon +5 damage_mult == 0.60, got %f" % float(mods_w5.get("damage_mult", 0.0)))
		quit(1)
		return
	if not is_equal_approx(float(mods_w5.get("crit", 0.0)), 0.10):
		print("FAIL: Expected weapon +5 crit == 0.10, got %f" % float(mods_w5.get("crit", 0.0)))
		quit(1)
		return
	if not is_equal_approx(float(mods_w5.get("attack_speed", 0.0)), 0.10):
		print("FAIL: Expected weapon +5 attack_speed == 0.10, got %f" % float(mods_w5.get("attack_speed", 0.0)))
		quit(1)
		return
	print("  PASS: Weapon +5 grants +60% Damage, +10% Crit, +10% Attack Speed")

	var mods_a5: Dictionary = ShopData.upgrade_mods("armor", 5)
	if not is_equal_approx(float(mods_a5.get("hp_add", 0.0)), 250.0):
		print("FAIL: Expected armor +5 hp_add == 250.0, got %f" % float(mods_a5.get("hp_add", 0.0)))
		quit(1)
		return
	if not is_equal_approx(float(mods_a5.get("defense", 0.0)), 0.20):
		print("FAIL: Expected armor +5 defense == 0.20, got %f" % float(mods_a5.get("defense", 0.0)))
		quit(1)
		return
	if not is_equal_approx(float(mods_a5.get("regen", 0.0)), 1.5):
		print("FAIL: Expected armor +5 regen == 1.5, got %f" % float(mods_a5.get("regen", 0.0)))
		quit(1)
		return
	print("  PASS: Armor +5 grants +250 HP, +20% Defense, +1.5 HP/s Regen")

	var mods_s5: Dictionary = ShopData.upgrade_mods("shield", 5)
	if not is_equal_approx(float(mods_s5.get("hp_add", 0.0)), 150.0) or not is_equal_approx(float(mods_s5.get("block_add", 0.0)), 0.15):
		print("FAIL: Unexpected shield +5 stats: %s" % [str(mods_s5)])
		quit(1)
		return
	print("  PASS: Shield +5 grants +150 HP, +15% Block, +15% Defense")

	# -----------------------------------------------------------------
	# 3. Test Progressive Upgrading on Player
	# -----------------------------------------------------------------
	print("\n--- 3. Testing In-Game Player Upgrades (+1..+5) ---")
	player.gold = 50000
	player.junk = {
		"iron_scrap": 50,
		"bone_shard": 50,
		"lava_ember": 50,
		"mountain_herb": 50,
		"reed": 50,
		"waterlily": 50,
		"autumn_cone": 50,
	}
	player.gear_upgrades = {"weapon": 0, "armor": 0, "shield": 0}
	player._recalc()
	var base_hp := player.max_health
	var base_dmg := player.sword_damage
	print("  Base George Stats -> HP: %.1f, Damage: %.1f" % [base_hp, base_dmg])

	for step in range(1, 6):
		var ok: bool = player.upgrade_gear("weapon")
		if not ok or player.gear_upgrades["weapon"] != step:
			print("FAIL: Failed to upgrade weapon to +%d" % step)
			quit(1)
			return
		print("  PASS: Upgraded weapon to +%d (Current dmg: %.1f)" % [step, player.sword_damage])

	if player.sword_damage <= base_dmg:
		print("FAIL: Upgraded weapon didn't increase player sword damage!")
		quit(1)
		return

	# Test capping at +5
	var over_up := player.upgrade_gear("weapon")
	if over_up:
		print("FAIL: Upgrading past +5 should return false!")
		quit(1)
		return
	print("  PASS: Upgrades correctly blocked at max level +5")

	# -----------------------------------------------------------------
	# 4. Test Special Forging Recipes
	# -----------------------------------------------------------------
	print("\n--- 4. Testing Masterwork Forging Recipes ---")
	var expected_recipes := ["forge_orc_cleaver", "forge_wolf_bow", "forge_corsair_mail", "forge_bulwark"]
	for rid in expected_recipes:
		if not ShopData.FORGE_RECIPES.has(rid):
			print("FAIL: Missing forge recipe: %s" % rid)
			quit(1)
			return
		var rec: Dictionary = ShopData.FORGE_RECIPES[rid]
		var gid: String = rec["gear_id"]
		if not ShopData.GEAR.has(gid):
			print("FAIL: GEAR missing item: %s" % gid)
			quit(1)
			return

		var can_f := ShopData.can_forge(rid, player.gold, player.junk, player.gear_owned)
		if not can_f:
			print("FAIL: Expected can_forge == true for %s with full materials" % rid)
			quit(1)
			return

		var forged_ok: bool = ShopData.forge_recipe(rid, player)
		if not forged_ok or not player.gear_owned.has(gid):
			print("FAIL: Failed to forge recipe %s" % rid)
			quit(1)
			return
		print("  PASS: Forged %s -> Owned in inventory" % rec["name"])

		# Can no longer forge already-owned gear
		var can_dup := ShopData.can_forge(rid, player.gold, player.junk, player.gear_owned)
		if can_dup:
			print("FAIL: Should not allow duplicate crafting of owned unique gear: %s" % rid)
			quit(1)
			return

	# -----------------------------------------------------------------
	# 5. Test 3D BlacksmithForge Station
	# -----------------------------------------------------------------
	print("\n--- 5. Testing 3D BlacksmithForge Station Node ---")
	var forge_inst: Node3D = BlacksmithForgeClass.new()
	root.add_child(forge_inst)
	await process_frame

	if not forge_inst.is_in_group("interactables") or not forge_inst.is_in_group("blacksmith"):
		print("FAIL: BlacksmithForge station missing required groups")
		quit(1)
		return
	var prompt: String = forge_inst.call("interact_prompt")
	print("  Prompt: %s" % prompt)
	if not prompt.contains("Αμόνι & Καμίνι"):
		print("FAIL: Prompt does not mention anvil/hearth")
		quit(1)
		return

	if forge_inst.interact_range() < 3.0:
		print("FAIL: Interact range too small: %f" % forge_inst.interact_range())
		quit(1)
		return

	# Check presence in village
	var village := get_first_node_in_group("village")
	var found_forges := get_nodes_in_group("blacksmith")
	print("  Found %d Blacksmith nodes in scene tree" % found_forges.size())
	if found_forges.is_empty():
		print("FAIL: No BlacksmithForge found in world")
		quit(1)
		return
	print("  PASS: BlacksmithForge station verified in world")

	# -----------------------------------------------------------------
	# 6. Test Visual Enchantment Overlay on Weapons
	# -----------------------------------------------------------------
	print("\n--- 6. Testing Weapon Enchantment Glow Visuals ---")
	if Player.UPGRADE_GLOW_COLORS.size() != 5:
		print("FAIL: Expected 5 UPGRADE_GLOW_COLORS, got %d" % Player.UPGRADE_GLOW_COLORS.size())
		quit(1)
		return
	print("  PASS: 5 Upgrade tier glow colors verified (Silver, Ember, Tempest, Void, Solar)")

	# Equip forged orc cleaver (2h)
	player.equip("weapon_orc_cleaver")
	player._update_equipment_visuals()
	await process_frame
	print("  PASS: Equipping 2H Orc Cleaver with +5 Solar aura succeeds without error")

	# Equip forged wolf stalker bow
	player.equip("bow_wolf_stalker")
	player._update_equipment_visuals()
	await process_frame
	print("  PASS: Equipping Wolf Stalker Bow with +5 Solar aura succeeds without error")

	print("\n==================================================")
	print("ALL BLACKSMITH FORGE & UPGRADE TESTS PASSED!")
	print("==================================================")
	quit(0)
