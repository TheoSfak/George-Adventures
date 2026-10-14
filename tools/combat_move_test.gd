extends SceneTree
## George swings fast, keeps moving while he swings, chains five hits, steps with the stab and spins at the end:
##   godot --path . --headless --script tools/combat_move_test.gd
var failed := false
var swings: Array = []


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _speed(p: Player) -> float:
	return Vector2(p.velocity.x, p.velocity.z).length()


func _dummy(spawner, pos: Vector3):
	var e = spawner.spawn_extra("brute", pos)        # 130 health, so it survives a few blows
	e.set_physics_process(false)                      # it stands still and does not hit back
	return e


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	var spawner = get_first_node_in_group("enemy_spawner")
	p.attacked.connect(func(i): swings.append(i))
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await create_timer(0.5).timeout

	# --- standing still: the swing is quick and the body plays the full animation
	p._start_attack()
	await create_timer(0.05).timeout
	check("a standing swing is a full-body animation at 1.7x", not p._swing_layer and p._anim.current_animation == "1H_Melee_Attack_Slice_Diagonal" and absf(p._anim.get_playing_speed() - 1.7) < 0.01)
	await create_timer(0.45).timeout
	check("George may act again after a third of a second (it used to take a second)", not p._attacking)
	await create_timer(1.2).timeout

	# --- five hits chain quickly while the button is mashed
	swings.clear()
	p._combo_index = 0
	var t0 := Time.get_ticks_msec()
	while swings.size() < 5 and Time.get_ticks_msec() - t0 < 4000:
		p._attack_queued = 0.25
		await physics_frame
	var took := (Time.get_ticks_msec() - t0) / 1000.0
	check("mashing the button plays the five hits in order %s" % str(swings), swings == [0, 1, 2, 3, 4])
	check("the whole combo takes under 2.2 s (%.2f s)" % took, took < 2.2)
	await create_timer(1.5).timeout

	# --- the attack speed stat
	p.stats.set_source("test", {"attack_speed": 0.5})
	p._start_attack()
	await create_timer(0.05).timeout
	check("+50% attack speed: swings play at 2.55x", absf(p._anim.get_playing_speed() - 1.7 * 1.5) < 0.01)
	await create_timer(0.6).timeout
	p.stats.set_source("test", {})

	# --- moving: no stop, the legs keep running, the upper-body layer swings
	await create_timer(1.0).timeout
	Input.action_press("move_forward")
	Input.action_press("run")
	await create_timer(0.8).timeout
	var run_speed := _speed(p)
	check("George is running (%.1f m/s)" % run_speed, run_speed > 7.0)
	p._combo_index = 0
	p._start_attack()
	await create_timer(0.1).timeout
	check("he keeps running while the blow lands (%.1f m/s, was %.1f)" % [_speed(p), run_speed], _speed(p) > run_speed * 0.7)
	check("the swing plays on the upper-body layer", p._swing_layer and p._upper.player.is_playing())
	check("while the base animation keeps the legs running", p._anim.current_animation == "Running_A" or p._anim.current_animation == "Walking_A")
	# the poses themselves: the arm is where the swing puts it, the leg is where the run puts it
	var skel := p._model.find_child("Skeleton3D", true, false) as Skeleton3D
	var swing_anim: Animation = p._anim.get_animation(p._upper.player.current_animation)
	var run_anim: Animation = p._anim.get_animation(p._anim.current_animation)
	var arm_track := swing_anim.find_track(NodePath("Rig/Skeleton3D:upperarm.r"), Animation.TYPE_ROTATION_3D)
	var leg_swing_track := swing_anim.find_track(NodePath("Rig/Skeleton3D:upperleg.l"), Animation.TYPE_ROTATION_3D)
	var leg_run_track := run_anim.find_track(NodePath("Rig/Skeleton3D:upperleg.l"), Animation.TYPE_ROTATION_3D)
	var arm_pose: Quaternion = skel.get_bone_pose_rotation(skel.find_bone("upperarm.r"))
	var leg_pose: Quaternion = skel.get_bone_pose_rotation(skel.find_bone("upperleg.l"))
	var arm_want: Quaternion = swing_anim.rotation_track_interpolate(arm_track, p._upper.player.current_animation_position)
	var leg_run_want: Quaternion = run_anim.rotation_track_interpolate(leg_run_track, p._anim.current_animation_position)
	var leg_swing_want: Quaternion = swing_anim.rotation_track_interpolate(leg_swing_track, p._upper.player.current_animation_position)
	var arm_err := arm_pose.angle_to(arm_want)
	var leg_err_run := leg_pose.angle_to(leg_run_want)
	var leg_err_swing := leg_pose.angle_to(leg_swing_want)
	print("   arm vs swing: %.3f rad, leg vs run: %.3f rad, leg vs swing: %.3f rad" % [arm_err, leg_err_run, leg_err_swing])
	check("the right arm is posed by the swing", arm_err < 0.25)
	check("the left leg is posed by the run, not by the swing", leg_err_run < 0.25 and leg_err_run < leg_err_swing)
	await create_timer(0.5).timeout
	check("the layer stops after the swing", not p._swing_layer and not p._upper.player.is_playing())
	Input.action_release("move_forward")
	Input.action_release("run")
	await create_timer(0.8).timeout

	# --- the blow lands early and hurts
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await create_timer(0.4).timeout
	var front := p._facing()
	var target = _dummy(spawner, p.global_position + front * 2.0)
	var h0: float = target.health
	p._combo_index = 0
	p._start_attack()
	await create_timer(0.1).timeout
	check("nothing yet before the blade lands", is_equal_approx(target.health, h0))
	await create_timer(0.2).timeout
	check("the blow has landed after 0.3 s", target.health < h0)
	await create_timer(0.4).timeout

	# --- the stab steps forward
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await create_timer(0.4).timeout
	var start := p.global_position
	p._combo_index = 2
	p._start_attack()
	await create_timer(0.6).timeout
	check("the stab stepped forward about 1.2 m (%.2f m)" % start.distance_to(p.global_position), start.distance_to(p.global_position) > 0.9 and start.distance_to(p.global_position) < 1.7)
	await create_timer(0.5).timeout

	# --- the spinning finisher hits enemies behind him too
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await create_timer(0.4).timeout
	var behind_a = _dummy(spawner, p.global_position - p._facing() * 1.6)
	var behind_b = _dummy(spawner, p.global_position + Vector3(p._facing().z, 0, -p._facing().x) * 1.6)
	var ha: float = behind_a.health
	var hb: float = behind_b.health
	p._combo_index = 4
	p._start_attack()
	await create_timer(0.5).timeout
	check("the finisher hit the one behind him", behind_a.health < ha or behind_a.is_dead())
	check("and the one at his side", behind_b.health < hb or behind_b.is_dead())

	# --- a normal cone blow does not hit what is behind him
	await create_timer(0.8).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await create_timer(0.4).timeout
	var rear = _dummy(spawner, p.global_position - p._facing() * 1.6)
	var hr: float = rear.health
	p._attacking = true                         # call the blow directly: the aim assist of _start_attack would turn him round
	p._swing_hits(p._attack_serial, 10.0, 5.0, false)
	check("a normal blow does not reach behind him", is_equal_approx(rear.health, hr))
	p._swing_hits(p._attack_serial, 10.0, 5.0, true)
	check("a blow that goes all around does", rear.health < hr)
	p._attacking = false
	quit(1 if failed else 0)
