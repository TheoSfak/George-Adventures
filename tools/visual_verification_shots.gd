extends SceneTree

var out_dir := "C:/Users/user/.gemini/antigravity-ide/brain/b4e8c09d-d4b5-4402-8be1-5536522d6f1b"

func _init() -> void:
	_run.call_deferred()

func shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var p: String = "%s/%s.png" % [out_dir, shot_name]
	img.save_png(p)
	print("Saved screenshot: %s" % p)

func _look(cam: Camera3D, target: Vector3, from_pos: Vector3) -> void:
	cam.global_position = from_pos
	cam.look_at(target, Vector3.UP)

func _run() -> void:
	await process_frame
	if not root.has_node("Quests"):
		var q: Node = (load("res://scripts/quests.gd") as GDScript).new()
		q.name = "Quests"
		q.set("intro_seen", true)
		root.add_child(q)

	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout

	var hud: CanvasLayer = main.get_node_or_null("HUD") as CanvasLayer
	if hud:
		hud.visible = false

	var dn: DayNight = get_first_node_in_group("daynight") as DayNight
	if dn:
		dn.running = false
		dn.set_time(12.0)

	var p: Player = get_first_node_in_group("player") as Player
	if p:
		p.max_health = 50000.0
		p.health = 50000.0

	var cam: Camera3D = Camera3D.new()
	cam.fov = 68.0
	main.add_child(cam)
	cam.make_current()

	var island: Node3D = get_first_node_in_group("pirate_island") as Node3D
	var island_wildlife: Node = island.get_node_or_null("IslandWildlife") if island else null
	var island_deer: Node3D = null
	var island_wolf: Node3D = null
	if island_wildlife:
		for c: Node in island_wildlife.get_children():
			if c is VillageDeer and island_deer == null:
				island_deer = c as Node3D
			elif c is CharacterBody3D and not (c is VillageDeer) and not (c is VillageCow) and island_wolf == null:
				island_wolf = c as Node3D

	if island_deer:
		var dp := island_deer.global_position
		_look(cam, dp + Vector3(0.0, 1.8, 0.0), dp + Vector3(6.5, 3.0, 6.0))
		await create_timer(1.0).timeout
		await shot("island_deer_huge")

	if island_wolf:
		var wp := island_wolf.global_position
		_look(cam, wp + Vector3(0.0, 1.4, 0.0), wp + Vector3(5.0, 2.5, 5.0))
		await create_timer(1.0).timeout
		await shot("island_wolf_huge")

	print("ALL ISLAND VERIFICATION SHOTS COMPLETED!")
	quit(0)
