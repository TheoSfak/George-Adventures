extends SceneTree
## HUD screenshots (bars, panels, dialogue, windows):  godot --path . --resolution 1920x1080 --script tools/uishot.gd -- <outdir>
var out := "."


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
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
	var p := get_first_node_in_group("player") as Player
	var hud := get_first_node_in_group("hud")
	p.gain_xp(150)
	p.collect("gold", 123)
	p.collect("potion", 3)
	q.state["bell"] = 2
	q.state["kegs"] = 2
	q.progress["kegs"][0] = 2
	q.state["archers"] = 3
	q.changed.emit()
	p.take_damage(35.0, p.global_position + Vector3(1, 0, 0))
	p.message.emit("Βρήκες ένα βαρέλι κρασιού")
	p.message.emit("+25 εμπειρία")
	await create_timer(1.2).timeout
	await shot("ui_1_hud")
	# an NPC prompt and dialogue
	var npc = get_nodes_in_group("npcs")[0]
	p.teleport(npc.global_position + Vector3(2.0, 0.05, 0), -PI / 2.0)
	await create_timer(1.0).timeout
	await shot("ui_2_prompt")
	npc.interact(p)
	await create_timer(1.5).timeout
	await shot("ui_3_dialogue")
	quit()
