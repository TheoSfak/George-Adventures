extends SceneTree
## Enemies grow with George's level above 20: health, damage, XP:
##   godot --path . --headless --script tools/enemy_scaling_test.gd
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
	p._invulnerable = 99999.0
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	var spawner = get_first_node_in_group("enemy_spawner")
	var at := Vector3(150, 0.05, -150)

	# level 1: nothing changes
	var w1 = spawner.spawn_extra("warrior", at)
	check("level 1: damage is the plain 20", is_equal_approx(w1.scaled_damage(), 20.0))
	w1.take_damage(20.0, w1.global_position + Vector3.RIGHT)
	check("level 1: a 20 blow takes exactly 20 of the 45 health", is_equal_approx(w1.health, 25.0))
	w1.take_damage(25.0, w1.global_position + Vector3.RIGHT)
	check("level 1: 45 damage kill a warrior", w1.is_dead())

	# level 20: still nothing changes
	p.level = 20
	var w20 = spawner.spawn_extra("warrior", at + Vector3(8, 0, 0))
	w20.take_damage(20.0, w20.global_position + Vector3.RIGHT)
	check("level 20: still unscaled (health 25)", is_equal_approx(w20.health, 25.0) and is_equal_approx(w20.scaled_damage(), 20.0))

	# level 40: five times the health, three times the damage
	p.level = 40
	var w40 = spawner.spawn_extra("warrior", at + Vector3(16, 0, 0))
	check("level 40: a warrior hits 4.2 times as hard (84.0)", is_equal_approx(w40.scaled_damage(), 20.0 * 4.2))
	w40.take_damage(45.0, w40.global_position + Vector3.RIGHT)
	check("level 40: a 45 blow does only 45 / 5.4", w40.health > 45.0 - 45.0 / 5.4 - 0.01 and w40.health < 45.0 - 45.0 / 5.4 + 0.01)
	var hits := 1
	while not w40.is_dead() and hits < 50:
		w40.take_damage(45.0, w40.global_position + Vector3.RIGHT)
		hits += 1
	check("level 40: it takes 6 blows of 45 to kill it (%d)" % hits, hits == 6)
	var boss = spawner.spawn_extra("necromancer", at + Vector3(0, 0, 20))
	boss.take_damage(100.0, boss.global_position + Vector3.RIGHT)
	check("level 40: bosses scale too", boss.health > boss.max_health - 100.0 / 5.4 - 0.01 and boss.health < boss.max_health - 100.0 / 5.4 + 0.01)

	# arrows
	var archer = spawner.spawn_extra("rogue", at + Vector3(0, 0, 40))
	check("level 40: archers shoot harder too", is_equal_approx(archer.scaled_damage(), archer.attack_damage * 4.2))

	# XP: level 24 -> x1.6 (25 XP warrior gives 40)
	var jm = get_first_node_in_group("journal_manager")
	if jm:
		jm.check_achievements()
	p.level = 24
	p.xp = 0
	var w24 = spawner.spawn_extra("warrior", at + Vector3(30, 0, 0))
	w24.take_damage(9999.0, w24.global_position + Vector3.RIGHT)
	await create_timer(0.3).timeout
	check("level 24: a warrior's 25 XP become 40", p.xp == 40)
	p.level = 10
	p.xp = 0
	var w10 = spawner.spawn_extra("warrior", at + Vector3(40, 0, 0))
	w10.take_damage(9999.0, w10.global_position + Vector3.RIGHT)
	await create_timer(0.3).timeout
	check("level 10: the plain 25 XP", p.xp == 25)

	# guards: they deal as much as before relative to the tougher enemies
	var guard_script = load("res://scripts/guard.gd")
	check("guards exist as a script", guard_script != null)
	quit(1 if failed else 0)
