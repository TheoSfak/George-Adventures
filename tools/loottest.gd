extends SceneTree
## XP / loot / potion check:  godot --path . --resolution 1280x720 --script tools/loottest.gd -- <outdir>
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
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
	await create_timer(1.5).timeout
	var p := get_first_node_in_group("player") as Player
	var enemies := get_nodes_in_group("enemies")
	print("start: level ", p.level, " xp ", p.xp, "/", p.xp_needed(), " gold ", p.gold, " potions ", p.potions)

	# kill the first skeleton right next to George
	var e: Enemy = enemies[0]
	for other in enemies:
		if other != e:
			other.queue_free()
	p.global_position = e.global_position + Vector3(3.5, 0.05, 0)
	await create_timer(0.2).timeout
	e.take_damage(999.0, p.global_position)
	await create_timer(0.3).timeout
	print("after kill: xp ", p.xp, " (reward ", e.xp_reward, "), pickups on ground: ", get_nodes_in_group("pickups").size())
	await create_timer(0.35).timeout
	await shot("loot_on_ground")
	await create_timer(2.0).timeout
	print("after pickup: gold ", p.gold, " potions ", p.potions, " pickups left: ", get_nodes_in_group("pickups").size())

	# potion: only works when hurt
	p.collect("potion", 1)
	p.use_potion()
	print("potion at full health ignored: potions ", p.potions, " (expect 1)")
	p.take_damage(30.0, p.global_position + Vector3(2, 0, 0))
	var hp := p.health
	p.use_potion()
	print("potion used: hp ", hp, " -> ", p.health, " potions ", p.potions, " (expect 0)")

	# level up
	var lv := p.level
	var mh := p.max_health
	var dmg := p.sword_damage
	p.gain_xp(p.xp_needed() + 5)
	print("level ", lv, " -> ", p.level, " max hp ", mh, " -> ", p.max_health, " sword ", dmg, " -> ", p.sword_damage, " hp ", p.health, " xp ", p.xp)
	await create_timer(0.3).timeout
	await shot("level_up")

	# skeleton respawn is scheduled
	print("alive enemies now: ", get_nodes_in_group("enemies").size(), " (0 until respawn)")
	quit()
