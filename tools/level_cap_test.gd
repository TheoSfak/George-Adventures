extends SceneTree
## Levels 20 to 40: xp, stats, talent points, the new gear, potions, the defense cap:
##   godot --path . --headless --script tools/level_cap_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	check("the cap is 40", p.max_level == 40)
	check("George starts at level 1", p.level == 1)
	var hp0 := p.base_max_health
	var dmg0 := p.base_damage

	# a level-up past 20 and the full climb
	p.gain_xp(LevelScaling.xp_total(1, 20))
	check("XP of levels 1 to 19 gets him to level 20", p.level == 20)
	check("level 20 is no longer the end: the bar still has a goal", p.xp_needed() == 705)
	p.gain_xp(LevelScaling.xp_needed(20))
	check("level 21 comes with the next 705 XP", p.level == 21)
	p.gain_xp(LevelScaling.xp_total(21, 40) + 5)
	check("the rest of the climb gets him to level 40", p.level == 40)
	check("at the cap the XP bar is empty", p.xp == 0)
	check("health +10 per level: 490", is_equal_approx(p.base_max_health, hp0 + 390.0))
	check("damage +2 per level: +78", is_equal_approx(p.base_damage, dmg0 + 78.0))
	p.gain_xp(100000)
	check("no level 41", p.level == 40 and p.xp == 0)
	check("39 talent points to spend (one per level from level 2)", p.talent_points_free() == 39)

	# the new gear
	var sd = load("res://scripts/shop_data.gd")
	var shops: Dictionary = sd.SHOPS
	var stock_ids: Array = shops["blacksmith"]["stock"].map(func(e): return e["id"])
	for slot in ["weapon", "armor", "shield"]:
		var prev_price: int = 0
		for t in range(5, 10):
			var id: String = "%s_%d" % [slot, t]
			var g: Dictionary = sd.GEAR[id]
			check("%s exists: tier %d, level %d, %d gold" % [id, g["tier"], g["level"], g["price"]], g["tier"] == t and g["level"] == 20 + (t - 5) * 5 and g["price"] > prev_price)
			check("%s is on sale at the blacksmith" % id, id in stock_ids)
			prev_price = g["price"]
	check("the weapons get better with every tier", sd.GEAR["weapon_9"]["mods"]["damage_add"] > sd.GEAR["weapon_5"]["mods"]["damage_add"] and sd.GEAR["weapon_5"]["mods"]["damage_add"] > sd.GEAR["weapon_4"]["mods"]["damage_add"])
	check("nine tier colours", sd.TIER_COLORS.size() == 9)
	for id in sd.GEAR:
		check("%s has a Greek name and a description" % id, String(sd.GEAR[id]["name"]).length() > 3 and String(sd.GEAR[id]["desc"]).length() > 5)

	# wearing the best set at level 40: the stats, the defense cap and the model
	p.gear_owned.assign(["weapon_9", "armor_9", "shield_9"])
	p.equipped = {"weapon": "weapon_9", "armor": "armor_9", "shield": "shield_9"}
	for id in p.talents.keys():
		p.talents.erase(id)
	for id in TalentData.NODES:
		if TalentData.NODES[id].has("mods") and TalentData.NODES[id]["mods"].has("defense"):
			p.talents[id] = TalentData.NODES[id]["max"]
	p._recalc()
	check("armor, shield and talents together never pass the 80% defense cap", p.stats.total("defense") <= 0.8 + 0.0001)
	check("the best weapon adds its 100 damage to the 93 of level 40", p.sword_damage >= 93.0 + 100.0 - 0.01)
	p._update_equipment_visuals()
	check("the tier-9 gear can be drawn (no crash, shield and sword visible)", p._gear_tier("shield") == 9 and p._gear_tier("weapon") == 9)

	# healing potions stay useful
	p.health = 1.0
	p.consumables["health"] = 3
	p.consumables["health_big"] = 3
	p._potion_cooldown = 0.0
	p.use_consumable("health")
	check("a health potion heals at least 25% of max health", p.health >= 1.0 + p.max_health * 0.25 - 0.5)
	p.health = 1.0
	p._potion_cooldown = 0.0
	p.use_consumable("health_big")
	check("a big potion heals at least 50%", p.health >= 1.0 + p.max_health * 0.5 - 0.5)
	p.level = 1
	p._recalc()
	p.health = 1.0
	p._potion_cooldown = 0.0
	var before := p.health
	p.use_consumable("health")
	check("at the start a potion still heals a flat amount (never less than 40)", p.health - before >= 39.0)
	quit(1 if failed else 0)
