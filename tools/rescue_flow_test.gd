extends SceneTree
## The whole rescue event: alert, ring of skeletons, drain, success, failure, save/load:
##   godot --path . --headless --script tools/rescue_flow_test.gd
## Event states: 0 WAITING, 1 ALERT, 2 ACTIVE, 3 SAVED, 4 FAILED.  Quest states: 2 ACTIVE, 3 READY, 4 DONE, 5 FAILED.
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _alert_card() -> Node:
	for c in get_first_node_in_group("hud").get_children():
		if c.get_script() != null and c.get_script().get_global_name() == &"RescueAlert":
			return c
	return null


func _besiegers() -> Array:
	return get_nodes_in_group("besiegers").filter(func(e): return not e.is_dead())


func _run() -> void:
	await process_frame
	var q = root.get_node("/root/Quests")
	q.intro_seen = true
	var save = load("res://scripts/save_game.gd")
	var real := "user://savegame.before_rescue_test"
	var real_bak := "user://savegame.bak.before_rescue_test"
	var had_save: bool = FileAccess.file_exists(save.PATH)
	var had_bak: bool = FileAccess.file_exists(save.BACKUP)
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real))
	if had_bak:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.BACKUP), ProjectSettings.globalize_path(real_bak))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	var r = get_first_node_in_group("rescue")
	r.set_process(false)
	check("the rescue node exists and waits", r != null and r.state == 0)
	check("the limit is 180..300 s", r.limit >= 180.0 and r.limit <= 300.0)

	# --- the clock only runs when George is free
	var before: float = r.elapsed
	p.busy = true
	r.step(500.0)
	check("busy George: the clock stands still", r.state == 0 and r.elapsed == before)
	p.busy = false
	r.step(r.limit - r.elapsed - 1.0)
	check("one second before the limit: still waiting", r.state == 0)
	r.step(2.0)
	check("at the limit the alert opens", r.state == 1 and _alert_card() != null)
	check("George is held while the card is open", p.busy)

	# --- accept: the scene appears
	_alert_card()._accept()
	await create_timer(0.5).timeout
	check("ACTIVE after the card", r.state == 2)
	check("the quest started", q.state["andreas"] == 2)
	check("six besiegers", _besiegers().size() == 6)
	check("Andreas stands at the site", r.andreas != null and Vector2(r.andreas.global_position.x - r.SITE.x, r.andreas.global_position.z - r.SITE.y).length() < 2.0)
	check("George is free again", not p.busy)
	check("the map marker finds Andreas", r.andreas_position() != Vector3.ZERO)

	# --- the drain
	r.step(30.0)
	check("30 s with six: health about 0.8", r.health > 0.75 and r.health < 0.85)

	# --- success: kill them all
	for e in _besiegers():
		e.take_damage(9999.0, e.global_position + Vector3.RIGHT)
	await create_timer(0.3).timeout
	r.step(0.1)
	check("all dead: SAVED", r.state == 3)
	check("the quest is READY", q.state["andreas"] == 3)
	var gold: int = p.gold
	q.finish_dialogue(q.dialogue_for("andreas"))
	check("hand-in: DONE and 120 gold", q.state["andreas"] == 4 and p.gold == gold + 120)
	check("Andreas walks to the square", r.andreas.position.is_equal_approx(r.SQUARE_SPOT))

	# --- failure: nobody comes
	q.reset()
	r.reset()
	await create_timer(0.3).timeout
	check("reset gives a clean slate", r.state == 0 and r.elapsed == 0.0 and q.state["andreas"] == 0)
	r.trigger_now()
	_alert_card()._accept()
	await create_timer(0.5).timeout
	check("second run is ACTIVE with six", r.state == 2 and _besiegers().size() == 6)
	for i in 20:
		r.step(10.0)
	check("after 200 s Andreas is dead: FAILED", r.state == 4)
	check("the quest FAILED", q.state["andreas"] == 5)
	await create_timer(21.0).timeout
	check("the ring dissolves and Andreas is gone", _besiegers().is_empty() and r.andreas == null)

	# --- save and load in the middle of a rescue
	q.reset()
	r.reset()
	await create_timer(0.3).timeout
	r.trigger_now()
	_alert_card()._accept()
	await create_timer(0.5).timeout
	r.step(30.0)
	var h: float = r.health
	check("saved", save.save())
	r.reset()
	await create_timer(0.3).timeout
	check("after reset nothing is left", _besiegers().is_empty() and r.state == 0)
	save.apply(save.read())
	await create_timer(0.5).timeout
	check("loaded: ACTIVE again", r.state == 2)
	check("health kept", absf(r.health - h) < 0.01)
	check("six besiegers rebuilt", _besiegers().size() == 6)
	check("the quest is ACTIVE", q.state["andreas"] == 2)

	# --- an old save without the rescue block
	r.load_data({})
	check("a save without a rescue block starts waiting", r.state == 0)

	# --- put the player's real saves back
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
