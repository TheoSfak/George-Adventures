extends SceneTree

const TempleSanctumScript = preload("res://scripts/temple_interior.gd")
const TravelingMerchantScript = preload("res://scripts/traveling_merchant.gd")
const EnemiesScript = preload("res://scripts/enemies.gd")

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(desc: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS: %s" % desc)
	else:
		failed += 1
		printerr("  FAIL: %s" % desc)

func _run() -> void:
	var quests_node = load("res://scripts/quests.gd").new()
	quests_node.name = "Quests"
	root.add_child(quests_node)

	print("--- Running George Adventures v1.13.0 Features Test ---")

	# 1. Feature 1: Crafting & Equipment Upgrades
	print("\n[1] Testing Crafting & Upgrades...")
	check("MAX_UPGRADE_LEVEL is 3", ShopData.MAX_UPGRADE_LEVEL == 3)

	var u1: Dictionary = ShopData.upgrade_mods("weapon", 1)
	var u2: Dictionary = ShopData.upgrade_mods("armor", 2)
	var u3: Dictionary = ShopData.upgrade_mods("shield", 3)
	check("upgrade_mods weapon has damage_mult", u1.get("damage_mult", 0.0) > 0.0)
	check("upgrade_mods armor has hp_add and defense", u2.get("hp_add", 0.0) > 0.0 and u2.get("defense", 0.0) > 0.0)
	check("upgrade_mods shield has block_add and defense", u3.get("block_add", 0.0) > 0.0 and u3.get("defense", 0.0) > 0.0)

	var test_upgrades := {"weapon": 2, "armor": 1, "shield": 0}
	var total_mods := ShopData.total_upgrade_mods(test_upgrades)
	check("total_upgrade_mods accumulates damage_mult and hp_add", total_mods.get("damage_mult", 0.0) > 0.0 and total_mods.get("hp_add", 0.0) > 0.0)

	check("Crafting materials in ShopData.JUNK", ShopData.JUNK.has("bone_shard") and ShopData.JUNK.has("iron_scrap") and ShopData.JUNK.has("lava_ember"))
	check("can_upgrade_slot checks materials and gold", ShopData.can_upgrade_slot("weapon", 0, 150, {"iron_scrap": 3}))
	check("can_upgrade_slot returns false if not enough gold", not ShopData.can_upgrade_slot("weapon", 0, 10, {"iron_scrap": 3}))
	check("can_upgrade_slot returns false if not enough mats", not ShopData.can_upgrade_slot("weapon", 0, 150, {"iron_scrap": 0}))

	# 2. Feature 2: New Weapon Types
	print("\n[2] Testing Weapon Types (2H & Dual Wield)...")
	check("2H weapons recognized", ShopData.weapon_type("weapon_2h_1") == "2h" and ShopData.weapon_type("weapon_2h_3") == "2h")
	check("Dual wield weapons recognized", ShopData.weapon_type("weapon_dual_1") == "dual" and ShopData.weapon_type("weapon_dual_3") == "dual")
	check("Default 1H weapon recognized", ShopData.weapon_type("weapon_1") == "1h" and ShopData.weapon_type("") == "1h")
	check("CombatTiming combo_for 2h", CombatTiming.combo_for("2h") == CombatTiming.COMBO_2H)
	check("CombatTiming combo_for dual", CombatTiming.combo_for("dual") == CombatTiming.COMBO_DUAL)

	var anims := CombatTiming.animations()
	check("CombatTiming animations includes 2H anims", anims.has("2H_Melee_Attack_Slice") and anims.has("2H_Melee_Attack_Spin") and anims.has("2H_Melee_Attack_Chop"))
	check("CombatTiming animations includes Dual anims", anims.has("Dualwield_Melee_Attack_Slice") and anims.has("Dualwield_Melee_Attack_Chop"))

	# 3. Feature 3: Temple Sanctum & Story Part 5
	print("\n[3] Testing Temple Sanctum & Story Part 5...")
	check("Interiors.REGION_IDS includes 'temple'", Interiors.REGION_IDS.has("temple"))
	check("QuestData.QUESTS has t_sanctum", QuestData.QUESTS.has("t_sanctum"))
	check("QuestData.QUESTS has t_archon", QuestData.QUESTS.has("t_archon"))
	check("t_archon quest has ends_game=true", QuestData.QUESTS["t_archon"].get("ends_game", false) == true)
	check("a_boss ends_game flag removed", QuestData.QUESTS["a_boss"].get("ends_game", false) == false)

	var sanctum = TempleSanctumScript.new()
	check("TempleSanctum instantiates", sanctum != null and sanctum.spawn_point() != Vector3.ZERO)
	sanctum.free()

	# 4. Feature 4: Dynamic Events & Living World
	print("\n[4] Testing Living World (Scarecrows & Traveling Merchant)...")
	check("cursed_scarecrow in Enemies.KINDS", EnemiesScript.KINDS.has("cursed_scarecrow"))
	check("cinder_archon in Enemies.KINDS", EnemiesScript.KINDS.has("cinder_archon"))
	check("cinder_guardian in Enemies.KINDS", EnemiesScript.KINDS.has("cinder_guardian"))
	check("NOT_SKELETONS contains cursed_scarecrow", QuestData.NOT_SKELETONS.has("cursed_scarecrow"))
	check("NOT_SKELETONS contains cinder_archon", QuestData.NOT_SKELETONS.has("cinder_archon"))
	check("QuestData.QUESTS has f_scarecrows", QuestData.QUESTS.has("f_scarecrows"))
	check("QuestData.NPCS has pantelis", QuestData.NPCS.has("pantelis"))
	check("ShopData.SHOPS has wandering", ShopData.SHOPS.has("wandering"))

	var merchant = TravelingMerchantScript.new()
	check("TravelingMerchant instantiates with valid interact_range", merchant != null and merchant.interact_range() > 0.0)
	merchant.free()

	# 5. Feature 5: SFX Audio
	print("\n[5] Testing SFX Audio Variants...")
	var sfx_keys := ["craft_upgrade", "flame_altar", "scarecrow_groan", "swing_2h", "swing_dual"]
	var all_sfx := true
	for k in sfx_keys:
		if not SfxIds.VARIANTS.has(k) or SfxIds.VARIANTS[k] <= 0:
			all_sfx = false
			printerr("  FAIL: SfxIds missing key: %s" % k)
	check("All 5 new SFX IDs registered in SfxIds.VARIANTS", all_sfx)

	print("\n-------------------------------------------")
	print("Summary: %d Passed, %d Failed" % [passed, failed])
	if failed == 0:
		print("ALL v1.13.0 TESTS PASSED SUCCESSFULLY!")
	print("-------------------------------------------")

	quit(0 if failed == 0 else 1)
