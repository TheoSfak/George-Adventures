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
		dn.set_time(12.5)

	var interiors := get_first_node_in_group("interiors") as Interiors
	var p: Player = get_first_node_in_group("player") as Player
	if p:
		p.max_health = 50000.0
		p.health = 50000.0

	var cam: Camera3D = Camera3D.new()
	cam.fov = 68.0
	main.add_child(cam)
	cam.make_current()

	print("Capturing Castle Interiors & Entrances...")

	# 1. Inside Guard Castle / Watchtower (tower)
	p.busy = false
	interiors.enter("tower_12", "tower", Vector3(95.1, 0.0, -78.7), 0.0, p)
	await create_timer(1.2).timeout
	var tower_room := interiors.get_node("Room_tower_12")
	var tower_origin: Vector3 = interiors._rooms["tower_12"]["origin"]
	if p:
		p.global_position = tower_origin + Vector3(0.0, 0.05, 3.0)
		p.rotation_degrees.y = 180.0
	_look(cam, tower_origin + Vector3(0.0, 2.2, -4.0), tower_origin + Vector3(0.0, 3.2, 7.5))
	await create_timer(0.8).timeout
	await shot("castle_interior_guard_tower")

	# 2. Inside Ruined Orc Stronghold Castle Keep (orc_castle)
	p.busy = false
	interiors._exit_room("tower_12", p)
	await create_timer(1.2).timeout
	p.busy = false
	interiors.enter("orc_castle_0", "orc_castle", Vector3(130.5, 0.05, 6.0), 0.0, p)
	await create_timer(1.2).timeout
	var orc_room := interiors.get_node("Room_orc_castle_0")
	var orc_origin: Vector3 = interiors._rooms["orc_castle_0"]["origin"]
	if p:
		p.global_position = orc_origin + Vector3(0.0, 0.05, 4.0)
		p.rotation_degrees.y = 180.0
	_look(cam, orc_origin + Vector3(0.0, 2.4, -4.5), orc_origin + Vector3(0.0, 3.8, 8.5))
	await create_timer(0.8).timeout
	await shot("castle_interior_orc_stronghold")

	# 3. Inside Fortress of Shadow Keep (shadow_castle)
	p.busy = false
	interiors._exit_room("orc_castle_0", p)
	await create_timer(1.2).timeout
	p.busy = false
	interiors.enter("shadow_castle_0", "shadow_castle", Vector3(0.0, 0.0, -160.0), 0.0, p)
	await create_timer(1.2).timeout
	var shadow_room := interiors.get_node("Room_shadow_castle_0")
	var shadow_origin: Vector3 = interiors._rooms["shadow_castle_0"]["origin"]
	if p:
		p.global_position = shadow_origin + Vector3(0.0, 0.05, 4.5)
		p.rotation_degrees.y = 180.0
	_look(cam, shadow_origin + Vector3(0.0, 2.8, -5.0), shadow_origin + Vector3(0.0, 4.2, 9.8))
	await create_timer(0.8).timeout
	await shot("castle_interior_shadow_realm")

	# 4. Outside at the Orc Castle Entrance in the Stronghold
	p.busy = false
	interiors._exit_room("shadow_castle_0", p)
	await create_timer(1.2).timeout
	if p:
		p.global_position = Vector3(144.5, 0.0, 68.0)
		p.rotation_degrees.y = 45.0
	_look(cam, Vector3(150.0, 2.2, 68.0), Vector3(140.0, 2.5, 74.0))
	await create_timer(0.8).timeout
	await shot("castle_entrance_orc_keep")

	print("CASTLE INTERIOR SHOTS DONE!")
	quit(0)
