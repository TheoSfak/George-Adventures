extends SceneTree
## Story part 3 data checks (no world needed):
##   godot --path . --headless --script tools/part3_data_test.gd
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
	var chain := ["f_gate", "f_guards", "f_symbols", "f_wall", "f_malakar", "f_return"]
	for id in chain:
		check("quest %s exists" % id, QuestData.QUESTS.has(id))
	check("NPC ilarion exists", QuestData.NPCS.has("ilarion"))
	check("NPC elpida exists", QuestData.NPCS.has("elpida"))
	check("item symbol is named", QuestData.ITEMS.has("symbol"))
	if failed:
		quit(1)
		return

	var known_types := ["kill", "collect", "defend", "reach"]
	for id in chain:
		var qd: Dictionary = QuestData.QUESTS[id]
		check("%s: giver and hand-in are NPCs" % id, QuestData.NPCS.has(qd["giver"]) and QuestData.NPCS.has(qd["turn_in"]))
		check("%s: has offer, progress and complete text" % id, qd["offer"].size() > 0 and qd["progress"].size() > 0 and qd["complete"].size() > 0)
		for req in qd["requires"]:
			check("%s: requirement %s exists" % [id, req], QuestData.QUESTS.has(req))
		for o in qd["objectives"]:
			check("%s: objective type %s is known" % [id, o["type"]], o["type"] in known_types)
	check("necro no longer ends the game", not QuestData.QUESTS["necro"].has("ends_game"))
	var enders := []
	for id in QuestData.QUESTS:
		if QuestData.QUESTS[id].get("ends_game", false):
			enders.append(id)
	check("only f_return ends the game (found %s)" % str(enders), enders == ["f_return"])
	check("Strings has the frontier name", Strings.BUILDING_NAMES.has("frontier"))

	# --- availability chain
	q.reset()
	check("f_gate is locked at the start", q.state["f_gate"] == q.S.LOCKED)
	for id in QuestData.QUESTS:
		if not id.begins_with("f_"):
			q.state[id] = q.S.DONE
	q._refresh_availability()
	check("f_gate is available once necro is done", q.state["f_gate"] == q.S.AVAILABLE)
	check("Stavros shows a '!'", q.marker_for("stavros") == "!")
	check("f_guards and f_symbols are still locked", q.state["f_guards"] == q.S.LOCKED and q.state["f_symbols"] == q.S.LOCKED)

	q.state["f_gate"] = q.S.ACTIVE
	q.report_reach("frontier")
	check("arriving in the frontier readies f_gate", q.state["f_gate"] == q.S.READY)
	check("Ilarion shows a '?'", q.marker_for("ilarion") == "?")
	q.state["f_gate"] = q.S.DONE
	q._refresh_availability()
	check("f_guards and f_symbols open after f_gate", q.state["f_guards"] == q.S.AVAILABLE and q.state["f_symbols"] == q.S.AVAILABLE)
	check("f_wall waits for both", q.state["f_wall"] == q.S.LOCKED)
	q.state["f_guards"] = q.S.DONE
	q._refresh_availability()
	check("f_wall still waits for the symbols", q.state["f_wall"] == q.S.LOCKED)
	q.state["f_symbols"] = q.S.DONE
	q._refresh_availability()
	check("f_wall opens", q.state["f_wall"] == q.S.AVAILABLE)
	q.state["f_wall"] = q.S.DONE
	q._refresh_availability()
	check("f_malakar opens", q.state["f_malakar"] == q.S.AVAILABLE)
	q.state["f_malakar"] = q.S.DONE
	q._refresh_availability()
	check("f_return opens", q.state["f_return"] == q.S.AVAILABLE)
	q.state["f_return"] = q.S.ACTIVE
	q.report_reach("village")
	check("returning to the village readies f_return", q.state["f_return"] == q.S.READY)
	q.reset()
	quit(1 if failed else 0)
