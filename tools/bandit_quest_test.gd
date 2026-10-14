extends SceneTree
## The quest "Οι Ληστές του Δάσους" and the rule that bandits are not skeletons:
##   godot --path . --headless --script tools/bandit_quest_test.gd
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
	var qd = load("res://scripts/quest_data.gd")

	check("is_skeleton: a skeleton yes, a totem and bandits no", qd.is_skeleton("warrior") and qd.is_skeleton("king") and not qd.is_skeleton("totem")
			and not qd.is_skeleton("bandit_thug") and not qd.is_skeleton("bandit_chief"))
	check("is_bandit: the thugs yes, the chief and skeletons no", qd.is_bandit("bandit_archer") and qd.is_bandit("bandit_thief") and not qd.is_bandit("bandit_chief") and not qd.is_bandit("minion"))

	# bandits do not count for a skeleton quest (the first quest: kill 4 skeletons)
	q.state["bell"] = 2
	var before: int = q.progress["bell"][0]
	q.report_kill("bandit_thug")
	q.report_kill("bandit_chief")
	check("bandits do not count as skeletons", q.progress["bell"][0] == before)
	q.report_kill("warrior")
	check("a skeleton still counts", q.progress["bell"][0] == before + 1)

	# the quest chain
	q.reset()
	check("the bandit quest is locked at the start", q.state["bandits"] == 0)
	q.state["bell"] = 4
	q.state["sacks"] = 4
	q._refresh_availability()
	check("it opens once the sacks quest is done", q.state["bandits"] == 1)
	check("Στέλιος has the '!'", q.marker_for("stelios") == "!")
	var plan: Dictionary = q.dialogue_for("stelios")
	check("he offers it", plan["kind"] == "offer" and plan["quest"] == "bandits")
	q.finish_dialogue(plan)
	check("ACTIVE after the offer", q.state["bandits"] == 2)
	q.report_kill("warrior")
	check("skeletons do not count for the bandit quest", q.progress["bandits"][0] == 0 and q.progress["bandits"][1] == 0)
	q.report_kill("bandit_chief")
	check("the chief counts for his own objective only", q.progress["bandits"][0] == 0 and q.progress["bandits"][1] == 1)
	for kind in ["bandit_thug", "bandit_archer", "bandit_thief", "bandit_thug", "bandit_archer"]:
		q.report_kill(kind)
	check("five bandits: not ready yet", q.progress["bandits"][0] == 5 and q.state["bandits"] == 2)
	q.report_kill("bandit_thief")
	check("six bandits and the chief: READY", q.progress["bandits"][0] == 6 and q.state["bandits"] == 3)
	check("Στέλιος shows '?'", q.marker_for("stelios") == "?")
	var gold: int = p.gold
	var damage: float = p.base_damage
	q.finish_dialogue(q.dialogue_for("stelios"))
	check("DONE", q.state["bandits"] == 4)
	check("220 gold", p.gold == gold + 220)
	check("at least +3 damage (the 450 XP may add level-ups on top)", p.base_damage >= damage + 3.0)
	quit(1 if failed else 0)
