extends SceneTree
## Windows and menus in the new look:  godot --path . --resolution 1920x1080 --script tools/uishot2.gd -- <outdir>
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
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var hud := get_first_node_in_group("hud")
	p.gain_xp(900)
	p.collect("gold", 480)
	p.collect("potion", 4)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.5).timeout
	for tab in ["skills", "talents", "gear"]:
		hud._hero.toggle(tab)
		await create_timer(0.6).timeout
		await shot("ui2_hero_" + tab)
		hud._hero.visible = false
	hud.open_shop("blacksmith", p)
	await create_timer(0.6).timeout
	await shot("ui2_shop")
	hud._shop.visible = false
	# invasion bar and buffs
	hud._on_invasion_updated(true, 2, 3, 7, 62.0)
	p.add_buff("power", 20.0) if p.has_method("add_buff") else null
	await create_timer(0.8).timeout
	await shot("ui2_invasion")
	quit()
