extends SceneTree
## Headless test for v1.11.0 features:
## 1. Combat & Gear expansion:
##    - High-tier skills: thunder_strike (lvl 15) and battle_cry (lvl 25)
##    - Gear Set Bonus: matching gear tiers >= 2 grant set bonus HP, defense, damage
## 2. Side Quests & NPCs:
##    - Frontier: Kyriakos NPC and f_patrols quest (kill 5 raiders)
##    - Ash Valley: a_crystals quest (collect 4 lava crystals) and crystal QuestItem
## 3. Invasion Variety & Rewards:
##    - Themed invasion nights (Shadows, Giants, Cult)
##    - Gilded morning victory chest with radiant beacon beam & light

var passed := 0
var failed := 0
var log_file: FileAccess


func _init() -> void:
	log_file = FileAccess.open("res://test_results.txt", FileAccess.WRITE)
	log_file.store_line("--- Running v111_features_test ---")
	print("--- Running v111_features_test ---")
	call_deferred("_run")


func check(desc: String, ok: bool) -> void:
	if ok:
		passed += 1
		var line := "  PASS: %s" % desc
		print(line)
		if log_file:
			log_file.store_line(line)
			log_file.flush()
	else:
		failed += 1
		var line := "  FAIL: %s" % desc
		print(line)
		if log_file:
			log_file.store_line(line)
			log_file.flush()


func _run() -> void:
	# Autoloads
	var quests = load("res://scripts/quests.gd").new()
	quests.name = "Quests"
	root.add_child(quests)

	var sound_mgr = load("res://scripts/sound_manager.gd").new()
	sound_mgr.name = "SoundManager"
	root.add_child(sound_mgr)

	await process_frame

	# 1. High-tier skills in SkillData
	check("SkillData has thunder_strike", SkillData.SKILLS.has("thunder_strike"))
	var ts = SkillData.SKILLS.get("thunder_strike", {})
	check("thunder_strike level is 15", ts.get("level") == 15)
	check("thunder_strike icon is bolt", ts.get("icon") == "bolt")

	check("SkillData has battle_cry", SkillData.SKILLS.has("battle_cry"))
	var bc = SkillData.SKILLS.get("battle_cry", {})
	check("battle_cry level is 25", bc.get("level") == 25)
	check("battle_cry icon is shout", bc.get("icon") == "shout")

	# 2. Player skills & buffs
	var player = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	await process_frame

	player.level = 1
	check("Level 1 player does not know thunder_strike", not player.knows_skill("thunder_strike"))
	check("Level 1 player does not know battle_cry", not player.knows_skill("battle_cry"))

	player.level = 15
	check("Level 15 player knows thunder_strike", player.knows_skill("thunder_strike"))
	check("Level 15 player does not know battle_cry", not player.knows_skill("battle_cry"))

	player.level = 25
	check("Level 25 player knows battle_cry", player.knows_skill("battle_cry"))

	var used_bc = player.use_skill("battle_cry")
	check("battle_cry fired successfully", used_bc)
	check("battle_cry buff duration active", player.buff_time("battle_cry") > 11.0)
	check("battle_cry buff multiplies damage", player._damage_mult() >= 1.30)
	check("attack_speed_stat reflects battle_cry", player.attack_speed_stat() >= 0.15)

	# 3. Gear Set Bonus
	check("Empty gear has set tier 0", ShopData.set_tier({}) == 0)
	var t2_gear = {"weapon": "weapon_2", "armor": "armor_2", "shield": "shield_2"}
	check("Matching tier 2 gear has set tier 2", ShopData.set_tier(t2_gear) == 2)
	var mixed_gear = {"weapon": "weapon_2", "armor": "armor_3", "shield": "shield_2"}
	check("Mismatched gear has set tier 0", ShopData.set_tier(mixed_gear) == 0)
	check("Set bonus name for tier 2 is Σετ Ατσαλιού", ShopData.set_bonus_name(2) == "Σετ Ατσαλιού")
	var mods_t2 = ShopData.set_bonus_mods(2)
	check("Set bonus mods contain hp_add", mods_t2.has("hp_add") and mods_t2["hp_add"] == 40.0)
	check("Set bonus mods contain defense", mods_t2.has("defense") and mods_t2["defense"] > 0.05)

	# Player equipping set
	player.gear_owned.clear()
	player.gear_owned.append("weapon_2")
	player.gear_owned.append("armor_2")
	player.gear_owned.append("shield_2")
	player.equip("weapon_2")
	player.equip("armor_2")
	player.equip("shield_2")
	check("Player stats reflect set_bonus source", player.stats._sources.has("set_bonus"))
	check("Player has active set tier 2", player._active_set_tier == 2)

	# 4. Frontier & Ash Valley Quests
	check("QuestData has kyriakos NPC", QuestData.NPCS.has("kyriakos"))
	check("QuestData has f_patrols quest", QuestData.QUESTS.has("f_patrols"))
	var fp = QuestData.QUESTS.get("f_patrols", {})
	check("f_patrols giver is kyriakos", fp.get("giver") == "kyriakos")
	check("f_patrols targets raider", fp["objectives"][0]["target"] == "raider")

	check("QuestData has a_crystals quest", QuestData.QUESTS.has("a_crystals"))
	var ac = QuestData.QUESTS.get("a_crystals", {})
	check("a_crystals item is crystal", ac["objectives"][0]["item"] == "crystal")
	check("QuestItem has crystal model", QuestItem.MODELS.has("crystal"))
	var av = load("res://scripts/ash_valley.gd")
	check("AshValley defines 4 crystals", av.CRYSTALS.size() == 4)
	var all_outside_lava := true
	for c in av.CRYSTALS:
		var dist_to_center: float = absf(c.y - av.stream_z(c.x))
		if dist_to_center <= av.STREAM_WIDTH * 0.5 + 1.5:
			all_outside_lava = false
			break
	check("All 4 lava crystals are placed safely outside the lava river and rim", all_outside_lava)

	var has_raider_spawns := false
	for s in Frontier.SPAWNS:
		if s[0] == "raider":
			has_raider_spawns = true
			break
	check("Frontier spawns contain raiders", has_raider_spawns)

	# 5. Invasion Themes & Morning Chest
	check("Strings has INVASION_THEME_SHADOWS", Strings.INVASION_THEME_SHADOWS.contains("ΕΙΣΒΟΛΗ ΣΚΙΩΝ"))
	check("Strings has INVASION_THEME_GIANTS", Strings.INVASION_THEME_GIANTS.contains("ΕΠΕΛΑΣΗ ΓΙΓΑΝΤΩΝ"))
	check("Strings has INVASION_THEME_CULT", Strings.INVASION_THEME_CULT.contains("ΝΥΧΤΑ ΑΙΡΕΤΙΚΩΝ"))
	check("Strings has INVASION_REWARD_CHEST", Strings.INVASION_REWARD_CHEST.contains("χρυσό σεντούκι της νίκης"))

	var inv_src := FileAccess.get_file_as_string("res://scripts/invasion.gd")
	check("Invasion implements theme_banner()", inv_src.contains("func theme_banner("))
	check("Invasion defines themed mob pools in _kind_pool", inv_src.contains("rogue") and inv_src.contains("dark_knight") and inv_src.contains("cultist"))
	check("Invasion creates VictoryBeam with CylinderMesh", inv_src.contains("VictoryBeam") and inv_src.contains("CylinderMesh.new()"))
	check("Invasion creates VictoryLight with OmniLight3D", inv_src.contains("VictoryLight") and inv_src.contains("OmniLight3D.new()"))

	var chest_src := FileAccess.get_file_as_string("res://scripts/chest.gd")
	check("Chest clears VictoryBeam on interact", chest_src.contains("find_child(\"VictoryBeam\""))
	check("Chest clears VictoryLight on interact", chest_src.contains("find_child(\"VictoryLight\""))

	player.queue_free()
	sound_mgr.queue_free()
	quests.queue_free()

	var summary := "\n--- v111_features_test Results: %d passed, %d failed ---" % [passed, failed]
	print(summary)
	if log_file:
		log_file.store_line(summary)
		log_file.store_line("ALL PASS" if failed == 0 else "TESTS FAILED")
		log_file.flush()
		log_file.close()

	if failed == 0:
		print("ALL PASS")
		quit(0)
	else:
		print("TESTS FAILED")
		quit(1)
