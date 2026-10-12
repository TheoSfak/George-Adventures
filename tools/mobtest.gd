extends SceneTree
## New mobs (archer, mage, brute) and invaders:  godot --path . --resolution 1280x720 --script tools/mobtest.gd -- <outdir>
var out := "."
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	_run()
func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	var p := get_first_node_in_group("player") as Player
	var spawner := main.get_node("Enemies")
	p.teleport(Vector3(0, 0.05, 28), PI)
	p.max_health = 2000.0
	p.health = 2000.0
	# archer
	var archer: Enemy = spawner.spawn_invader("rogue", Vector3(0, 0, 14), Vector3.ZERO)
	await create_timer(3.5).timeout
	var arrows := 0
	for c in spawner.get_children():
		if c is Projectile: arrows += 1
	print("archer: dist ", snappedf(archer.global_position.distance_to(p.global_position), 0.1), " George hp ", p.health, " arrows in flight ", arrows)
	await shot("mob_archer")
	await create_timer(4.0).timeout
	print("archer after 7.5 s: George lost ", 2000.0 - p.health, " hp (arrows hit)")
	archer.dissolve()
	p.health = 2000.0
	# mage
	p.teleport(Vector3(0, 0.05, 28), PI)
	var mage: Enemy = spawner.spawn_invader("mage", Vector3(0, 0, 12), Vector3.ZERO)
	for i in 6:
		await create_timer(0.75).timeout
		print("  mage t=", snappedf((i + 1) * 0.75, 0.01), " pos ", mage.global_position, " state ", mage._state, " dist ", snappedf(mage.global_position.distance_to(p.global_position), 0.1), " cd ", snappedf(mage._cooldown, 0.1))
	print("mage: dist ", snappedf(mage.global_position.distance_to(p.global_position), 0.1), " George lost ", 2000.0 - p.health, " hp")
	await shot("mob_mage")
	mage.dissolve()
	await create_timer(1.0).timeout
	# brute in melee
	p.teleport(Vector3(0, 0.05, 28), PI)
	p.health = 2000.0
	var brute: Enemy = spawner.spawn_invader("brute", Vector3(0, 0, 14), Vector3.ZERO)
	await create_timer(5.0).timeout
	print("brute: dist ", snappedf(brute.global_position.distance_to(p.global_position), 0.1), " George lost ", 2000.0 - p.health, " hp")
	await shot("mob_brute")
	# an invader marches to the well when George is far away
	brute.dissolve()
	p.teleport(Vector3(150, 0.05, 150), 0.0)
	var inv: Enemy = spawner.spawn_invader("minion", Vector3(0, 0, -100), Vector3.ZERO)
	var d0 := inv.global_position.distance_to(Vector3.ZERO)
	await create_timer(12.0).timeout
	print("invader marched from ", snappedf(d0, 0.1), " m to ", snappedf(inv.global_position.distance_to(Vector3.ZERO), 0.1), " m from the well in 12 s")
	quit()
