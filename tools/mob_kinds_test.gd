extends SceneTree
## The data of the new creatures: godot --path . --headless --script tools/mob_kinds_test.gd
var failed := false
const NEW := ["pumpkin", "haunted_tree", "golem", "bone_heap", "mimic", "cultist", "cult_priest"]


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func has_greek(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if c >= 0x370 and c <= 0x3ff:
			return true
	return false


func _run() -> void:
	await process_frame
	var enemies = load("res://scripts/enemies.gd")
	var kinds: Dictionary = enemies.KINDS
	check("all seven new kinds exist", NEW.all(func(k): return kinds.has(k)))
	var ok_ids := true
	var ok_stats := true
	var ok_models := true
	var ok_names := true
	var ok_anim := true
	for k in NEW:
		var s: Dictionary = kinds[k]
		ok_ids = ok_ids and s["kind_id"] == k
		ok_stats = ok_stats and float(s["max_health"]) > 0.0 and int(s["xp_reward"]) >= 0 and float(s.get("aggro_range", 14.0)) > 0.0
		if k != "bone_heap":
			ok_names = ok_names and has_greek(String(s.get("display_name", "")))
		if s.get("static_mob", false):
			var paths: Array = []
			if String(s.get("model_path", "")) != "":
				paths.append(s["model_path"])
			for part in s.get("parts", []):
				if part.has("path"):
					paths.append(part["path"])
			ok_models = ok_models and not paths.is_empty()
			for path in paths:
				ok_models = ok_models and ResourceLoader.exists(path)
				var scene := load(path) as PackedScene
				if scene != null:
					var node := scene.instantiate()
					ok_anim = ok_anim and node.find_child("AnimationPlayer", true, false) == null
					node.queue_free()
		else:
			ok_models = ok_models and ResourceLoader.exists(String(s["model_path"]))
	check("kind_id matches the key", ok_ids)
	check("health, xp and aggro range are sane", ok_stats)
	check("every creature but the heap has a Greek name", ok_names)
	check("the models and parts of the static creatures load", ok_models)
	check("static creatures have no AnimationPlayer (their body language is made in code)", ok_anim)

	# sounds
	var sound_sets: Dictionary = (load("res://scripts/enemy.gd") as GDScript).SOUND_SETS
	var sfx_ids = load("res://scripts/sfx_ids.gd")
	var sounds_ok := true
	for set_name in sound_sets:
		for id in sound_sets[set_name].values():
			sounds_ok = sounds_ok and sfx_ids.VARIANTS.has(id)
	check("every sound of every sound set exists", sounds_ok)
	var sets_ok := true
	for k in NEW:
		var set_name: String = kinds[k].get("sound_set", "bone")
		sets_ok = sets_ok and (set_name == "bone" or sound_sets.has(set_name))
	check("every kind uses a known sound set", sets_ok)

	# the dormant and rooted ones
	check("the golem and the bone heap sleep, the others do not", kinds["golem"]["dormant"] and kinds["bone_heap"]["dormant"] and not kinds["pumpkin"].get("dormant", false))
	check("the bone heap bursts into skeletons of a known kind", kinds.has(kinds["bone_heap"]["wake_spawn"]) and int(kinds["bone_heap"]["wake_count"]) == 3)
	check("the haunted tree is rooted (no speed) with a long reach", float(kinds["haunted_tree"]["chase_speed"]) == 0.0 and float(kinds["haunted_tree"]["attack_range"]) >= 4.0)
	check("the priest calls cultists and is a boss", kinds["cult_priest"]["summon_kind"] == "cultist" and enemies.BOSSES.has("cult_priest") and kinds["cult_priest"].has("respawn_after"))
	check("the mimic never comes back", kinds["mimic"]["respawn"] == false)

	# spawns
	var counts := {}
	var all_known := true
	for s in enemies.SPAWNS:
		counts[s[0]] = int(counts.get(s[0], 0)) + 1
		all_known = all_known and kinds.has(s[0])
	check("every spawn is a known kind", all_known)
	check("pumpkins 5, trees 3, golems 3, bone heaps 4, cultists 5, one priest", counts.get("pumpkin", 0) == 5 and counts.get("haunted_tree", 0) == 3 and counts.get("golem", 0) == 3 and counts.get("bone_heap", 0) == 4 and counts.get("cultist", 0) == 5 and counts.get("cult_priest", 0) == 1)

	# quests
	var q: Dictionary = QuestData.QUESTS["cult"]
	check("the cult quest unlocks after the Bone King", q["requires"] == ["king"] and q["giver"] == "stavros" and q["turn_in"] == "stavros")
	var targets_ok := true
	for o in q["objectives"]:
		targets_ok = targets_ok and kinds.has(o["target"])
	check("its objectives name real kinds", targets_ok and q["objectives"][0]["count"] == 5)
	check("its text is Greek", has_greek(q["title"]) and has_greek(q["offer"][0]) and has_greek(q["complete"][0]) and has_greek(q["progress"][0]))
	var not_skeletons := true
	for k in NEW:
		not_skeletons = not_skeletons and not QuestData.is_skeleton(k)
	check("none of them counts as a skeleton for the skeleton quests", not_skeletons and QuestData.is_skeleton("minion") and QuestData.is_skeleton("warrior"))
	check("the strings exist", has_greek(Strings.MIMIC_REVEAL) and Strings.MAP_PLACES.has("cult"))

	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
