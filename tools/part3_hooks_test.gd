extends SceneTree
## Everything that must behave differently inside the Frontier:
##   godot --path . --headless --script tools/part3_hooks_test.gd
var failed := false
var p: Player
var q: Node
var interiors


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func wait_region(on: bool) -> void:
	for i in 150:
		await create_timer(0.1).timeout
		if interiors.in_region() == on and not p.busy:
			return


func _run() -> void:
	await process_frame
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var save = load("res://scripts/save_game.gd")
	var fr = load("res://scripts/frontier.gd")
	# keep the player's real save safe: this test writes savegame.json
	var real_backup := "user://savegame.before_hooks_test"
	var real_bak_backup := "user://savegame.bak.before_hooks_test"
	if FileAccess.file_exists(save.PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(save.BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.BACKUP), ProjectSettings.globalize_path(real_bak_backup))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	interiors = get_first_node_in_group("interiors")
	var hud = get_first_node_in_group("hud")
	var sound = get_first_node_in_group("sound_manager")
	var invasion = get_first_node_in_group("invasion")
	p._invulnerable = 99999.0
	check("the corner minimap is visible in the village", hud._mini_frame.visible)
	check("village music is not 'mountain'", sound._pick_music() != "mountain")

	q.state["f_gate"] = q.S.ACTIVE
	interiors.enter_region("frontier", fr.VILLAGE_GATE + Vector3(0, 0.05, 5), 0.0, p)
	await wait_region(true)
	check("in the region", interiors.in_region())
	for e in get_nodes_in_group("enemies"):
		e.queue_free()                             # no fight music in this test
	await create_timer(0.5).timeout
	check("the corner minimap is hidden in the region", not hud._mini_frame.visible)
	check("the music is 'mountain'", sound._pick_music() == "mountain")
	hud.toggle_big_map()
	check("the big map does not open in the region", not hud._big_map.visible)

	# --- a night invasion is skipped while George is away
	invasion.start(1)
	check("the invasion is skipped while away", not invasion.active)

	# --- saving inside the region and loading it back
	save.delete()
	check("saved", save.save())
	var data: Dictionary = save.read()
	check("the save knows George is in the frontier", bool(data["player"].get("in_frontier", false)))
	var saved_pos: Vector3 = p.global_position
	var near := Vector3(float(data["player"]["position"][0]), float(data["player"]["position"][1]), float(data["player"]["position"][2]))
	check("...and stores the real position", near.distance_to(saved_pos) < 0.5)
	interiors.exit_region(p)
	await wait_region(false)
	check("back in the village", not interiors.in_region())
	check("the village minimap returns", hud._mini_frame.visible)
	save.apply(data)
	await wait_region(true)
	check("loading the save puts George back in the Frontier", interiors.in_region() and p.global_position.distance_to(saved_pos) < 1.5)

	# --- a save made in the village says so
	interiors.exit_region(p)
	await wait_region(false)
	save.save()
	data = save.read()
	check("a village save has in_frontier false", not bool(data["player"].get("in_frontier", true)))

	# --- dying in the Frontier wakes George in the village
	interiors.enter_region("frontier", fr.VILLAGE_GATE + Vector3(0, 0.05, 5), 0.0, p)
	await wait_region(true)
	p.respawn_time = 0.3
	p._die()
	await create_timer(1.0).timeout
	check("George respawned outside the region", not interiors.in_region() and p.global_position.length() < 60.0)

	# restore the real save
	save.delete()
	if FileAccess.file_exists(real_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_backup), ProjectSettings.globalize_path(save.PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(real_bak_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_bak_backup), ProjectSettings.globalize_path(save.BACKUP))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_bak_backup))
	quit(1 if failed else 0)
