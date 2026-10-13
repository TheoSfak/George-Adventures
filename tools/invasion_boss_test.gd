extends SceneTree
## The rules of the invasion boss nights (no world needed):
##   godot --path . --headless --script tools/invasion_boss_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func approx(a: float, b: float) -> bool:
	return absf(a - b) < 0.001


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	check("night 0 is no boss night", not InvasionBoss.is_boss_night(0))
	check("night 4 is no boss night", not InvasionBoss.is_boss_night(4))
	check("night 5 is a boss night", InvasionBoss.is_boss_night(5))
	check("night 6 is no boss night", not InvasionBoss.is_boss_night(6))
	check("night 10 and 15 are boss nights", InvasionBoss.is_boss_night(10) and InvasionBoss.is_boss_night(15))
	check("tiers: 5 -> 1, 10 -> 2, 15 -> 3", InvasionBoss.tier_of(5) == 1 and InvasionBoss.tier_of(10) == 2 and InvasionBoss.tier_of(15) == 3)
	check("waves: 3 on night 4, 4 on night 5", InvasionBoss.total_waves(4, 3) == 3 and InvasionBoss.total_waves(5, 3) == 4)
	check("factor 1.0 / 1.4 / 1.8", approx(InvasionBoss.factor(1), 1.0) and approx(InvasionBoss.factor(2), 1.4) and approx(InvasionBoss.factor(3), 1.8))
	check("summon cap grows by 1 per tier and stops at 8", InvasionBoss.summon_cap(4, 1) == 4 and InvasionBoss.summon_cap(4, 2) == 5 and InvasionBoss.summon_cap(4, 9) == 8)
	check("escort 6 / 8 / 10", InvasionBoss.escort_size(1) == 6 and InvasionBoss.escort_size(2) == 8 and InvasionBoss.escort_size(3) == 10)
	check("bonus xp 200 / 400", InvasionBoss.bonus_xp(1) == 200 and InvasionBoss.bonus_xp(2) == 400)
	check("roman numerals", InvasionBoss.roman(1) == "I" and InvasionBoss.roman(4) == "IV" and InvasionBoss.roman(9) == "IX" and InvasionBoss.roman(14) == "XIV")
	check("tier 1 keeps the plain name", InvasionBoss.title("Άρχοντας", 1) == "Άρχοντας")
	check("tier 2 and 3 get a numeral", InvasionBoss.title("Άρχοντας", 2) == "Άρχοντας II" and InvasionBoss.title("Άρχοντας", 3) == "Άρχοντας III")
	var base := {"max_health": 900.0, "attack_damage": 28.0, "summon_max": 4, "display_name": "Άρχοντας της Νύχτας"}
	var t1 := InvasionBoss.overrides(1, base)
	check("tier 1 overrides equal the base", approx(t1["max_health"], 900.0) and approx(t1["attack_damage"], 28.0) and t1["summon_max"] == 4 and t1["display_name"] == "Άρχοντας της Νύχτας")
	var t2 := InvasionBoss.overrides(2, base)
	check("tier 2 overrides: 1260 hp, 39.2 damage, 5 helpers, numeral", approx(t2["max_health"], 1260.0) and approx(t2["attack_damage"], 39.2) and t2["summon_max"] == 5 and t2["display_name"] == "Άρχοντας της Νύχτας II")
	check("the strings exist", Strings.INVASION_BOSS_COMING != "" and Strings.INVASION_BOSS_WON != "" and Strings.NIGHT_LORD_ENRAGE != "")
	quit(1 if failed else 0)
