extends SceneTree
## The data of story part 4 (the Ash Valley): creatures, quests, NPCs, strings, the shard item, voices:
##   godot --path . --headless --script tools/ash_data_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var spawner = (load("res://scripts/enemies.gd") as GDScript)
	var kinds: Dictionary = spawner.KINDS
	# ---------------------------------------------------------------- creatures
	for k in ["ember_skeleton", "ash_caster", "magma_golem", "pyrforos"]:
		check("%s is defined with its kind_id" % k, kinds.has(k) and kinds[k]["kind_id"] == k)
		check("%s has health, damage and a name" % k, float(kinds[k]["max_health"]) > 0.0 and float(kinds[k]["attack_damage"]) > 0.0 and String(kinds[k]["display_name"]) != "")
	check("the caster throws fire orbs", kinds["ash_caster"]["projectile_kind"] == "fire" and kinds["ash_caster"]["ranged"])
	check("the golem is a dormant prop creature", kinds["magma_golem"]["dormant"] and kinds["magma_golem"]["static_mob"] and kinds["magma_golem"]["stomp_slow"] > 0.0)
	check("the boss belongs to a_boss and comes back after 60 s", kinds["pyrforos"]["quest"] == "a_boss" and float(kinds["pyrforos"]["respawn_after"]) == 60.0)
	check("the boss enrages and calls ember skeletons", kinds["pyrforos"]["enrage_below"] == 0.5 and kinds["pyrforos"]["enrage_summon"] == "ember_skeleton")
	check("the boss is listed as a boss", "pyrforos" in spawner.BOSSES)
	check("a level-20 hero meets stronger creatures than the Frontier's", float(kinds["ember_skeleton"]["max_health"]) > float(kinds["shadow_knight"]["max_health"]) and float(kinds["pyrforos"]["max_health"]) > float(kinds["malakar"]["max_health"]))
	check("every summoned kind exists", kinds.has(kinds["pyrforos"]["enrage_summon"]))
	check("the kinds count for skeleton targets, except the golem", QuestData.is_skeleton("ember_skeleton") and QuestData.is_skeleton("ash_caster") and QuestData.is_skeleton("pyrforos") and not QuestData.is_skeleton("magma_golem"))
	var av = load("res://scripts/ash_valley.gd")
	for s in av.SPAWNS:
		check("spawn kind %s exists" % s[0], kinds.has(s[0]))
		var local := Vector2(s[1], s[2])
		check("%s at %s lies in the bounds and outside the camp" % [s[0], str(local)], av.BOUNDS.has_point(local) and local.distance_to(av.CAMP) > av.CAMP_RADIUS)
	var counts := {}
	for s in av.SPAWNS:
		counts[s[0]] = int(counts.get(s[0], 0)) + 1
	check("enough creatures for the quest (>= 8 ember skeletons, >= 4 casters)", int(counts["ember_skeleton"]) >= 8 and int(counts["ash_caster"]) >= 4)
	check("three magma golems and one boss", int(counts["magma_golem"]) == 3 and int(counts["pyrforos"]) == 1)
	# ---------------------------------------------------------------- quests
	var chain := ["a_gate", "a_embers", "a_shards", "a_boss"]
	for id in chain:
		check("quest %s exists with Greek texts" % id, QuestData.QUESTS.has(id) and QuestData.QUESTS[id]["title"] != "" and QuestData.QUESTS[id]["offer"].size() > 0 and QuestData.QUESTS[id]["complete"].size() > 0 and QuestData.QUESTS[id]["progress"].size() > 0)
		var q: Dictionary = QuestData.QUESTS[id]
		check("%s: giver and turn-in are NPCs" % id, QuestData.NPCS.has(q["giver"]) and QuestData.NPCS.has(q["turn_in"]))
		for r in q["requires"]:
			check("%s requires an existing quest (%s)" % [id, r], QuestData.QUESTS.has(r))
	check("a_gate comes after the Frontier story", QuestData.QUESTS["a_gate"]["requires"] == ["f_return"])
	check("a_embers and a_shards need the gate", QuestData.QUESTS["a_embers"]["requires"] == ["a_gate"] and QuestData.QUESTS["a_shards"]["requires"] == ["a_gate"])
	check("a_boss needs both", "a_embers" in QuestData.QUESTS["a_boss"]["requires"] and "a_shards" in QuestData.QUESTS["a_boss"]["requires"])
	check("a_gate asks to reach the valley", QuestData.QUESTS["a_gate"]["objectives"][0]["type"] == "reach" and QuestData.QUESTS["a_gate"]["objectives"][0]["place"] == "ashvalley")
	check("a_embers: 8 ember skeletons and 4 casters", QuestData.QUESTS["a_embers"]["objectives"][0]["target"] == "ember_skeleton" and QuestData.QUESTS["a_embers"]["objectives"][0]["count"] == 8 and QuestData.QUESTS["a_embers"]["objectives"][1]["target"] == "ash_caster" and QuestData.QUESTS["a_embers"]["objectives"][1]["count"] == 4)
	check("a_shards: 3 shards", QuestData.QUESTS["a_shards"]["objectives"][0]["item"] == "shard" and QuestData.QUESTS["a_shards"]["objectives"][0]["count"] == 3)
	check("a_boss kills the boss and ends the part", QuestData.QUESTS["a_boss"]["objectives"][0]["target"] == "pyrforos" and QuestData.QUESTS["a_boss"].get("ends_game", false))
	check("the quest 'boss' target is the quest of the kind", kinds["pyrforos"]["quest"] == "a_boss")
	check("rewards are big enough for levels 20 to 40", QuestData.QUESTS["a_boss"]["reward"]["xp"] >= 6000 and QuestData.QUESTS["a_embers"]["reward"]["xp"] >= 2500)
	var texts := 0
	for id in chain:
		for key in ["offer", "progress", "complete"]:
			for line in QuestData.QUESTS[id][key]:
				texts += 1
				check("%s %s line is Greek (%s...)" % [id, key, String(line).left(14)], _has_greek(line))
	check("quest texts counted", texts >= 20)
	# ---------------------------------------------------------------- people, items, strings, voices
	for npc in ["theofilos", "damianos"]:
		check("NPC %s has a Greek name, a model and idle lines" % npc, _has_greek(QuestData.NPCS[npc]["name"]) and ResourceLoader.exists(QuestData.NPCS[npc]["model"]) and QuestData.NPCS[npc]["idle"].size() >= 2)
		check("NPC %s has a voice" % npc, VoiceData.NPC_PROFILES.has(npc) and VoiceData.PROFILES.has(VoiceData.NPC_PROFILES[npc]))
		check("the voice of %s is found by name" % npc, VoiceData.profile_for(QuestData.NPCS[npc]["name"]) == VoiceData.NPC_PROFILES[npc])
	check("the shard item has a name and a model", QuestData.ITEMS.has("shard") and ResourceLoader.exists(load("res://scripts/quest_item.gd").MODELS["shard"]["path"]))
	var consts: Dictionary = (load("res://scripts/strings_el.gd") as GDScript).get_script_constant_map()
	for s in ["PYRFOROS_ENRAGE", "ASH_SEALED", "MSG_ASH_SEALED", "PROMPT_ASH_BACK", "PROMPT_TEMPLE_GATE", "MSG_TEMPLE_SEALED", "MSG_TEMPLE_OPEN"]:
		check("Strings.%s is Greek" % s, consts.has(s) and _has_greek(consts[s]))
	check("the valley has a building name", Strings.BUILDING_NAMES.has("ashvalley"))
	# ---------------------------------------------------------------- the region framework
	var interiors_script = load("res://scripts/interiors.gd")
	check("the region registry knows both regions", "frontier" in interiors_script.REGION_IDS and "ashvalley" in interiors_script.REGION_IDS)
	check("the gates are far apart", av.VILLAGE_GATE.distance_to(load("res://scripts/frontier.gd").VILLAGE_GATE) > 100.0)
	check("the valley stands where no other region stands", av.ORIGIN.distance_to(load("res://scripts/frontier.gd").ORIGIN) > 5000.0)
	check("the lava shader exists", ResourceLoader.exists("res://shaders/lava.gdshader"))
	quit(1 if failed else 0)


func _has_greek(text: String) -> bool:
	for i in text.length():
		var c := text.unicode_at(i)
		if c >= 0x370 and c <= 0x3FF:
			return true
	return false
