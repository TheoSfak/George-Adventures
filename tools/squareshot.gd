extends SceneTree
## Screenshots of the village square from several angles:
##   godot --path . --resolution 1920x1080 --script tools/squareshot.gd -- <outdir> [night]
var out := "."
var night := false


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	night = a.size() > 1 and a[1] == "night"
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var p := get_first_node_in_group("player") as Player
	get_first_node_in_group("hud").visible = false
	var dn := get_first_node_in_group("daynight") as DayNight
	dn.set_time(21.5 if night else 12.0)
	var views := [
		["sq_1_overview", Vector3(0, 0.05, 30), PI, -1.15, 48.0],
		["sq_2_from_south", Vector3(0, 0.05, 20), PI, -0.35, 12.0],
		["sq_3_from_east", Vector3(20, 0.05, 0), PI * 1.5, -0.35, 12.0],
		["sq_4_from_north", Vector3(0, 0.05, -20), 0.0, -0.35, 12.0],
		["sq_5_from_west", Vector3(-20, 0.05, 0), PI * 0.5, -0.35, 12.0],
		["sq_6_close", Vector3(0, 0.05, 11), PI, -0.25, 6.0],
		["sq_7_stalls", Vector3(12, 0.05, 12), PI * 1.25, -0.3, 9.0],
	]
	for v in views:
		p.teleport(v[1], v[2])
		p._pitch = v[3]
		p._arm.spring_length = v[4]
		await create_timer(1.2).timeout
		await shot(v[0] + ("_night" if night else ""))
	quit()
