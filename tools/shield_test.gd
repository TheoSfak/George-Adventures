extends SceneTree
## The Saint's shield (skill "guard") blocks every hit completely, and a blocked arrow or orb does not push George back:
##   godot --path . --headless --script tools/shield_test.gd
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
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 0.0
	p.health = p.max_health
	var front: Vector3 = p.global_position + p._facing() * 5.0
	var behind: Vector3 = p.global_position - p._facing() * 5.0

	# --- the guard skill: no damage, no stagger, no push, from any side, melee or ranged
	p._guard_time = 5.0
	for ranged in [false, true]:
		for src in [front, behind]:
			p.velocity = Vector3.ZERO
			p.take_damage(40.0, src, ranged)
			check("guard: no damage (ranged %s)" % ranged, p.health == p.max_health)
			check("guard: no push (ranged %s)" % ranged, Vector2(p.velocity.x, p.velocity.z).length() < 0.01)
			check("guard: no stagger (ranged %s)" % ranged, p._stun == 0.0)
			p._guard_hit_cd = 0.0
	p._guard_time = 0.0

	# --- no guard, no block: a normal hit hurts and pushes (melee and ranged)
	p._blocking = false
	p.velocity = Vector3.ZERO
	p.take_damage(10.0, front, true)
	check("a free arrow hurts", p.health < p.max_health)
	check("a free arrow pushes George back", Vector2(p.velocity.x, p.velocity.z).length() > 3.0)
	p._invulnerable = 0.0
	p.health = p.max_health

	# --- blocking (K / Ctrl): a blocked melee blow still moves him a little, a blocked arrow or orb does not
	p._blocking = true
	p.velocity = Vector3.ZERO
	p.take_damage(20.0, front, false)
	var melee_push := Vector2(p.velocity.x, p.velocity.z).length()
	check("a blocked blow takes only a part of the damage", p.health > p.max_health - 20.0 * 0.3 and p.health < p.max_health)
	check("a blocked blow still pushes a little", melee_push > 1.0 and melee_push < 4.0)
	p._invulnerable = 0.0
	p.health = p.max_health
	p._blocking = true
	p.velocity = Vector3.ZERO
	p.take_damage(20.0, front, true)
	check("a blocked arrow hurts only a little", p.health > p.max_health - 20.0 * 0.3 and p.health < p.max_health)
	check("a blocked arrow does not push George back", Vector2(p.velocity.x, p.velocity.z).length() < 0.01)
	p._invulnerable = 0.0
	p._blocking = false

	# --- a real arrow flies at him while the shield is up, and one while he blocks
	var proj = load("res://scripts/projectile.gd")
	p.health = p.max_health
	p._guard_time = 5.0
	var at: Vector3 = p.global_position + Vector3(0, 1.0, 0)
	var shot = proj.make("arrow", at + p._facing() * 6.0, -p._facing(), 17.0, 25.0)
	main.add_child(shot)
	await create_timer(0.8).timeout
	check("a real arrow against the shield does nothing", p.health == p.max_health and Vector2(p.velocity.x, p.velocity.z).length() < 0.5)
	p._guard_time = 0.0
	p.health = p.max_health
	p._invulnerable = 0.0
	quit(1 if failed else 0)
