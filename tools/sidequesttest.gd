extends SceneTree
## New quests, NPCs and totems:  godot --path . --resolution 1920x1080 --script tools/sidequesttest.gd -- <outdir>
var out := "."
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	_run()
func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
func states(q) -> String:
	var s := []
	for id in ["sacks", "logs", "archers", "mages", "brutes", "totems"]:
		s.append("%s=%d" % [id, q.state[id]])
	return " ".join(s)
func _run() -> void:
	await process_frame
	var q := root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var p := get_first_node_in_group("player") as Player
	p.max_health = 9999.0
	p.health = 9999.0
	q.state["bell"] = 4
	q._refresh_availability()
	q.changed.emit()
	print("after the bell quest: ", states(q), "  (1 = available)")
	var npc_names := []
	for n in get_nodes_in_group("npcs"):
		npc_names.append(n.get("npc_id"))
	print("npcs in the world: ", npc_names)
	var vis := get_nodes_in_group("breakables").filter(func(t): return t.visible).size()
	print("totems visible before the quest: ", vis, " of ", get_nodes_in_group("breakables").size())
	# --- totems
	q.state["totems"] = 2
	q.changed.emit()
	await create_timer(0.3).timeout
	print("totems visible with the quest active: ", get_nodes_in_group("breakables").filter(func(t): return t.visible).size())
	var totems := get_nodes_in_group("breakables")
	p.teleport(totems[0].global_position + Vector3(3.0, 0.05, 0.0), -PI / 2.0)   # face the totem
	await create_timer(0.8).timeout
	await shot("totem")
	for t in totems:
		p.teleport(t.global_position + Vector3(2.4, 0.05, 0.0), -PI / 2.0)
		await create_timer(0.3).timeout
		var swings := 0
		while is_instance_valid(t) and not t._dying and swings < 20:
			p._attacking = true
			p._attack_serial += 1
			p._swing_hits(p._attack_serial, p.sword_damage, 5.0)
			p._attacking = false
			swings += 1
			await create_timer(0.05).timeout
		print("  totem destroyed after ", swings, " swings")
	await create_timer(1.0).timeout
	print("totems quest -> ", q.state["totems"], " (3 = ready)  progress ", q.progress["totems"])
	# --- sacks
	q.state["sacks"] = 2
	q.changed.emit()
	await create_timer(0.3).timeout
	var items := get_nodes_in_group("quest_items").filter(func(i): return i.visible and i.get("item_id") == "sack")
	print("sacks visible: ", items.size())
	p.teleport(items[0].global_position + Vector3(0, 0.05, 6.0), PI)
	await create_timer(1.0).timeout
	await shot("sack")
	for it in items:
		if is_instance_valid(it):
			p.teleport(it.global_position + Vector3(0, 0.05, 0.5), 0.0)
			await create_timer(0.4).timeout
	print("sacks quest -> ", q.state["sacks"], " (3 = ready)  progress ", q.progress["sacks"])
	# --- logs
	q.state["logs"] = 2
	q.changed.emit()
	await create_timer(0.3).timeout
	var logs := get_nodes_in_group("quest_items").filter(func(i): return i.visible and i.get("item_id") == "log")
	p.teleport(logs[0].global_position + Vector3(0, 0.05, 6.0), PI)
	await create_timer(1.0).timeout
	await shot("log")
	for it in logs:
		if is_instance_valid(it):
			p.teleport(it.global_position + Vector3(0, 0.05, 0.5), 0.0)
			await create_timer(0.4).timeout
	print("logs quest -> ", q.state["logs"], " (3 = ready)  progress ", q.progress["logs"])
	# --- kill chains
	q.state["archers"] = 2
	for i in 5: q.report_kill("rogue")
	print("archers -> ", q.state["archers"], " ready; hand in:")
	q._complete("archers")
	print("mages available after archers: ", q.state["mages"], " (1 = available)")
	q.state["mages"] = 2
	for i in 4: q.report_kill("mage")
	q._complete("mages")
	q.state["brutes"] = 2
	for i in 3: q.report_kill("brute")
	var dmg0 := p.base_damage
	q._complete("brutes")
	print("brutes done: damage ", dmg0, " -> ", p.base_damage, "  power potions ", p.consumables["power"], " speed potions ", p.consumables["speed"])
	# --- Vasilis in the world
	for n in get_nodes_in_group("npcs"):
		if n.get("npc_id") == "vasilis":
			p.teleport(n.global_position + Vector3(0, 0.05, 8.0), PI)
	await create_timer(1.2).timeout
	await shot("vasilis")
	quit()
