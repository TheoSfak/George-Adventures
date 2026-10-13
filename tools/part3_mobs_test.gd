extends SceneTree
## The new Frontier creatures, the enrage phase and the slowing shot:
##   godot --path . --headless --script tools/part3_mobs_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var spawner = get_first_node_in_group("enemy_spawner")
	for kind in ["shadow_knight", "soul_collector", "giant_skeleton", "malakar"]:
		check("KINDS has %s" % kind, spawner.KINDS.has(kind))
	if failed:
		quit(1)
		return
	check("giant skeleton belongs to f_wall", spawner.KINDS["giant_skeleton"]["quest"] == "f_wall")
	check("malakar belongs to f_malakar", spawner.KINDS["malakar"]["quest"] == "f_malakar")
	check("both are listed as bosses", "giant_skeleton" in spawner.BOSSES and "malakar" in spawner.BOSSES)

	var at := Vector3(0.0, 0.05, 40.0)
	var knight = spawner.spawn_extra("shadow_knight", at)
	check("shadow knight spawns with 190 health", knight != null and knight.max_health == 190.0)
	var caster = spawner.spawn_extra("soul_collector", at + Vector3(12, 0, 0))
	check("soul collector shoots slowing souls", caster != null and caster.ranged and caster.projectile_slows and caster.projectile_kind == "soul")
	var giant = spawner.spawn_extra("giant_skeleton", at + Vector3(0, 0, 12))
	check("giant skeleton is big and slow", giant != null and giant.model_scale > 2.0 and giant.chase_speed < 4.0)

	var boss = spawner.spawn_extra("malakar", at + Vector3(-12, 0, 0))
	check("malakar starts without helpers", boss != null and boss.summon_kind == "" and not boss._enraged)
	boss.take_damage(boss.max_health * 0.40, boss.global_position + Vector3(0, 0, 3))
	check("not enraged at 60% health", not boss._enraged)
	boss.take_damage(boss.max_health * 0.15, boss.global_position + Vector3(0, 0, 3))
	check("enraged below 50% health and calls shadow knights", boss._enraged and boss.summon_kind == "shadow_knight")

	p.slow(0.5)
	check("George is slowed", p.is_slowed())
	await create_timer(0.8).timeout
	check("the slow wears off", not p.is_slowed())
	quit(1 if failed else 0)
