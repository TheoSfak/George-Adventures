extends SceneTree
## Minimap + big map:  godot --path . --resolution 1280x720 --script tools/minimaptest.gd -- <outdir>
var out := "."
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	_run()
func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
func _run() -> void:
	await process_frame
	var quests := root.get_node("/root/Quests")
	quests.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(4.0).timeout
	var p := get_first_node_in_group("player") as Player
	p.teleport(Vector3(0, 0.05, 14), 0.0)
	p.max_health = 5000.0
	p.health = 5000.0
	# bell done, three quests active, the night quest still on offer
	quests.state["bell"] = 4
	for id in ["kegs", "key", "captain"]:
		quests.state[id] = 2
	quests._refresh_availability()
	quests.changed.emit()
	await create_timer(1.0).timeout
	var tex = load("res://scripts/minimap.gd").world_texture
	print("world texture captured: ", tex != null, " size ", tex.get_size() if tex else "-")
	await shot("mini_plaza")
	p.teleport(Vector3(-20, 0.05, -125), 0.0)   # near the stolen keg in the north
	await create_timer(1.0).timeout
	await shot("mini_keg")
	var hud := get_first_node_in_group("hud")
	hud._big_map.visible = true
	await create_timer(0.5).timeout
	await shot("bigmap")
	hud._big_map.visible = false
	quit()
