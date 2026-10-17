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
	else:
		root.get_node("Quests").set("intro_seen", true)

	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout

	var hud: CanvasLayer = main.get_node_or_null("HUD") as CanvasLayer
	if hud:
		hud.visible = false

	var dn: DayNight = get_first_node_in_group("daynight") as DayNight
	if dn:
		dn.running = false
		dn.set_time(12.5)

	var p: Player = get_first_node_in_group("player") as Player
	if p:
		p.max_health = 50000.0
		p.health = 50000.0
		p.global_position = Vector3(128.0, 0.0, 78.0) # Outside the stronghold approach

	var cam: Camera3D = Camera3D.new()
	cam.fov = 65.0
	main.add_child(cam)
	cam.make_current()

	print("Capturing Orc Stronghold Castle views...")

	# 1. High angle overview of the entire Orc Stronghold
	_look(cam, Vector3(148.0, 2.0, 68.0), Vector3(125.0, 18.0, 95.0))
	await create_timer(0.8).timeout
	await shot("orc_castle_overview")

	# 2. Eye-level view from the approach path facing the OPEN gate archway
	if p:
		p.global_position = Vector3(131.0, 0.0, 77.0)
		p.rotation_degrees.y = 55.0
	_look(cam, Vector3(139.0, 2.5, 73.0), Vector3(126.0, 2.0, 81.0))
	await create_timer(0.8).timeout
	await shot("orc_castle_gate_approach")

	# 3. George standing right in the open gateway archway entering the courtyard
	if p:
		p.global_position = Vector3(139.0, 0.0, 73.0)
		p.rotation_degrees.y = 65.0
	_look(cam, Vector3(147.0, 2.0, 69.0), Vector3(134.0, 2.2, 76.0))
	await create_timer(0.8).timeout
	await shot("orc_castle_gateway_open")

	# 4. Inside the courtyard: George confronting the Orc Warlord and Warband
	if p:
		p.global_position = Vector3(145.0, 0.0, 70.0)
		p.rotation_degrees.y = 75.0
	_look(cam, Vector3(150.0, 2.0, 68.0), Vector3(140.0, 2.8, 76.0))
	await create_timer(0.8).timeout
	await shot("orc_castle_courtyard")

	print("ORC CASTLE SHOTS DONE!")
	quit(0)
