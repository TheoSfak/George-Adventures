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

func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout

	var p: Player = get_first_node_in_group("player") as Player
	var hud = get_first_node_in_group("hud")
	var jmgr = get_first_node_in_group("journal_manager")
	var dn: DayNight = get_first_node_in_group("daynight") as DayNight
	if dn:
		dn.running = false
		dn.set_time(14.5) # Bright clear afternoon lighting

	# Give player progress and stats for rich display
	p.level = 18
	p.gold = 3500
	p.gear_upgrades = {"weapon": 4, "armor": 3, "shield": 2}

	# Report some kills and stats to journal manager
	if jmgr:
		jmgr.report_kill("warrior")
		jmgr.report_kill("warrior")
		jmgr.report_kill("warrior")
		jmgr.report_kill("orc_warrior")
		jmgr.report_kill("orc_berserker")
		jmgr.report_kill("orc_warlord")
		jmgr.report_kill("bandit_thug")
		jmgr.report_kill("bandit_chief")
		jmgr.report_kill("pirate_corsair")
		jmgr.report_kill("wolf")
		jmgr.report_stat("chests_opened", 8)
		jmgr.report_stat("fish_caught", 4)
		jmgr.report_stat("herbs_harvested", 7)
		jmgr.report_stat("arena_victories", 3)
		jmgr.report_stat("arena_bronze", 1)
		jmgr.report_stat("arena_silver", 1)
		jmgr.report_stat("parkour_completed", 1)
		jmgr.report_stat("sailed_boat", 1)
		jmgr.check_achievements()

	# 1. Capture Achievements Tab
	if hud and hud.has_method("open_journal"):
		hud.open_journal("achievements")
		await create_timer(0.6).timeout
		await shot("journal_achievements_window")

		# 2. Capture Bestiary Tab with 3D turntable
		hud.open_journal("bestiary")
		await create_timer(0.3).timeout
		var jwin = hud.find_child("JournalWindow", true, false)
		if jwin and jwin.has_method("_display_bestiary_entry"):
			jwin._selected_bestiary_kind = "orc_warlord"
			jwin._render_bestiary_list()
			jwin._display_bestiary_entry("orc_warlord")
		await create_timer(0.6).timeout
		await shot("journal_bestiary_3d_turntable")

		# Close window
		if jwin and jwin.has_method("close"):
			jwin.close()
		await create_timer(0.4).timeout

	# 3. Capture Achievement Toast Banner
	if hud and hud.has_method("show_achievement_toast"):
		var ach_demo = {
			"id": "orc_slayer",
			"title": "Εξολοθρευτής των Ορκ",
			"desc": "Εξόντωσε 20 πολεμιστές και berserkers των Ορκ.",
			"icon": "🪓",
			"reward": {"gold": 350, "xp": 600, "title": "Τρομοκράτης των Ορκ"}
		}
		hud.show_achievement_toast(ach_demo)
		await create_timer(0.5).timeout
		await shot("journal_achievement_unlock_toast")

	print("Screenshot session complete!")
	quit(0)
