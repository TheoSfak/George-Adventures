extends SceneTree
## Shops, equipment and junk:  godot --path . --resolution 1280x720 --script tools/shoptest.gd -- <outdir>
var out := "."
var p: Player


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.1).timeout
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	p = get_first_node_in_group("player") as Player
	var hud := get_first_node_in_group("hud")
	p.teleport(Vector3(0, 0.05, 22), PI)
	await create_timer(0.4).timeout

	# --- stat layer with nothing equipped: unchanged numbers
	print("1) base: damage ", p.sword_damage, " (expect 15), max hp ", p.max_health, " (expect 100), defense ", p.stats.total("defense"))

	# --- junk loot and selling
	p.collect("junk_bone", 3)
	p.collect("junk_rust", 1)
	p.collect("junk_charm", 1)
	print("2) junk: ", p.junk)
	p.gold = 500
	p.inventory_changed.emit(p.gold, p.potions)

	# --- open the market
	hud.open_shop("market", p)
	await create_timer(0.4).timeout
	print("3) market open, player busy ", p.busy, " (expect true)")
	await shot("shop_market_buy")
	var shop: ShopWindow = hud.find_child("ShopWindow", true, false)
	shop._buy({"type": "item", "id": "health", "price": 25})
	print("   bought a health potion: gold ", p.gold, " (expect 475), potions ", p.consumables["health"], " (expect 1)")
	shop._buy({"type": "item", "id": "health_big", "price": 70, "level": 8})
	print("   big potion needs level 8: it should still be buyable by code (button disabled in UI) -> gold ", p.gold)
	shop._set_tab("sell")
	await create_timer(0.2).timeout
	await shot("shop_market_sell")
	shop._sell_junk("bone", 3)
	shop._sell_junk("charm", 1)
	print("   sold 3 bones + a charm: gold ", p.gold, " (expect 475 - 70 + 9 + 25 = 439), junk ", p.junk)
	shop.close()
	await create_timer(0.5).timeout
	print("   closed, busy ", p.busy, " (expect false)")

	# --- blacksmith: buy gear, stats and visuals
	p.gold = 5000
	p.gain_xp(100000)   # level 20
	print("4) level ", p.level, ", talent points ", p.talent_points_free(), " (expect 19)")
	hud.open_shop("blacksmith", p)
	await create_timer(0.4).timeout
	await shot("shop_blacksmith_buy")
	shop._buy({"type": "gear", "id": "weapon_2"})
	print("   steel sword: damage ", p.sword_damage, " (expect base+9 = ", p.base_damage + 9.0, ")")
	shop._buy({"type": "gear", "id": "armor_3"})
	shop._buy({"type": "gear", "id": "shield_3"})
	print("   armor+shield: max hp ", p.max_health, " (expect ", p.base_max_health + 140.0, "), defense ", p.stats.total("defense"), " (expect 0.22)")
	var hp_before := p.health
	p.take_damage(100.0, p.global_position + Vector3(2, 0, 0))
	print("   100 damage with defense: took ", hp_before - p.health, " (expect 78)")
	shop._buy({"type": "gear", "id": "weapon_4"})
	shop._buy({"type": "gear", "id": "armor_4"})
	shop._buy({"type": "gear", "id": "shield_4"})
	print("   equipped: ", p.equipped)
	await create_timer(0.3).timeout
	shop._set_tab("sell")
	await create_timer(0.2).timeout
	await shot("shop_blacksmith_sell")
	var gold_before := p.gold
	shop._sell_gear("weapon_2")
	print("   sold the steel sword for ", p.gold - gold_before, " (expect 88)")
	shop.close()
	await create_timer(0.5).timeout

	# --- the equipment window and George with the royal set
	await press("equipment")
	await create_timer(0.3).timeout
	await shot("shop_equipment_window")
	await press("equipment")
	p.get_node("CameraRig/SpringArm3D").spring_length = 4.2
	p._yaw += PI * 0.8   # look at George from the front-side
	await create_timer(0.6).timeout
	await shot("shop_george_royal")
	quit()
