extends SceneTree
## The save game remembers the chests inside the houses, which village spawns are defeated and how hurt the living are,
## and a night invasion in progress:
##   godot --path . --headless --script tools/save_gaps_test.gd      (takes about a minute)
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func wait(t: float) -> void:
	await create_timer(t).timeout


func world() -> Node:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await wait(3.0)
	return main


func room_chest(interiors, door_id: String):
	var origin: Vector3 = interiors._rooms[door_id]["origin"]
	for c in get_nodes_in_group("chests"):
		if c.global_position.distance_to(origin) < 40.0:
			return c
	return null


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var save = load("res://scripts/save_game.gd")
	# keep the player's real saves safe
	var real := "user://savegame.before_gaps_test"
	var real_bak := "user://savegame.bak.before_gaps_test"
	var had_save: bool = FileAccess.file_exists(save.PATH)
	var had_bak: bool = FileAccess.file_exists(save.BACKUP)
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real))
	if had_bak:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.BACKUP), ProjectSettings.globalize_path(real_bak))
	save.reset_progress()

	# ---------------------------------------------------------------- 1. the rooms stand where their door says
	var main = await world()
	var interiors = get_first_node_in_group("interiors")
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	interiors._build_room("home_5", "home", Vector3(0, 0.05, 0), 0.0)       # opened in the "wrong" order on purpose
	interiors._build_room("home_3", "home", Vector3(0, 0.05, 0), 0.0)
	check("home_3 stands at x = 2000 + 3 * 90 whatever was opened first", interiors._rooms["home_3"]["origin"].is_equal_approx(Vector3(2270, 0, 2000)))
	check("home_5 stands at x = 2000 + 5 * 90", interiors._rooms["home_5"]["origin"].is_equal_approx(Vector3(2450, 0, 2000)))
	var chest = room_chest(interiors, "home_3")
	check("the house has a chest", chest != null)
	chest.mark_opened()
	save.note_chest(chest.global_position)
	var chest_key: String = save.key_for(chest.global_position)

	# ---------------------------------------------------------------- 2. skeletons: one defeated, one hurt
	var spawner = get_first_node_in_group("enemy_spawner")
	var defeated_index := -1
	var hurt_index := -1
	for i in spawner.SPAWNS.size():
		var kind: String = spawner.SPAWNS[i][0]
		if defeated_index < 0 and kind == "minion" and spawner._spawned.has(i):
			defeated_index = i
		elif hurt_index < 0 and kind == "warrior" and spawner._spawned.has(i):
			hurt_index = i
	var gone = spawner._spawned[defeated_index]
	gone.take_damage(9999.0, gone.global_position + Vector3.RIGHT)
	await wait(0.3)
	var damaged = spawner._spawned[hurt_index]
	damaged.take_damage(20.0, damaged.global_position + Vector3.RIGHT)
	var share: float = damaged.health / damaged.max_health
	var sd: Dictionary = spawner.save_data()
	check("the defeated spawn is in the save with its respawn time (%s)" % str(sd["dead"]), sd["dead"].has(str(defeated_index)) and float(sd["dead"][str(defeated_index)]) > 30.0)
	check("the hurt one is in the save with its health share (%.2f)" % share, sd["hurt"].has(str(hurt_index)) and absf(float(sd["hurt"][str(hurt_index)]) - share) < 0.02)
	check("an unhurt one is not in the save", sd["hurt"].size() == 1)

	# ---------------------------------------------------------------- 3. a night invasion in progress
	var dn := get_first_node_in_group("daynight") as DayNight
	var inv = get_first_node_in_group("invasion")
	check("no invasion by day", not inv.active)
	dn.set_time(21.0)
	await wait(6.5)
	check("the night invasion is running (wave %d)" % inv.wave, inv.active and inv.wave >= 1)
	var saved_wave: int = inv.wave
	inv.safety = 63.0
	check("a running invasion is in the save", inv.save_data()["active"] and inv.save_data()["wave"] == saved_wave)
	check("the save is written", save.save())

	# ---------------------------------------------------------------- the same game in a brand new world
	main.queue_free()
	await wait(0.5)
	for n in get_nodes_in_group("invaders"):
		n.queue_free()
	save.reset_progress()
	main = await world()
	interiors = get_first_node_in_group("interiors")
	spawner = get_first_node_in_group("enemy_spawner")
	inv = get_first_node_in_group("invasion")
	check("fresh world: the defeated spawn stands again", spawner._spawned.has(defeated_index) and is_instance_valid(spawner._spawned[defeated_index]))
	check("fresh world: no invasion", not inv.active)
	var data: Dictionary = save.read()
	save.apply(data)
	await wait(0.6)
	check("loaded: the defeated spawn is gone and will return in about %d s" % int(float(spawner._due.get(defeated_index, 0.0)) - spawner._clock), not spawner._spawned.has(defeated_index) and spawner._due.has(defeated_index) and float(spawner._due[defeated_index]) - spawner._clock > 30.0)
	var again = spawner._spawned[hurt_index]
	check("loaded: the hurt one is hurt (%.2f of %.2f)" % [again.health / again.max_health, share], absf(again.health / again.max_health - share) < 0.03)
	# the room and its chest, built after the load
	interiors._build_room("home_3", "home", Vector3(0, 0.05, 0), 0.0)
	var chest2 = room_chest(interiors, "home_3")
	check("loaded: the same chest of the same house is still opened (%s)" % chest_key, chest2 != null and save.key_for(chest2.global_position) == chest_key and chest2.opened)
	interiors._build_room("home_4", "home", Vector3(0, 0.05, 0), 0.0)
	var other = room_chest(interiors, "home_4")
	check("while the chest of another house is not", other != null and not other.opened)
	# the invasion comes back
	await wait(5.5)
	check("loaded: the invasion is running again at wave %d (saved %d)" % [inv.wave, saved_wave], inv.active and inv.wave == saved_wave)
	check("with the saved safety (%.0f)" % inv.safety, inv.safety <= 63.0 and inv.safety > 40.0)
	check("invaders march again", get_nodes_in_group("invaders").size() > 0)
	check("and the guards stand at the well", get_nodes_in_group("guards").size() >= 2)
	# a defeated spawn comes back when its time is up and George is away
	spawner._due[defeated_index] = spawner._clock + 0.2
	p = get_first_node_in_group("player") as Player
	p.teleport(Vector3(0, 0.05, 16), 0.0)
	await wait(1.0)
	check("when its time is up the defeated spawn is back", spawner._spawned.has(defeated_index) and not spawner._due.has(defeated_index))

	# ---------------------------------------------------------------- 4. older saves and saves without the new blocks
	save.load_progress({"world": {"opened_chests": ["2090,2000", "10,10", "-6000,5990", "6000,6000"]}})
	check("an old save loses only the keys of the old, unstable rooms", save.opened_chests == ["10,10", "-6000,5990", "6000,6000"])
	save.load_progress({"world": {"stable_rooms": true, "opened_chests": ["2090,2000", "10,10"]}})
	check("a new save keeps its room keys", save.opened_chests.size() == 2)
	spawner.load_data({})
	check("a save without an enemies block leaves the village alone", true)

	# ---------------------------------------------------------------- put the player's real saves back
	save.reset_progress()
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real), ProjectSettings.globalize_path(save.PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real))
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save.PATH))
	if had_bak:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_bak), ProjectSettings.globalize_path(save.BACKUP))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_bak))
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save.BACKUP))
	quit(1 if failed else 0)
