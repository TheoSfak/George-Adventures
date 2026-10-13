extends SceneTree
## The Night Lord kind, stat overrides on invaders and invader helpers:
##   godot --path . --headless --script tools/invasion_boss_world_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func approx(a: float, b: float) -> bool:
	return absf(a - b) < 0.01


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var spawner = get_first_node_in_group("enemy_spawner")
	check("KINDS has night_lord", spawner.KINDS.has("night_lord"))
	var base: Dictionary = spawner.KINDS["night_lord"]
	check("it is a named boss that does not come back", base["display_name"] == "Άρχοντας της Νύχτας" and base["respawn"] == false)
	check("it summons and enrages", base["summon_kind"] == "minion" and base["enrage_below"] == 0.5 and base["enrage_summon"] == "warrior")
	check("it is listed among the bosses (always drops a charm)", "night_lord" in spawner.BOSSES)

	var boss = spawner.spawn_invader("night_lord", Vector3(0, 0.05, 60), Vector3.ZERO, InvasionBoss.overrides(2, base))
	await process_frame
	check("the boss is an invader", boss.invader and boss.is_in_group("invaders"))
	check("tier 2 health is 1260 (max and current)", approx(boss.max_health, 1260.0) and approx(boss.health, 1260.0))
	check("tier 2 damage is 39.2", approx(boss.attack_damage, 39.2))
	check("tier 2 may keep 5 helpers and is named II", boss.summon_max == 5 and boss.display_name == "Άρχοντας της Νύχτας II")

	boss.call("_summon")
	var helpers: Array = boss.get("_summons")
	check("the boss calls two helpers", helpers.size() == 2)
	var all_march := helpers.size() > 0
	for h in helpers:
		if not (h.invader and h.is_in_group("invaders") and h.march_target == boss.march_target):
			all_march = false
	check("the helpers of an invader are invaders marching to the same place", all_march)

	var plain = spawner.spawn_extra("minion", Vector3(40, 0.05, 40))
	plain.summon_kind = "minion"
	plain.call("_summon")
	var plain_helpers: Array = plain.get("_summons")
	var none_invade := plain_helpers.size() > 0
	for h in plain_helpers:
		if h.invader:
			none_invade = false
	check("the helpers of an ordinary skeleton are not invaders", none_invade)
	quit(1 if failed else 0)
