extends SceneTree
## Automated test suite for George Adventures v1.8.0 features:
## 1. Ash Valley expansion (Tier 10 gear, ash_forge, ash_lord boss, embers, volcanic sky tint)
## 2. More mobs (dark_knight, witch, thief with gold steal, raider, cursed_coffin)
## 3. Combat extensions (front kick, mid-air plunge attack, skill attack speed scaling)
## Run with:
##   cmd /c "godot --headless --script tools/v18_features_test.gd"

var failed := false

func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame

	print("=== Part 1: Ash Valley Expansion & Tier 10 Gear ===")
	# Tier 10 items
	check("Tier 10 weapon exists", ShopData.GEAR.has("weapon_10"))
	check("Tier 10 armor exists", ShopData.GEAR.has("armor_10"))
	check("Tier 10 shield exists", ShopData.GEAR.has("shield_10"))
	check("Tier 10 color exists in TIER_COLORS", ShopData.TIER_COLORS.size() >= 10)
	var w10: Dictionary = ShopData.GEAR.get("weapon_10", {})
	check("weapon_10 is level 40, tier 10, price 60000", w10.get("level") == 40 and w10.get("tier") == 10 and w10.get("price") == 60000)
	check("weapon_10 name is Greek (Αιώνιας Φλόγας)", "Αιώνιας Φλόγας" in String(w10.get("name", "")))

	# ash_forge shop & Damianos
	check("ash_forge shop exists", ShopData.SHOPS.has("ash_forge"))
	var forge: Dictionary = ShopData.SHOPS.get("ash_forge", {})
	var stock_ids: Array = []
	for item in forge.get("stock", []):
		stock_ids.append(item.get("id"))
	check("ash_forge sells Tier 10 items", "weapon_10" in stock_ids and "armor_10" in stock_ids and "shield_10" in stock_ids)
	check("Damianos has ash_forge assigned", QuestData.NPCS.get("damianos", {}).get("shop") == "ash_forge")

	# Ash Valley boss ash_lord
	var spawner = (load("res://scripts/enemies.gd") as GDScript)
	var kinds: Dictionary = spawner.KINDS
	check("ash_lord is defined in Enemies.KINDS", kinds.has("ash_lord"))
	check("ash_lord is in Enemies.BOSSES", "ash_lord" in spawner.BOSSES)
	var al: Dictionary = kinds.get("ash_lord", {})
	check("ash_lord has high HP and attack damage", float(al.get("max_health", 0)) >= 2000.0 and float(al.get("attack_damage", 0)) >= 30.0)
	check("ash_lord display name is Greek", "Ιγνάτιος" in String(al.get("display_name", "")))

	# Ash Valley spawns and embers
	var av = load("res://scripts/ash_valley.gd")
	var has_ash_lord := false
	for s in av.SPAWNS:
		if s[0] == "ash_lord":
			has_ash_lord = true
			break
	check("ash_lord is spawned in Ash Valley", has_ash_lord)

	print("\n=== Part 2: More Mobs & Interactions ===")
	for k in ["dark_knight", "witch", "thief", "raider", "cursed_coffin"]:
		check("%s is defined in Enemies.KINDS" % k, kinds.has(k))
		check("%s has valid health and damage" % k, float(kinds[k]["max_health"]) > 0.0 and float(kinds[k]["attack_damage"]) > 0.0)
		check("%s has non-empty display name" % k, String(kinds[k]["display_name"]) != "")
		check("%s is excluded from skeleton count (not a skeleton)" % k, not QuestData.is_skeleton(k))

	check("ash_lord is also excluded from skeleton count", not QuestData.is_skeleton("ash_lord"))
	check("thief steals gold on hit (steals_gold = 8)", kinds["thief"].get("steals_gold") == 8)
	check("cursed_coffin is a static dormant mob with wood sounds", kinds["cursed_coffin"].get("static_mob") == true and kinds["cursed_coffin"].get("sound_set") == "wood")
	check("MSG_GOLD_STOLEN is defined in Strings", Strings.MSG_GOLD_STOLEN != "" and "%d" in Strings.MSG_GOLD_STOLEN)

	# World spawns for new mobs
	var world_spawns: Array = spawner.SPAWNS
	for k in ["dark_knight", "witch", "thief", "raider", "cursed_coffin"]:
		var found := false
		for sp in world_spawns:
			if sp[0] == k:
				found = true
				break
		check("World spawns include %s" % k, found)

	print("\n=== Part 3: Combat Extensions (Kick, Air Plunge, Attack Speed) ===")
	# CombatExtras data & pure logic
	check("KICK_ANIM is Unarmed_Melee_Attack_Kick", CombatExtras.KICK_ANIM == "Unarmed_Melee_Attack_Kick")
	check("KICK_HIT and KICK_COMMIT timing are valid", CombatExtras.KICK_HIT < CombatExtras.KICK_COMMIT and CombatExtras.KICK_COOLDOWN >= 0.0)
	check("KICK_DAMAGE and KICK_KNOCK are configured", CombatExtras.KICK_DAMAGE > 0.5 and CombatExtras.KICK_KNOCK >= 10.0)
	check("kick_stun stuns bosses less than normal mobs", CombatExtras.kick_stun(true) < CombatExtras.kick_stun(false))
	check("AIR_ATTACK_ANIM is 1H_Melee_Attack_Chop", CombatExtras.AIR_ATTACK_ANIM == "1H_Melee_Attack_Chop")
	check("AIR_ATTACK_RADIUS and AIR_ATTACK_DAMAGE are configured", CombatExtras.AIR_ATTACK_RADIUS >= 4.0 and CombatExtras.AIR_ATTACK_DAMAGE >= 1.5)

	# Controls and settings
	var inputs_script = load("res://scripts/inputs.gd")
	check("Inputs.WATCHED includes kick", "kick" in inputs_script.WATCHED)
	check("GameSettings.REBINDABLE includes kick", load("res://scripts/game_settings.gd").REBINDABLE.any(func(r): return r[0] == "kick"))
	check("Strings.CONTROLS_HELP includes kick", Strings.CONTROLS_HELP.any(func(c): return c[0] == "C" and "Κλωτσιά" in c[1]))

	# Player combat mechanics
	var player_script = load("res://scripts/player.gd")
	var dummy_player = CharacterBody3D.new()
	dummy_player.set_script(player_script)
	check("Player has _kick_cd member", "_kick_cd" in dummy_player)
	check("Player has _kicking member", "_kicking" in dummy_player)
	check("Player has _kick_queued member", "_kick_queued" in dummy_player)
	check("Player has _air_attacking member", "_air_attacking" in dummy_player)
	check("Player has _start_kick method", dummy_player.has_method("_start_kick"))
	check("Player has _kick_hits method", dummy_player.has_method("_kick_hits"))
	check("Player has _start_air_attack method", dummy_player.has_method("_start_air_attack"))
	check("Player has _air_slam method", dummy_player.has_method("_air_slam"))
	dummy_player.free()

	print("\n=== Result ===")
	if failed:
		print("FAILED: Some checks did not pass.")
		quit(1)
	else:
		print("SUCCESS: All v1.8.0 feature checks passed!")
		quit(0)
