extends SceneTree
## The rules of levels 21 to 40:
##   godot --path . --headless --script tools/level_scaling_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	for lv in [1, 5, 10, 15, 19, 20]:
		check("level %d: nothing is scaled" % lv, LevelScaling.health_mult(lv) == 1.0 and LevelScaling.damage_mult(lv) == 1.0 and LevelScaling.xp_mult(lv) == 1.0 and LevelScaling.gold_mult(lv) == 1.0)
	check("level 21 is the first scaled level", LevelScaling.health_mult(21) > 1.0 and LevelScaling.damage_mult(21) > 1.0)
	check("level 40: health about x5.4", is_equal_approx(LevelScaling.health_mult(40), 1.0 + 0.22 * 20.0))
	check("level 40: damage about x4.2", is_equal_approx(LevelScaling.damage_mult(40), 1.0 + 0.16 * 20.0))
	check("level 40: xp and gold about x4", is_equal_approx(LevelScaling.xp_mult(40), 4.0) and is_equal_approx(LevelScaling.gold_mult(40), 4.0))
	var mono := true
	for lv in range(1, 40):
		mono = mono and LevelScaling.health_mult(lv + 1) >= LevelScaling.health_mult(lv) and LevelScaling.xp_needed(lv + 1) > LevelScaling.xp_needed(lv)
	check("everything grows with the level", mono)
	check("the old XP curve is kept up to level 20 (705 at level 20)", LevelScaling.xp_needed(1) == 40 and LevelScaling.xp_needed(19) == 40 + 35 * 18 and LevelScaling.xp_needed(20) == 705)
	check("level 21 asks 80 more than level 20", LevelScaling.xp_needed(21) == 785)
	check("level 39 asks 2225", LevelScaling.xp_needed(39) == 2225)
	check("levels 20 to 40 need about 29,000 XP", LevelScaling.xp_total(20, 40) == 29300)
	check("levels 1 to 20 still need 6,745 XP", LevelScaling.xp_total(1, 20) == 6745)
	check("the cap is 40", LevelScaling.MAX_LEVEL == 40)
	quit(1 if failed else 0)
