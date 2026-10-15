extends SceneTree
## The dodge roll (V) and the shield bash (attack while blocking):
##   godot --path . --headless --script tools/dodge_bash_test.gd
var failed := false
var p: Player
var swings := 0


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func wait(t: float) -> void:
	await create_timer(t).timeout


func _dummy(spawner, pos: Vector3):
	var e = spawner.spawn_extra("brute", pos)
	e.set_physics_process(false)             # it stands still: its timers do not run either
	return e


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	# the pure rules first
	check("a roll covers 4.2 m with the push speed (%.1f m/s)" % CombatExtras.dodge_speed(30.0), absf(CombatExtras.dodge_speed(30.0) * CombatExtras.DODGE_MOVE_TIME + pow(CombatExtras.dodge_speed(30.0), 2.0) / 60.0 - CombatExtras.DODGE_DISTANCE) < 0.01)
	check("forward, backward, left and right pick their animation", CombatExtras.dodge_anim(Vector2(0, 1)) == "Dodge_Forward" and CombatExtras.dodge_anim(Vector2(0, -1)) == "Dodge_Backward"
			and CombatExtras.dodge_anim(Vector2(1, 0)) == "Dodge_Right" and CombatExtras.dodge_anim(Vector2(-1, 0.2)) == "Dodge_Left")
	check("a diagonal picks the stronger direction", CombatExtras.dodge_anim(Vector2(0.5, 0.8)) == "Dodge_Forward" and CombatExtras.dodge_anim(Vector2(0.8, 0.5)) == "Dodge_Right")
	check("bosses are stunned for less", CombatExtras.bash_stun(true) < CombatExtras.bash_stun(false))
	check("the bash is shorter than its cooldown and lands before it ends", CombatExtras.BASH_HIT < CombatExtras.BASH_COMMIT and CombatExtras.BASH_COOLDOWN > 1.0)

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await wait(3.0)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	p = get_first_node_in_group("player") as Player
	p._invulnerable = 0.0
	p.max_health = 500.0
	p.health = 500.0
	var spawner = get_first_node_in_group("enemy_spawner")
	p.attacked.connect(func(_i): swings += 1)
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await wait(0.5)
	check("the action exists and is bound to V", InputMap.has_action("dodge") and InputMap.action_get_events("dodge").any(func(ev): return ev is InputEventKey and ev.physical_keycode == KEY_V))
	check("it can be rebound in the settings", load("res://scripts/game_settings.gd").REBINDABLE.any(func(r): return r[0] == "dodge"))

	# --- a roll to the right (strafe), measured against his facing
	var facing: Vector3 = p._facing()
	var right := Vector3(-cos(p._heading), 0.0, sin(p._heading))
	var start := p.global_position
	Input.action_press("strafe_right")
	p._start_dodge()
	Input.action_release("strafe_right")
	await wait(0.05)
	check("the roll to the right plays Dodge_Right", p._anim.current_animation == "Dodge_Right" and p._dodging)
	check("he is invulnerable at once", p._invulnerable > 0.25)
	var h0 := p.health
	p.take_damage(80.0, p.global_position + Vector3(2, 0, 0))
	check("a blow during the roll does nothing", p.health == h0)
	await wait(0.6)
	var moved := p.global_position - start
	check("he rolled about 4 m to the right (%.2f m)" % moved.dot(right), moved.dot(right) > 3.2 and moved.dot(right) < 5.2)
	check("and hardly forward or back (%.2f m)" % moved.dot(facing), absf(moved.dot(facing)) < 1.0)
	check("the roll is over: he can be hurt again", not p._dodging and p._invulnerable <= 0.0)
	p.take_damage(30.0, p.global_position + Vector3(2, 0, 0))
	check("and a blow hurts again", p.health < h0)
	p._invulnerable = 0.0

	# --- the cooldown
	p.health = p.max_health
	check("he cannot roll again at once (cooldown %.1f s)" % p._dodge_cd, p._dodge_cd > 0.3)
	var before_try := p._dodge_serial
	Input.action_press("dodge")
	await wait(0.1)
	Input.action_release("dodge")
	check("pressing V during the cooldown does nothing", p._dodge_serial == before_try)
	await wait(1.4)

	# --- nothing pressed: a hop backwards; the key itself works
	start = p.global_position
	facing = p._facing()
	Input.action_press("dodge")
	await wait(0.08)
	Input.action_release("dodge")
	check("the key V rolls", p._dodging or p._dodge_serial > before_try)
	check("with no direction it is a hop backwards (Dodge_Backward)", p._anim.current_animation == "Dodge_Backward")
	await wait(0.6)
	check("he moved backwards about 4 m (%.2f m)" % (-(p.global_position - start).dot(facing)), -(p.global_position - start).dot(facing) > 3.2)
	await wait(1.4)

	# --- a roll cancels a swing
	p._combo_index = 0
	p._start_attack()
	await wait(0.03)
	check("he is swinging", p._attacking)
	Input.action_press("move_forward")
	p._start_dodge()
	Input.action_release("move_forward")
	check("the roll cancels the swing and goes forward (Dodge_Forward)", not p._attacking and p._anim.current_animation == "Dodge_Forward")
	await wait(0.6)
	await wait(1.4)

	# --- not on a horse, not while a dialogue is open
	p.horse_owned = true
	p.mounted = true
	var serial0 := p._dodge_serial
	Input.action_press("dodge")
	await wait(0.1)
	Input.action_release("dodge")
	check("he cannot roll on the horse", p._dodge_serial == serial0)
	p.mounted = false
	p.busy = true
	Input.action_press("dodge")
	await wait(0.1)
	Input.action_release("dodge")
	p.busy = false
	check("or while a dialogue is open", p._dodge_serial == serial0)
	await wait(0.3)

	# --- the shield bash
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await wait(0.5)
	var target = _dummy(spawner, p.global_position + p._facing() * 1.8)
	var th: float = target.health
	swings = 0
	Input.action_press("block")
	await wait(0.15)
	check("he is blocking", p._blocking)
	p._attack_queued = 0.25
	await wait(0.06)
	check("attacking while blocking starts the bash (Block_Attack), not a sword swing", p._attacking and p._anim.current_animation == "Block_Attack" and swings == 0)
	await wait(0.3)
	check("the shield hurt the enemy a little", target.health < th and target.health > th - p.sword_damage)
	check("and stunned it (%.1f s)" % target._hurt_timer, target._hurt_timer >= 1.0)
	check("and threw it back", target.velocity.length() > 4.0)
	await wait(0.4)
	check("he blocks again afterwards while the key is held", p._blocking and not p._attacking)
	check("the bash cooldown is running", p._bash_cd > 1.0)

	# --- during the cooldown the attack while blocking does nothing (no sword swing either)
	var h1: float = target.health
	p._attack_queued = 0.25
	await wait(0.5)
	check("a second bash right away does not happen, and no sword swing either", not p._attacking and swings == 0 and target.health == h1)
	await wait(2.2)
	p._attack_queued = 0.25
	await wait(0.4)
	check("after the cooldown it works again", target.health < h1)
	Input.action_release("block")

	# --- bosses are stunned for less
	await wait(1.0)
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await wait(0.5)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await wait(0.3)
	var boss = spawner.spawn_extra("captain", p.global_position + p._facing() * 1.8)
	boss.set_physics_process(false)
	p._bash_cd = 0.0
	Input.action_press("block")
	await wait(0.15)
	p._attack_queued = 0.25
	await wait(0.4)
	check("a named boss is only stunned for a moment (%.1f s)" % boss._hurt_timer, boss._hurt_timer > 0.3 and boss._hurt_timer < 0.8)
	Input.action_release("block")

	# --- the controls page lists both
	var strings = load("res://scripts/strings_el.gd")
	var keys: Array = strings.CONTROLS_HELP.map(func(r): return r[0])
	check("the controls page lists V for the roll", "V" in keys)
	quit(1 if failed else 0)
