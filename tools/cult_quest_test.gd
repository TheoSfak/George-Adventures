extends SceneTree
## The quest "Η Σέκτα του Σκότους" and the rule that the new creatures are not skeletons:
##   godot --path . --headless --script tools/cult_quest_test.gd
## Quest states: 0 LOCKED, 1 AVAILABLE, 2 ACTIVE, 3 READY, 4 DONE
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

	# none of the new creatures counts for a skeleton quest (the first quest: kill 4 skeletons)
	q.state["bell"] = 2
	var before: int = q.progress["bell"][0]
	for kind in ["pumpkin", "haunted_tree", "golem", "bone_heap", "mimic", "cultist", "cult_priest"]:
		q.report_kill(kind)
	check("pumpkins, trees, golems, heaps, mimics and the cult are not skeletons", q.progress["bell"][0] == before)
	q.report_kill("minion")
	check("a skeleton still counts", q.progress["bell"][0] == before + 1)

	# the chain
	q.reset()
	check("the cult quest is locked at the start", q.state["cult"] == 0)
	q.state["bell"] = 4
	q._refresh_availability()
	check("it does not open with the first quest alone", q.state["cult"] == 0)
	q.state["king"] = 4
	q._refresh_availability()
	check("it opens once the Bone King is dead", q.state["cult"] == 1)
	# Παπά-Σταύρος has other quests: leave only this one open so that his offer is this quest
	for id in q.state:
		if id != "cult" and q.state[id] == 1:
			q.state[id] = 4
	var plan: Dictionary = q.dialogue_for("stavros")
	check("Παπά-Σταύρος offers it", plan["kind"] == "offer" and plan["quest"] == "cult" and plan["lines"].size() == 3)
	check("Παπά-Σταύρος has the '!'", q.marker_for("stavros") == "!")
	q.finish_dialogue(plan)
	check("ACTIVE after the offer", q.state["cult"] == 2)
	q.report_kill("minion")
	q.report_kill("bandit_thug")
	check("skeletons and bandits do not count for it", q.progress["cult"][0] == 0 and q.progress["cult"][1] == 0)
	q.report_kill("cult_priest")
	check("the priest counts for his own objective only", q.progress["cult"][0] == 0 and q.progress["cult"][1] == 1)
	for i in 4:
		q.report_kill("cultist")
	check("four cultists: not ready yet", q.progress["cult"][0] == 4 and q.state["cult"] == 2)
	var tracker: Array = q.tracker()
	var line := ""
	for t in tracker:
		if t["title"] == QuestData.QUESTS["cult"]["title"]:
			line = String(t["lines"][0])
	check("the tracker shows the cultists (%s)" % line, line.contains("4/5"))
	q.report_kill("cultist")
	check("five cultists and the priest: READY", q.progress["cult"][0] == 5 and q.state["cult"] == 3)
	check("Παπά-Σταύρος shows '?'", q.marker_for("stavros") == "?")
	var complete: Dictionary = q.dialogue_for("stavros")
	check("he hands it in with his complete lines", complete["kind"] == "complete" and complete["quest"] == "cult")
	var gold: int = p.gold
	var damage: float = p.base_damage
	var potions: int = p.potions
	q.finish_dialogue(complete)
	check("DONE", q.state["cult"] == 4)
	check("250 gold and 2 potions", p.gold == gold + 250 and p.potions == potions + 2)
	check("at least +3 damage (the 500 XP may add level-ups on top)", p.base_damage >= damage + 3.0)
	quit(1 if failed else 0)
