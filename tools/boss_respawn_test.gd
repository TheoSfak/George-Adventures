extends SceneTree
## Bosses and big mobs come back a minute after they die (a killed boss can never block a quest):
##   godot --path . --headless --script tools/boss_respawn_test.gd      (takes about 75 s)
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func alive(kind: String) -> Array:
	return get_nodes_in_group("enemies").filter(func(e): return e.kind_id == kind and not e.is_dead())


func kill_all(kind: String) -> int:
	var n := 0
	for e in alive(kind):
		e.take_damage(99999.0, e.global_position + Vector3.RIGHT)
		n += 1
	return n


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	var spawner = get_first_node_in_group("enemy_spawner")
	var q = root.get_node("/root/Quests")

	# the kinds: every quest boss and the big mobs carry a 60 s timer; the invasion bosses and ordinary skeletons do not
	var kinds: Dictionary = spawner.KINDS
	for k in ["captain", "king", "warden_bone", "warden_flame", "warden_shadow", "necromancer", "giant_skeleton", "malakar", "brute", "shadow_knight"]:
		check("%s respawns after 60 s" % k, kinds[k].get("respawn", true) and kinds[k].get("respawn_after", 0.0) == 60.0)
	check("the night invaders never come back", kinds["warlord"]["respawn"] == false and kinds["night_lord"]["respawn"] == false)
	check("ordinary skeletons keep the normal timer", not kinds["minion"].has("respawn_after"))

	# kill the captain (quarry), a brute, and a catacomb boss placed far from George
	check("the captain stands in the quarry", alive("captain").size() == 1)
	var brutes_before := alive("brute").size()
	check("there are brutes", brutes_before > 0)
	var boss = spawner.spawn_extra("necromancer", Vector3(120, 0.05, 130))
	check("spawn_extra makes a necromancer", boss != null and alive("necromancer").size() == 1)
	check("a quest boss is unique: asking again returns the same one", spawner.spawn_extra("necromancer", Vector3(60, 0.05, 130)) == boss and alive("necromancer").size() == 1)
	kill_all("captain")
	kill_all("necromancer")
	var first_brute = alive("brute")[0]
	first_brute.take_damage(99999.0, first_brute.global_position + Vector3.RIGHT)
	await create_timer(0.5).timeout
	check("they are dead now", alive("captain").is_empty() and alive("necromancer").is_empty() and alive("brute").size() == brutes_before - 1)

	# the quest of the captain starts while he is dead: nobody to kill yet (it waits for the timer)
	await create_timer(50.0).timeout
	check("after 50 s they are still gone", alive("captain").is_empty() and alive("necromancer").is_empty() and alive("brute").size() == brutes_before - 1)
	await create_timer(16.0).timeout
	check("after 66 s the captain is back", alive("captain").size() == 1)
	check("the necromancer is back", alive("necromancer").size() == 1)
	check("the brute is back", alive("brute").size() == brutes_before)
	check("no duplicates", alive("captain").size() == 1 and alive("necromancer").size() == 1)

	# a respawned boss counts for the quest again
	q.state["captain"] = 2     # ACTIVE
	var before: int = q.progress["captain"][0]
	kill_all("captain")
	await create_timer(0.3).timeout
	check("the new captain counts for the quest", q.progress["captain"][0] == before + 1)
	quit(1 if failed else 0)
