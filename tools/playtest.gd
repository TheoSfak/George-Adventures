extends SceneTree
## Windowed playtest driver:  godot --path . --script tools/playtest.gd -- <outdir>
var out := "."

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	_run()

func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])

func press(action: String) -> void:
	var ev := InputEventAction.new(); ev.action = action; ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.08).timeout
	ev = InputEventAction.new(); ev.action = action; ev.pressed = false
	Input.parse_input_event(ev)

func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	var player := get_first_node_in_group("player") as Player
	var enemies := get_nodes_in_group("enemies")
	print("enemies: ", enemies.size(), " player hp ", player.health)
	await shot("01_start")
	# stand near the first warrior, facing it
	var e: Enemy = enemies[0]
	player.global_position = e.global_position + Vector3(6, 0.05, -4)
	await create_timer(0.3).timeout
	await shot("02_near")
	await create_timer(1.8).timeout
	print("dist to enemy: ", player.global_position.distance_to(e.global_position), " state ", e._state)
	await shot("03_chase")
	# fight: face enemy by setting camera yaw, then attack repeatedly
	for i in 14:
		var to := e.global_position - player.global_position
		player._yaw = atan2(-to.x, -to.z)
		await press("attack")
		await create_timer(0.45).timeout
		if i == 3: await shot("04_fight")
		print(i, " enemy hp ", e.health if is_instance_valid(e) else "gone", " player hp ", player.health)
		if not is_instance_valid(e) or e._state == Enemy.State.DEAD: break
	await shot("05_after")
	await create_timer(1.0).timeout
	await shot("06_dead")
	# let the others kill George
	player.global_position = enemies[2].global_position + Vector3(4, 0.05, 0)
	await create_timer(7.0).timeout
	print("player hp ", player.health, " dead ", player.is_dead)
	await shot("07_player_hurt")
	await create_timer(5.0).timeout
	print("after respawn hp ", player.health, " dead ", player.is_dead)
	quit()
