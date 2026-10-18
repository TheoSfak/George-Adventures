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
		p.global_position = Vector3(95.0, 0.0, 6.0) # Outside the stronghold staging area

	var cam: Camera3D = Camera3D.new()
	cam.fov = 65.0
	main.add_child(cam)
	cam.make_current()

	print("Capturing Orc Stronghold Castle views...")

	# 1. High angle overview of the entire Orc Stronghold at (122, 6)
	_look(cam, Vector3(124.0, 2.0, 6.0), Vector3(98.0, 19.0, 28.0))
	await create_timer(0.8).timeout
	await shot("orc_castle_overview")

	# 2. Eye-level view from the approach path facing the OPEN gate archway
	if p:
		p.global_position = Vector3(101.0, 0.0, 6.0)
		p.rotation_degrees.y = -90.0
	_look(cam, Vector3(110.0, 2.5, 6.0), Vector3(96.0, 2.0, 6.0))
	await create_timer(0.8).timeout
	await shot("orc_castle_gate_approach")

	# 3. George standing right in the open gateway archway entering the courtyard
	if p:
		p.global_position = Vector3(109.0, 0.0, 6.0)
		p.rotation_degrees.y = -90.0
	_look(cam, Vector3(122.0, 2.2, 6.0), Vector3(103.5, 2.2, 6.0))
	await create_timer(0.8).timeout
	await shot("orc_castle_gateway_open")

	# 4. Inside the courtyard: George confronting the Orc Warlord, Berserkers, Totems and Keep
	if p:
		p.global_position = Vector3(118.0, 0.0, 6.0)
		p.rotation_degrees.y = -90.0
	_look(cam, Vector3(128.0, 2.2, 6.0), Vector3(113.0, 2.6, 6.0))
	await create_timer(0.8).timeout
	await shot("orc_castle_courtyard")

	# 5. Clear, unobstructed approach to Ash Valley Gate at (178, 64)
	if p:
		p.global_position = Vector3(150.0, 0.0, 66.0)
		p.rotation_degrees.y = -70.0
	_look(cam, Vector3(178.0, 2.5, 64.0), Vector3(145.0, 3.5, 68.0))
	await create_timer(0.8).timeout
	await shot("ash_valley_portal_clear")

	print("ORC CASTLE SHOTS DONE!")
	quit(0)
