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
	root.get_node("/root/Quests").intro_seen = true

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await create_timer(2.0).timeout

	var p: Player = get_first_node_in_group("player") as Player
	var hud = get_first_node_in_group("hud")
	var dn: DayNight = get_first_node_in_group("daynight") as DayNight
	if dn:
		dn.running = false
		dn.set_time(14.0) # Bright daytime lighting

	# Give George resources, unique forged weapon and +5 upgrade
	p.gold = 50000
	p.junk = {
		"iron_scrap": 25,
		"bone_shard": 20,
		"lava_ember": 15,
		"mountain_herb": 15,
		"reed": 12,
		"waterlily": 10,
		"autumn_cone": 8,
	}
	p.gear_upgrades = {"weapon": 5, "armor": 5, "shield": 5}
	ShopData.forge_recipe("forge_orc_cleaver", p)
	ShopData.forge_recipe("forge_wolf_bow", p)
	ShopData.forge_recipe("forge_corsair_mail", p)
	ShopData.forge_recipe("forge_bulwark", p)
	p.equip("weapon_orc_cleaver")
	p.equip("armor_corsair_mail")
	p._recalc()
	p._update_equipment_visuals()

	# Forge is at Vector3(-88.5, 0.0, 24.5)
	var forge_pos := Vector3(-88.5, 0.0, 24.5)
	p.teleport(Vector3(-86.5, 0.05, 23.5), deg_to_rad(-110.0))
	await create_timer(0.4).timeout

	var cam: Camera3D = Camera3D.new()
	cam.fov = 60.0
	main.add_child(cam)
	cam.make_current()

	# 1. Outdoor Forge Overview: George standing beside the anvil, glowing hearth, and quenching basin
	_look(cam, forge_pos + Vector3(0.0, 1.1, 0.0), Vector3(-83.8, 2.2, 27.2))
	await shot("blacksmith_forge_station_outdoor")

	# 2. Weapon Enchantment Close-up: George holding +5 Solar Radiance glowing blade
	p.set_heading(deg_to_rad(65.0), false)
	await create_timer(0.2).timeout
	_look(cam, p.global_position + Vector3(0.0, 1.1, 0.0), p.global_position + Vector3(1.8, 1.4, 1.5))
	await shot("blacksmith_weapon_glow_aura")

	# 3. Forge / Upgrade UI Window open
	if hud:
		hud.visible = true
		hud.open_shop("blacksmith_forge", p, "upgrade")
		await create_timer(0.4).timeout
		await shot("blacksmith_upgrade_window_ui")

		# Switch to Forging tab
		var shop_win = hud.find_child("ShopWindow", true, false)
		if shop_win:
			shop_win._set_tab("forge")
			await create_timer(0.3).timeout
			await shot("blacksmith_forge_recipes_ui")

	print("ALL SCREENSHOTS CAPTURED SUCCESSFULLY")
	quit(0)
