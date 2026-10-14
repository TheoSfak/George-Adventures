extends SceneTree
## Save/load round trip:  godot --path . --resolution 1280x720 --script tools/savetest.gd
## (SaveGame/GameSettings are used untyped-safe: they mention the Quests autoload.)
func _initialize() -> void:
	_run()
func world() -> Node:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	return main
func _run() -> void:
	await process_frame
	var quests := root.get_node("/root/Quests")
	quests.intro_seen = true
	var save = load("res://scripts/save_game.gd")
	# keep the player's real save safe: the test deletes and rewrites savegame.json
	var real_backup := "user://savegame.before_test"
	if FileAccess.file_exists(save.PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real_backup))
	save.delete()
	var main := world()
	await create_timer(2.5).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	# --- build up some progress
	p.gain_xp(300)
	p.collect("gold", 250)
	p.collect("potion", 3)
	p.gear_owned.append("sword_iron") if ShopData.GEAR.has("sword_iron") else null
	p.talents = {"guard_1": 1} if TalentData.NODES.has("guard_1") else {}
	p.teleport(Vector3(-30, 0.05, 40), 1.0)
	quests.state["bell"] = 4
	quests.state["kegs"] = 2
	quests.progress["kegs"][0] = 2
	dn.time_of_day = 21.5
	dn.day_number = 3
	dn.night_number = 2
	for chest in get_nodes_in_group("chests"):
		save.note_chest(chest.global_position)
		break
	print("before: level ", p.level, " xp ", p.xp, " gold ", p.gold, " potions ", p.potions, " pos ", p.global_position, " day ", dn.day_number)
	print("saved: ", save.save(), "  file: ", ProjectSettings.globalize_path(save.PATH))
	print("summary: ", save.summary())
	# --- a brand new world, then load
	main.queue_free()
	await create_timer(0.5).timeout
	save.reset_progress()
	quests.reset()
	quests.intro_seen = true
	main = world()
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	dn = get_first_node_in_group("daynight") as DayNight
	print("fresh:  level ", p.level, " gold ", p.gold, " bell ", quests.state["bell"], " bosses alive: ", get_nodes_in_group("enemies").filter(func(e): return e.kind_id == "captain").size())
	save.apply(save.read())
	await create_timer(0.5).timeout
	print("loaded: level ", p.level, " xp ", p.xp, " gold ", p.gold, " potions ", p.potions, " pos ", p.global_position, " day ", dn.day_number, " time ", dn.time_of_day)
	print("quests: bell=", quests.state["bell"], " kegs=", quests.state["kegs"], " progress ", quests.progress["kegs"], " (2=active 4=done)")
	print("captain alive after load: ", get_nodes_in_group("enemies").filter(func(e): return e.kind_id == "captain" and not e.is_queued_for_deletion()).size(), " (1 expected: bosses respawn, so a loaded game has them again)")
	var opened := 0
	for chest in get_nodes_in_group("chests"):
		if chest.opened: opened += 1
	print("opened chests after load: ", opened, " (1 expected)")
	save.delete()
	if FileAccess.file_exists(real_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_backup), ProjectSettings.globalize_path(save.PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_backup))
	quit()
