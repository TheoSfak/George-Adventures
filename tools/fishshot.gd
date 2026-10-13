extends SceneTree
## Screenshots of the dock, the fishing bar, the cook in the tavern and his window, plus an fps check:
##   godot --path . --resolution 1920x1080 --script tools/fishshot.gd -- tools/_shots/fishshot
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func sample(label: String, secs: float) -> void:
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		frames += 1
	print("PERF ", label, ": ", snappedf(frames / secs, 0.1), " fps")


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var hud = get_first_node_in_group("hud")
	var interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	var spot: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_FISH:
			spot = n
	# the dock from the land side
	p.teleport(spot.global_position + Vector3(8.0, 0.05, 4.0), -PI / 2.0 - 0.6)
	await create_timer(1.5).timeout
	await shot("fs_01_dock")
	await sample("dock", 3.0)
	# casting, waiting, the bite
	spot.interact(p)
	await create_timer(0.5).timeout
	await shot("fs_02_cast")
	await create_timer(1.0).timeout
	var fishing = get_first_node_in_group("fishing")
	await shot("fs_03_wait")
	fishing._wait = 0.05
	await create_timer(0.8).timeout
	await shot("fs_04_bite_bar")
	fishing._marker = fishing._zone_center
	fishing.press()
	await create_timer(0.6).timeout
	await shot("fs_05_caught")
	# the cook in the tavern
	p.gold = 200
	p.junk = {"goby": 3, "perch": 2, "trout": 2, "sunfish": 1}
	interiors.enter("tavern_shot", "tavern", Vector3(-59, 0.05, 5), 0.0, p)
	await create_timer(2.0).timeout
	await shot("fs_06_tavern_cook")
	hud.open_shop("kitchen", p)
	await create_timer(0.6).timeout
	await shot("fs_07_kitchen_meals")
	var shop = hud.find_child("ShopWindow", true, false)
	shop._set_tab("cook")
	await create_timer(0.5).timeout
	await shot("fs_08_kitchen_cook")
	shop._eat("fried")
	await create_timer(0.5).timeout
	shop.close()
	await create_timer(0.6).timeout
	await shot("fs_09_food_pill")
	quit()
