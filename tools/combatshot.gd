extends SceneTree
## The five hits of the combo and a swing while running (legs run, arms swing), screenshots from the side:
##   godot --path . --resolution 1920x1080 --script tools/combatshot.gd -- <outdir>
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var dn := get_first_node_in_group("daynight") as DayNight
	dn.running = false
	dn.set_time(12.0)
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	var spawner = get_first_node_in_group("enemy_spawner")
	var cam := Camera3D.new()
	cam.fov = 38.0
	p.add_child(cam)
	cam.position = Vector3(7.5, 1.7, 0.0)
	cam.look_at(p.global_position + Vector3(0, 1.0, 0), Vector3.UP)
	cam.make_current()
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await create_timer(0.6).timeout

	# the five hits, standing, one picture shortly after the blade lands
	var dummy = spawner.spawn_extra("brute", p.global_position + p._facing() * 2.2)
	dummy.set_physics_process(false)
	for i in 5:
		p._combo_index = i
		p._start_attack()
		var step: Dictionary = CombatTiming.COMBO[i]
		await create_timer(CombatTiming.hit_delay(step, CombatTiming.BASE_SPEED) + 0.03).timeout
		await shot("combo_%d_%s" % [i + 1, String(step["anim"]).replace("_Melee_Attack", "")])
		await create_timer(0.8).timeout
		cam.look_at(p.global_position + Vector3(0, 1.0, 0), Vector3.UP)
	dummy.queue_free()

	# running: the same swing with only the arms swinging
	p.teleport(Vector3(0, 0.05, 40), 0.0)
	await create_timer(0.5).timeout
	Input.action_press("move_forward")
	Input.action_press("run")
	await create_timer(0.9).timeout
	await shot("run_before_swing")
	p._combo_index = 0
	p._start_attack()
	await create_timer(0.06).timeout
	await shot("run_swing_a")
	await create_timer(0.07).timeout
	await shot("run_swing_b")
	await create_timer(0.07).timeout
	await shot("run_swing_c")
	print("layer used: ", p._swing_layer, "  speed: ", Vector2(p.velocity.x, p.velocity.z).length(), "  fps: ", Engine.get_frames_per_second())
	Input.action_release("move_forward")
	Input.action_release("run")
	quit()
