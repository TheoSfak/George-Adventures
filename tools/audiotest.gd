extends SceneTree
## Audio check:  godot --path . --resolution 1280x720 --script tools/audiotest.gd
## Prints which music the manager chooses in each situation and the live bus levels, so the
## audio can be verified without listening. Watch for "SoundManager:" warnings.


func _initialize() -> void:
	_run()


func peak(bus: String) -> String:
	var i := AudioServer.get_bus_index(bus)
	return "%.0f dB" % maxf(AudioServer.get_bus_peak_volume_left_db(i, 0), AudioServer.get_bus_peak_volume_right_db(i, 0))


func report(label: String, sm) -> void:
	await create_timer(5.0).timeout
	print("%-26s music=%-9s | levels: Music %s  SFX %s  Ambient %s" % [label, sm._music_id, peak("Music"), peak("SFX"), peak("Ambient")])


func _run() -> void:
	await process_frame
	var quests := root.get_node("/root/Quests")
	quests.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var sm = get_first_node_in_group("sound_manager")
	var dn := get_first_node_in_group("daynight") as DayNight
	var p := get_first_node_in_group("player") as Player
	var spawner := main.get_node("Enemies")
	print("sound manager: ", sm != null, "  buses: ", AudioServer.get_bus_index("Music") >= 0, AudioServer.get_bus_index("SFX") >= 0, AudioServer.get_bus_index("Ambient") >= 0)
	dn.running = false
	dn.set_time(10.0)
	p.teleport(Vector3(0, 0.05, 20), 0.0)
	await report("village, morning", sm)

	# every sound effect must load and play without a warning
	var count := 0
	for id in SfxIds.VARIANTS:
		if SfxIds.LOOPS.has(id):
			continue
		Sfx.play(id)
		count += 1
		await create_timer(0.05).timeout
	print("played %d different sound effects (any 'unknown'/'missing' warning above is a bug)" % count)

	dn.set_time(22.0)
	await create_timer(1.0).timeout
	dn.set_time(22.0)
	var inv = get_first_node_in_group("invasion")
	await create_timer(0.3).timeout
	inv.active = false                 # the invasion would override everything below
	for e in get_nodes_in_group("invaders"):
		e.dissolve()
	await report("village, night", sm)
	p.teleport(Vector3(-20, 0.05, -125), 0.0)
	await report("near the crypt", sm)
	p.teleport(Vector3(-120, 0.05, 90), 0.0)
	await report("far from the village", sm)
	p.teleport(Vector3(0, 0.05, 20), 0.0)
	dn.set_time(11.0)
	var skeleton: Enemy = spawner.spawn_invader("warrior", Vector3(0, 0, 12), Vector3.ZERO)
	await report("a skeleton attacks", sm)
	skeleton.dissolve()
	var boss: Enemy = spawner.spawn_invader("warlord", Vector3(0, 0, 8), Vector3.ZERO)
	p.max_health = 9999.0
	p.health = 9999.0
	await report("a boss attacks", sm)
	boss.dissolve()
	dn.set_time(20.4)
	await create_timer(0.5).timeout
	inv.active = false
	dn.set_time(5.9)
	await create_timer(0.3).timeout
	dn.set_time(20.6)    # a new night begins: the invasion
	await report("night invasion", sm)
	for e in get_nodes_in_group("invaders"):
		e.dissolve()
	var interiors := get_first_node_in_group("interiors")
	interiors.enter("tavern_1", "tavern", Vector3(-45, 0, -9.8), 1.57, p)
	await report("inside the tavern", sm)
	interiors._exit_room("tavern_1", p)
	await report("outside again", sm)
	quit()
