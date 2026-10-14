extends SceneTree
## The event quest "Σώσε τον Αντρέα" in the quest manager:
##   godot --path . --headless --script tools/rescue_quest_test.gd
## States: 0 LOCKED, 1 AVAILABLE, 2 ACTIVE, 3 READY, 4 DONE, 5 FAILED
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	check("the event quest is not offered by itself", q.state["andreas"] == 0)
	# even when every other quest is done, nobody hands it out
	for id in q.state:
		if id != "andreas":
			q.state[id] = 4
	q._refresh_availability()
	check("still locked after the whole story", q.state["andreas"] == 0)
	q.reset()
	check("no tracker entry yet", q.tracker().filter(func(t): return t["title"] == "Σώσε τον Αντρέα").is_empty())

	q.start_event_quest("andreas")
	check("starting it makes it ACTIVE", q.state["andreas"] == 2)
	var t: Array = q.tracker().filter(func(t): return t["title"] == "Σώσε τον Αντρέα")
	check("the tracker shows it with one objective 0/1", t.size() == 1 and t[0]["objectives"].size() == 1 and t[0]["objectives"][0]["max"] == 1)
	check("Andreas talks 'progress' while active", q.dialogue_for("andreas")["kind"] == "progress")

	q.report_rescue()
	check("report_rescue makes it READY", q.state["andreas"] == 3)
	check("Andreas shows '?' now", q.marker_for("andreas") == "?")
	var gold := p.gold
	var plan: Dictionary = q.dialogue_for("andreas")
	check("hand-in dialogue is 'complete'", plan["kind"] == "complete")
	q.finish_dialogue(plan)
	check("DONE after the hand-in", q.state["andreas"] == 4)
	check("120 gold reward", p.gold == gold + 120)

	q.reset()
	q.start_event_quest("andreas")
	q.fail_event_quest("andreas")
	check("failed quest is FAILED", q.state["andreas"] == 5)
	check("no tracker entry for a failed quest", q.tracker().filter(func(t): return t["title"] == "Σώσε τον Αντρέα").is_empty())
	q.report_rescue()
	check("a failed quest cannot be rescued later", q.state["andreas"] == 5)
	check("it cannot be started again", (func(): q.start_event_quest("andreas"); return q.state["andreas"] == 5).call())
	quit(1 if failed else 0)
