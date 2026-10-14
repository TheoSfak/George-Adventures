extends SceneTree
## The bandit kinds: models, shown props, animations, boss rules, spawn list, shared props helper:
##   godot --path . --headless --script tools/bandit_data_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _visible_props(root_node: Node3D) -> Array:
	var out := []
	for n in root_node.find_children("*", "Node3D", true, false):
		if n.name in CharacterProps.NODES and n.visible:
			out.append(String(n.name))
	out.sort()
	return out


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var spawner = get_first_node_in_group("enemy_spawner")
	var kinds: Dictionary = spawner.KINDS

	for k in ["bandit_thug", "bandit_archer", "bandit_thief", "bandit_chief"]:
		var d: Dictionary = kinds[k]
		check("%s: a human with a model, props and a tint" % k, d.get("human", false) and ResourceLoader.exists(d["model_path"]) and not d["show_nodes"].is_empty() and d["tint_color"].a > 0.0)
		var model := (load(d["model_path"]) as PackedScene).instantiate() as Node3D
		root.add_child(model)
		var names_ok := true
		for n in d["show_nodes"]:
			if model.find_child(n, true, false) == null:
				names_ok = false
		check("%s: every shown prop exists in the model" % k, names_ok)
		var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var needed: Array = ["Idle", d["walk_anim"], "Running_A", "Death_B", "Hit_A", d.get("attack_anim", "1H_Melee_Attack_Chop")]
		if d.get("ranged", false):
			needed.append(d["shoot_anim"])
		var missing := needed.filter(func(a): return not anim.has_animation(a))
		check("%s: has every animation it needs %s" % [k, str(missing)], missing.is_empty())
		model.queue_free()

	check("only the chief is a named boss with a one-minute respawn", kinds["bandit_chief"].has("respawn_after") and kinds["bandit_chief"]["respawn_after"] == 60.0
			and kinds["bandit_chief"].has("display_name") and not kinds["bandit_thug"].has("respawn_after"))
	check("the chief drops boss loot", "bandit_chief" in spawner.BOSSES)
	check("the chief calls thugs when hurt", kinds["bandit_chief"]["enrage_summon"] == "bandit_thug" and kinds["bandit_chief"]["enrage_below"] == 0.5)
	check("the archer shoots arrows from a distance", kinds["bandit_archer"]["ranged"] and kinds["bandit_archer"]["projectile_kind"] == "arrow")

	# the spawn list
	var counts := {}
	for s in spawner.SPAWNS:
		if String(s[0]).begins_with("bandit"):
			counts[s[0]] = counts.get(s[0], 0) + 1
			check("spawn %s at (%d, %d) is a known kind" % [s[0], s[1], s[2]], kinds.has(s[0]))
	check("one chief", counts.get("bandit_chief", 0) == 1)
	check("thugs, archers and a thief in the camp and on patrol", counts.get("bandit_thug", 0) == 6 and counts.get("bandit_archer", 0) == 5 and counts.get("bandit_thief", 0) == 1)

	# live enemies show only their own weapons, skeletons are untouched
	var thug = spawner.spawn_extra("bandit_thug", Vector3(0, 0.05, 30))
	var archer = spawner.spawn_extra("bandit_archer", Vector3(6, 0.05, 30))
	var thief = spawner.spawn_extra("bandit_thief", Vector3(12, 0.05, 30))
	var chief = spawner.spawn_extra("bandit_chief", Vector3(18, 0.05, 30))
	await create_timer(0.5).timeout
	check("thug shows an axe and a shield", _visible_props(thug) == ["1H_Axe", "Barbarian_Round_Shield"])
	check("archer shows a crossbow", _visible_props(archer) == ["1H_Crossbow"])
	check("thief shows two knives", _visible_props(thief) == ["Knife", "Knife_Offhand"])
	check("chief shows a two-handed axe", _visible_props(chief) == ["2H_Axe"])
	check("the chief is big", chief.model_scale > 1.5)
	var skeleton = spawner.spawn_extra("warrior", Vector3(24, 0.05, 30))
	await create_timer(0.3).timeout
	check("a skeleton is not a human and keeps its weapon attachments", not skeleton.human and _visible_props(skeleton).is_empty())
	for e in [thug, archer, thief, chief, skeleton]:
		e.queue_free()

	# the shared helper
	var knight := (load("res://assets/characters/Knight.glb") as PackedScene).instantiate() as Node3D
	root.add_child(knight)
	CharacterProps.apply(knight, ["1H_Sword", "Rectangle_Shield"])
	check("CharacterProps shows exactly the asked props", _visible_props(knight) == ["1H_Sword", "Rectangle_Shield"])
	knight.queue_free()
	check("the NPCs still hide their props", (func():
		for n in get_nodes_in_group("npcs"):
			if n.get("npc_id") == "stavros":
				return _visible_props(n).size() <= 3
		return false).call())
	quit(1 if failed else 0)
