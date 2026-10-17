extends SceneTree

var out_dirs: Array[String] = [
	"C:/Users/user/.gemini/antigravity-ide/brain/b4e8c09d-d4b5-4402-8be1-5536522d6f1b",
	"tools/_shots"
]

func _init() -> void:
	_run.call_deferred()

func shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	for d: String in out_dirs:
		DirAccess.make_dir_recursive_absolute(d)
		var p: String = "%s/%s.png" % [d, shot_name]
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

	for e: Node in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.2).timeout

	# Hide HUD for clean cinematic game shots
	var hud: CanvasLayer = main.get_node_or_null("HUD") as CanvasLayer
	if hud:
		hud.visible = false

	var dn: DayNight = get_first_node_in_group("daynight") as DayNight
	if dn:
		dn.running = false
		dn.set_time(12.8) # Bright midday Mediterranean sunlight

	var p: Player = get_first_node_in_group("player") as Player
	if p:
		p.max_health = 50000.0
		p.health = 50000.0

	var cam: Camera3D = Camera3D.new()
	cam.fov = 68.0
	main.add_child(cam)
	cam.make_current()

	var island: Node3D = get_first_node_in_group("pirate_island") as Node3D

	print("Capturing refined Pirate Island screenshots...")

	# 1. Panoramic nature view of the island with grand trees, lake, and volcano
	_look(cam, Vector3(-35.0, 14.0, 520.0), Vector3(80.0, 52.0, 415.0))
	await create_timer(0.8).timeout
	await shot("island_nature_panoramic")

	# 2. Forest groves view: Standing on the green trail looking through towering giant trees
	# Looking across the forest glade towards the mountain slope
	var grove_target := Vector3(-60.0, 8.5, 470.0)
	var grove_cam_pos := Vector3(-45.0, 6.2, 435.0)
	if p:
		p.global_position = Vector3(-55.0, 6.8, 455.0)
		p.rotation_degrees.y = 200.0
	_look(cam, grove_target, grove_cam_pos)
	await create_timer(0.8).timeout
	await shot("island_forest_huge_trees")

	# 3. Majestic wildlife: 2.2x scale wild deer on Pirate Island lake shore
	var island_wildlife: Node = island.get_node_or_null("IslandWildlife") if island else null
	var island_deer: Node3D = null
	var island_cow: Node3D = null
	if island_wildlife:
		for c: Node in island_wildlife.get_children():
			if c is VillageDeer and island_deer == null:
				island_deer = c as Node3D
			elif c is VillageCow and island_cow == null:
				island_cow = c as Node3D

	if island_deer:
		var dp := island_deer.global_position
		# Position camera to frame the giant deer in the lush landscape
		_look(cam, dp + Vector3(0.0, 1.6, 0.0), dp + Vector3(5.5, 2.5, 5.0))
		await create_timer(0.8).timeout
		await shot("island_wildlife_huge")

	# 4. Highland Pasture Cattle: 1.55x scale cow grazing on the island
	if island_cow:
		var cp := island_cow.global_position
		_look(cam, cp + Vector3(0.0, 1.4, 0.0), cp + Vector3(5.5, 2.2, 5.2))
		await create_timer(0.8).timeout
		await shot("island_wildlife_cattle")

	# 5. Buried Pirate Chest with mound, iron shovel, and skull marker
	var buried_holder: Node = island.get_node_or_null("BuriedChests") if island else null
	var buried_spot: Node3D = null
	if buried_holder and buried_holder.get_child_count() > 0:
		buried_spot = buried_holder.get_child(0) as Node3D

	if buried_spot:
		var bp := buried_spot.global_position
		_look(cam, bp + Vector3(-0.4, 0.4, 0.0), bp + Vector3(2.6, 1.7, 2.4))
		await create_timer(0.8).timeout
		await shot("island_buried_chest")

		# 6. Pirate Cove Landing Pier looking inland at the island entrance and towering forest
		_look(cam, Vector3(-20.0, 6.0, 440.0), Vector3(-20.0, 1.8, 385.0))
		await create_timer(0.8).timeout
		await shot("island_cove_pier_entrance")

	print("ALL PERFECT PIRATE ISLAND SCREENSHOTS CAPTURED!")
	quit(0)
