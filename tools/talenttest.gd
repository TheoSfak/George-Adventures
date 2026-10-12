extends SceneTree
## Talent tree and the six new skills:  godot --path . --resolution 1280x720 --script tools/talenttest.gd -- <outdir>
var out := "."
var p: Player


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.1).timeout
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)


func spawn_dummies(count: int, dist: float, hp := 800.0) -> Array:
	var made := []
	var enemies := get_nodes_in_group("enemies")
	for i in count:
		var e: Enemy = enemies[i]
		e.set_physics_process(false)
		e.max_health = hp
		e.health = hp
		var a := TAU * float(i) / float(count) + 0.3
		e.global_position = p.global_position + Vector3(sin(a), 0, cos(a)) * dist
		made.append(e)
	return made


func learn(id: String, times: int) -> void:
	for i in times:
		p.learn_talent(id)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	p = get_first_node_in_group("player") as Player
	p.teleport(Vector3(0, 0.05, 22), PI)
	await create_timer(0.4).timeout

	# --- points and tier gates
	print("1) level 1 points: ", p.talent_points_free(), " (expect 0)")
	p.gain_xp(100000)
	print("   level ", p.level, " points: ", p.talent_points_free(), " (expect 19)")
	print("   learn tier-2 node g_fort with no points in the branch: ", p.learn_talent("g_fort"), " (expect false)")
	learn("g_hp", 4)
	print("   g_hp 4 times (max 3): rank ", p.talents["g_hp"], " (expect 3), points left ", p.talent_points_free(), " (expect 16)")
	print("   max hp ", p.max_health, " (expect ", p.base_max_health + 45.0, ")")
	learn("g_def", 3)
	learn("g_block", 2)
	print("   taunt node before the tier opens (8 points in branch): ", p.learn_talent("g_taunt"), " (expect true: tier 1 needs 5)")
	print("   g_wall (tier 2 needs 10, has ", TalentData.points_in_branch(p.talents, "guardian"), "): ", p.learn_talent("g_wall"), " (expect false)")
	learn("g_regen", 2)
	print("   g_wall now: ", p.learn_talent("g_wall"), " (expect true), defense ", p.stats.total("defense"), " (expect 0.09)")
	print("   bar: ", p.bar)

	# --- the window
	await press("talents")
	await create_timer(0.3).timeout
	await shot("talents_window")
	await press("talents")
	await press("skillbook")
	await create_timer(0.3).timeout
	await shot("talents_skillbook")
	await press("skillbook")

	# --- respec
	var cost := p.respec_cost()
	p.gold = 5000
	print("2) respec costs ", cost, " (expect 1000); ", p.respec(), " gold ", p.gold, " (expect 4000), talents ", p.talents, ", points ", p.talent_points_free())

	# --- skills: give the whole set by writing the talents directly
	p.talents = {"g_taunt": 1, "g_wall": 1, "w_frenzy": 1, "w_leap": 1, "s_flame": 1, "s_sanct": 1}
	p._recalc()
	for id in ["taunt", "wall", "frenzy", "leap", "flame", "sanctuary"]:
		print("   knows ", id, ": ", p.knows_skill(id))
	p.bar.assign(["taunt", "wall", "frenzy", "leap", "flame", "sanctuary", "item:health", "item:power"])
	p.bar_changed.emit()
	p.base_damage = 15.0
	p._recalc()

	# --- taunt: stuns and cuts damage taken
	var ring := spawn_dummies(3, 5.0)
	await press("slot_1")
	await create_timer(0.3).timeout
	var stunned := ring.map(func(e): return e._state == Enemy.State.HURT)
	print("3) taunt: enemies stunned ", stunned, ", shout buff ", snappedf(p.buff_time("shout"), 0.1), " (expect ~6)")
	var hp := p.health
	p.take_damage(40.0, p.global_position + Vector3(2, 0, 0))
	print("   40 damage under the shout took ", snappedf(hp - p.health, 0.1), " (expect 30)")
	await shot("skills_taunt")
	await create_timer(1.5).timeout

	# --- wall: invulnerable
	p.health = p.max_health
	await press("slot_2")
	hp = p.health
	p.take_damage(100.0, p.global_position + Vector3(2, 0, 0))
	print("4) wall: buff ", snappedf(p.buff_time("wall"), 0.1), ", 100 damage took ", hp - p.health, " (expect 0)")
	await shot("skills_wall")
	await create_timer(3.4).timeout

	# --- frenzy
	await press("slot_3")
	print("5) frenzy: buff ", snappedf(p.buff_time("frenzy"), 0.1), " (expect ~8)")
	var d := spawn_dummies(1, 2.0)
	d[0].global_position = p.global_position + p._facing() * 2.0
	p.health = p.max_health - 50.0
	var before := p.health
	p._start_attack()
	await create_timer(0.7).timeout
	print("   a swing: dummy lost ", 800.0 - d[0].health, " hp (expect 15*1.25 = 18.75), health regained ", snappedf(p.health - before, 0.1), " (expect ~2.25 from 12% lifesteal)")
	await create_timer(8.0).timeout

	# --- leap
	var target := spawn_dummies(2, 5.0)
	for e in target:
		e.global_position = p.global_position + p._facing() * 6.0
	var start := p.global_position
	await press("slot_4")
	await create_timer(0.55).timeout
	await shot("skills_leap_air")
	await create_timer(1.2).timeout
	print("6) leap: moved ", snappedf(start.distance_to(p.global_position), 0.1), " m, dummies lost ", target.map(func(e): return 800.0 - e.health), " (expect ~30 each if in 4.5 m), stunned ", target.map(func(e): return e._state == Enemy.State.HURT))
	await shot("skills_leap_land")
	await create_timer(1.0).timeout

	# --- flame
	var around := spawn_dummies(3, 4.0)
	p.health = p.max_health - 80.0
	before = p.health
	await press("slot_5")
	await create_timer(0.3).timeout
	print("7) flame: damage ", around.map(func(e): return 800.0 - e.health), " (expect 33 each), healed ", snappedf(p.health - before, 0.1), " (expect ~24.75)")
	await shot("skills_flame")
	await create_timer(1.2).timeout

	# --- sanctuary
	p.health = p.max_health - 100.0
	before = p.health
	await press("slot_6")
	await create_timer(2.0).timeout
	print("8) sanctuary: healed ", snappedf(p.health - before, 0.1), " in 2 s (expect ~", snappedf(p.max_health * 0.04 * 2.0, 0.1), ")")
	await shot("skills_sanctuary")

	# --- rebirth
	p.talents["s_rebirth"] = 1
	p._recalc()
	p._invulnerable = 0.0
	p._wall_time = 0.0
	p.health = 5.0
	p.take_damage(500.0, p.global_position + Vector3(2, 0, 0))
	print("9) rebirth: dead ", p.is_dead, " (expect false), health ", p.health, " of ", p.max_health, " (expect 50%)")

	# --- cooldown reduction
	p.talents = {"w_cdr": 3}
	p._recalc()
	print("10) cooldown of power strike with 15% reduction: ", p.cooldown_total("power_strike"), " (expect 4.25)")

	# --- the complete talent window for a screenshot
	p.talents = {"g_hp": 3, "g_def": 2, "w_dmg": 2, "w_crit": 3, "w_cdr": 2, "w_frenzy": 1, "s_heal": 1}
	p._recalc()
	await press("talents")
	await create_timer(0.3).timeout
	await shot("talents_window_2")
	quit()
