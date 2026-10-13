extends SceneTree
## Enemy health bars in the new look:  godot --path . --resolution 1920x1080 --script tools/uishot3.gd -- <outdir>
var out := "."


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 9999.0
	var targets := get_nodes_in_group("enemies").filter(func(e): return e.kind_id == "warrior" and e.global_position.length() > 100.0 and e.global_position.x > -100.0)
	var e = targets[0]
	e.take_damage(18.0, e.global_position + Vector3(2, 0, 0))
	p.teleport(e.global_position + Vector3(0, 0.05, 8.0), PI)
	e.set_physics_process(false)
	p._pitch = -0.2
	p._arm.spring_length = 7.0
	await create_timer(7.0).timeout
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/ui3_enemy_bar.png" % out)
	quit()
