extends SceneTree
## A whole boss night:  godot --path . --headless --script tools/invasion_boss_flow_test.gd
var failed := false
var banners := []


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _kill_all(p: Player) -> void:
	for e in get_nodes_in_group("invaders"):
		e.take_damage(99999.0, p.global_position)


func _night_lord():
	for e in get_nodes_in_group("invaders"):
		if e.kind_id == "night_lord":
			return e
	return null


## Kills every invader round by round until the invasion reaches `target_wave` (or ends).
## Returns true if the Night Lord showed up along the way.
func _play_to_wave(inv, p: Player, target_wave: int) -> bool:
	var saw_boss := false
	var guard := 0
	while inv.active and inv.wave < target_wave and guard < 24:
		if _night_lord() != null:
			saw_boss = true
		_kill_all(p)
		await create_timer(0.8).timeout
		guard += 1
	return saw_boss


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	var inv = get_first_node_in_group("invasion")
	dn.running = false
	p.max_health = 50000.0
	p.health = 50000.0
	p.teleport(Vector3(0, 0.05, 12), 0.0)
	inv.banner.connect(func(t, _s): banners.append(t))

	# ---- night 1: an ordinary night, three waves, no boss
	dn.set_time(20.6)
	await create_timer(5.0).timeout
	check("night 1 has 3 waves", dn.night_number == 1 and inv.waves_total == 3)
	var saw_boss: bool = await _play_to_wave(inv, p, 99)
	check("night 1 is won without a boss", inv.last_success and not saw_boss and inv.wave == 3)

	# ---- night 5: the boss night
	dn.set_time(5.9)
	await create_timer(1.0).timeout
	dn.night_number = 4
	dn.set_time(20.6)
	await create_timer(5.0).timeout
	check("night 5 is a boss night with 4 waves", dn.night_number == 5 and inv.active and inv.waves_total == 4)
	var early: bool = await _play_to_wave(inv, p, 4)
	check("the boss does not come before wave 4", not early)
	await create_timer(0.3).timeout
	var boss = _night_lord()
	check("wave 4 brings the Night Lord", boss != null and inv.wave == 4)
	check("tier 1: 900 hp, plain name", boss != null and absf(boss.max_health - 900.0) < 0.01 and boss.display_name == "Άρχοντας της Νύχτας")
	check("the boss has an escort of 6", get_nodes_in_group("invaders").size() == 7)
	check("the boss was announced", banners.has(Strings.INVASION_BOSS_COMING))
	if boss == null:
		quit(1)
		return

	boss.call("_summon")
	await create_timer(1.0).timeout            # a tick of the invasion merges the helpers into its list
	var helpers: Array = boss.get("_summons")
	check("the boss called two helpers", helpers.size() == 2)
	var keep = helpers[0]
	for e in get_nodes_in_group("invaders"):
		if e != keep:
			e.take_damage(99999.0, p.global_position)
	await create_timer(1.5).timeout
	check("the night is not won while a helper is alive", inv.active and not inv.last_success)

	var power_before: int = p.consumables["power"]
	var xp_before := p.xp
	keep.take_damage(99999.0, p.global_position)
	await create_timer(1.5).timeout
	check("the night is won when the helper is dead", inv.last_success and not inv.active)
	check("the boss victory banner", banners.has(Strings.INVASION_BOSS_WON))
	check("a power potion and a speed potion as reward", p.consumables["power"] >= power_before + 1 and p.consumables["speed"] >= 1)
	check("xp was gained", p.xp != xp_before or p.level > 1)
	var found := false
	for c in main.get_node("Village/Chests").get_children():
		if c.get("golden") == true and int(c.get("gold_min")) == 2 * (30 + 15 * 5):
			found = true
	check("the golden chest has double gold", found)

	# ---- night 10: tier 2, and the dawn takes it away
	dn.set_time(5.9)
	await create_timer(1.0).timeout
	dn.night_number = 9
	dn.set_time(20.6)
	await create_timer(5.0).timeout
	await _play_to_wave(inv, p, 4)
	await create_timer(0.3).timeout
	boss = _night_lord()
	check("night 10 brings a stronger Night Lord II", boss != null and absf(boss.max_health - 1260.0) < 0.01 and boss.display_name == "Άρχοντας της Νύχτας II")
	check("tier 2 escort of 8", get_nodes_in_group("invaders").size() == 9)
	dn.set_time(5.6)
	await create_timer(3.5).timeout
	check("at dawn the boss and everyone else crumble", get_nodes_in_group("invaders").size() == 0 and not inv.active)
	quit(1 if failed else 0)
