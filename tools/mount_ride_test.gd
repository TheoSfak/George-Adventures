extends SceneTree
## Riding: the key, the speed, every dismount trigger and every block:
##   godot --path . --headless --script tools/mount_ride_test.gd
var failed := false
var messages: Array[String] = []


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _flat_speed(p: Player) -> float:
	return Vector2(p.velocity.x, p.velocity.z).length()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	var p := get_first_node_in_group("player") as Player
	p.max_health = 50000.0
	p.health = 50000.0
	p.message.connect(func(t): messages.append(t))
	p.teleport(Vector3(0, 0.05, 12), PI)
	await create_timer(0.5).timeout

	check("the mount key is registered (G)", InputMap.has_action("mount"))
	check("George has no horse at the start", not p.horse_owned and not p.mounted)
	check("without a horse he cannot mount", not p.mount() and not p.mounted)
	check("with the 'no horse' message", messages.has(String(Strings.MOUNT_BLOCKED["not_owned"])))

	# --- speed: walking on foot, then walking mounted
	p.horse_owned = true
	Input.action_press("move_forward")
	await create_timer(0.7).timeout
	var foot := _flat_speed(p)
	Input.action_release("move_forward")
	await create_timer(0.6).timeout
	p.teleport(Vector3(0, 0.05, 12), PI)
	await create_timer(0.3).timeout
	check("he mounts", p.mount() and p.mounted)
	check("with the message and the horse showing", messages.has(Strings.MOUNT_ON) and p.get("_horse").visible)
	Input.action_press("move_forward")
	await create_timer(0.7).timeout          # measured early: at 9 m/s the well is only 12 m away
	var riding := _flat_speed(p)
	Input.action_release("move_forward")
	check("walking on foot is about 5 m/s (%.1f)" % foot, foot > 4.0 and foot < 6.0)
	check("riding is 1.8 times faster (%.1f)" % riding, absf(riding / foot - MountRules.SPEED_FACTOR) < 0.15)
	await create_timer(0.6).timeout

	# --- the key
	p.teleport(Vector3(0, 0.05, 12), PI)
	Input.action_press("mount")
	await _frames(3)
	Input.action_release("mount")
	await _frames(3)
	check("pressing G dismounts", not p.mounted and messages.has(Strings.MOUNT_OFF))
	check("George is back on the ground", absf(p.get("_model").position.y) < 0.001)
	Input.action_press("mount")
	await _frames(3)
	Input.action_release("mount")
	await _frames(3)
	check("pressing G mounts again", p.mounted)

	# --- a hit dismounts
	await create_timer(0.8).timeout
	p.take_damage(1.0, Vector3(5, 0, 5))
	check("a hit throws him off", not p.mounted)
	await create_timer(1.0).timeout

	# --- an attack only dismounts
	p.mount()
	Input.action_press("attack")
	await _frames(3)
	Input.action_release("attack")
	check("the attack key dismounts", not p.mounted)
	check("and does not swing the sword", not p.get("_attacking"))
	await create_timer(0.6).timeout

	# --- a skill only dismounts
	var skill: String = p.bar[0]
	p.mount()
	Input.action_press("slot_1")
	await _frames(3)
	Input.action_release("slot_1")
	check("a skill key dismounts", not p.mounted)
	check("and does not use the skill", p.cooldown_left(skill) == 0.0)
	await create_timer(0.6).timeout

	# --- a potion slot does not
	p.mount()
	Input.action_press("slot_6")
	await _frames(3)
	Input.action_release("slot_6")
	check("a potion slot leaves him in the saddle", p.mounted)

	# --- busy (dialogue, shop, fishing, doors) dismounts
	p.busy = true
	await _frames(3)
	check("being busy (a dialogue, a door) dismounts him", not p.mounted)
	p.busy = true
	check("and while busy he cannot mount", p.mount_block_reason() == "busy" and not p.mount())
	p.busy = false
	await create_timer(0.5).timeout

	# --- a chasing skeleton blocks mounting
	var spawner = get_first_node_in_group("enemy_spawner")
	var skeleton = spawner.spawn_extra("warrior", p.global_position + Vector3(7, 0, 0))
	await create_timer(1.5).timeout
	check("a skeleton chases him", skeleton.get("_state") == Enemy.State.CHASE or skeleton.get("_state") == Enemy.State.ATTACK)
	messages.clear()
	check("he cannot mount with a skeleton on his heels", not p.mount())
	check("with the 'chased' message", messages.has(String(Strings.MOUNT_BLOCKED["chased"])))
	skeleton.take_damage(99999.0, p.global_position)
	await create_timer(1.0).timeout
	check("after it is dead he can mount again", p.mount())

	p.dismount(false)
	quit(1 if failed else 0)
