extends SceneTree
## Close-up of the new props:  godot --path . --resolution 1920x1080 --script tools/propshot.gd -- <outdir>
var out := "."
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	_run()
func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
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
	get_first_node_in_group("hud").visible = false
	q.state["totems"] = 2
	q.state["sacks"] = 2
	q.state["logs"] = 2
	q.changed.emit()
	await create_timer(0.4).timeout
	var n := 0
	for t in get_nodes_in_group("breakables"):
		if n == 0:
			p.teleport(t.global_position + Vector3(0.0, 0.05, -9.0), 0.0)       # the camp is crowded with big tents
		else:
			p.teleport(t.global_position + Vector3(-4.0, 0.05, 9.0), PI + 0.4)
		await create_timer(1.0).timeout
		await shot("prop_totem_%d" % n)
		n += 1
	var sack = get_nodes_in_group("quest_items").filter(func(i): return i.get("item_id") == "sack")[0]
	p.teleport(sack.global_position + Vector3(3.0, 0.05, 5.0), PI - 0.5)
	await create_timer(1.0).timeout
	await shot("prop_sack")
	var lg = get_nodes_in_group("quest_items").filter(func(i): return i.get("item_id") == "log")[0]
	p.teleport(lg.global_position + Vector3(3.0, 0.05, 5.0), PI - 0.5)
	await create_timer(1.0).timeout
	await shot("prop_log")
	quit()
