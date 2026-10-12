extends SceneTree
## Skills, action bar and potions:  godot --path . --resolution 1280x720 --script tools/skilltest.gd -- <outdir>
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


## Puts `count` frozen test skeletons in a ring `dist` metres from George.
func spawn_dummies(count: int, dist: float, hp := 500.0) -> Array:
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


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	p = get_first_node_in_group("player") as Player
	p.teleport(Vector3(0, 0.05, 22), PI)   # facing north, in the open square
	await create_timer(0.5).timeout
	print("bar: ", p.bar)

	# --- locked skills
	await press("slot_5")
	print("1) charge at level 1 -> cooldown ", p.cooldown_left("charge"), " (expect 0, skill locked)")
	await press("slot_3")
	print("   whirlwind at level 1 -> cooldown ", p.cooldown_left("whirlwind"), " (expect 0)")

	# --- power strike (unlocked at level 1): 15 * 2.2 = 33
	var d := spawn_dummies(1, 2.2)
	d[0].global_position = p.global_position + Vector3(0, 0, -2.2)   # straight ahead
	await press("slot_1")
	await create_timer(0.7).timeout
	print("2) power strike: dummy lost ", 500.0 - d[0].health, " hp (expect ~33), cooldown ", snappedf(p.cooldown_left("power_strike"), 0.1), " (expect ~4.x)")
	await create_timer(1.2).timeout

	# --- unlock everything
	p.gain_xp(2000)
	print("   level now ", p.level)
	await create_timer(1.0).timeout

	# --- guard
	await press("slot_2")
	var hp := p.health
	p.take_damage(40.0, p.global_position + Vector3(2, 0, 0))
	print("3) guard: buff ", snappedf(p.buff_time("guard"), 0.1), " s; 40 damage took ", hp - p.health, " (expect 10)")
	await shot("skills_guard")
	await create_timer(0.8).timeout

	# --- prayer
	p.health = 20.0
	await press("slot_4")
	print("4) prayer: hp 20 -> ", p.health, " of ", p.max_health, " (expect +40%)")
	await create_timer(1.2).timeout

	# --- whirlwind with three around George
	p.health = p.max_health
	var ring := spawn_dummies(3, 3.4)
	await press("slot_3")
	await create_timer(0.75).timeout
	var hits := ring.map(func(e): return 500.0 - e.health)
	print("5) whirlwind: damage to the three skeletons ", hits, " (expect ~", snappedf(p.sword_damage * 1.4, 0.1), " each)")
	await shot("skills_whirlwind")
	await create_timer(1.5).timeout

	# --- charge
	var target := spawn_dummies(1, 6.0)
	target[0].global_position = p.global_position + p._facing() * 6.0
	var start := p.global_position
	await press("slot_5")
	await create_timer(0.6).timeout
	print("6) charge: moved ", snappedf(start.distance_to(p.global_position), 0.1), " m, dummy lost ", 500.0 - target[0].health, " hp, stunned: ", target[0]._state == Enemy.State.HURT)

	# --- potions on the bar
	p.collect("potion", 2)
	p.collect("power_potion", 1)
	p.collect("speed_potion", 1)
	p.health = 50.0
	await create_timer(0.8).timeout
	await press("slot_6")
	print("7) health potion (slot 6): hp 50 -> ", p.health, ", potions left ", p.consumables["health"])
	await create_timer(0.8).timeout
	await press("slot_7")
	print("   power potion (slot 7): buff ", snappedf(p.buff_time("power"), 0.1), " s, left ", p.consumables["power"])
	await create_timer(0.8).timeout
	await press("slot_8")
	print("   speed potion (slot 8): buff ", snappedf(p.buff_time("speed"), 0.1), " s, left ", p.consumables["speed"])
	await shot("skills_bar")

	# --- rearranging the bar
	p.assign_slot(0, "item:health", 5)
	print("8) swap slot 1 and 6: ", p.bar)
	p.assign_slot(7, "whirlwind", -1)
	print("   whirlwind dragged from the book onto slot 8: ", p.bar)
	p.clear_slot(7)
	print("   slot 8 cleared: ", p.bar)

	# --- skill book
	await press("skillbook")
	await create_timer(0.4).timeout
	await shot("skills_book")
	quit()
