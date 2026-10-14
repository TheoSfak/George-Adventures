extends SceneTree
## Rescue rules (timer, drain, besieger mix):
##   godot --path . --headless --script tools/rescue_rules_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ok := true
	for i in 200:
		var l := RescueRules.pick_limit(rng)
		ok = ok and l >= RescueRules.MIN_DELAY and l <= RescueRules.MAX_DELAY
	check("limit always in 180..300", ok)
	var free := {"busy": false, "indoors": false, "region": false, "dead": false, "invasion": false}
	check("free outdoors", RescueRules.is_free(free))
	for k in ["busy", "indoors", "region", "dead"]:
		var c := free.duplicate()
		c[k] = true
		check("not free when %s" % k, not RescueRules.is_free(c))
	check("fires at the limit", RescueRules.should_fire(200.0, 200.0, free))
	check("not before the limit", not RescueRules.should_fire(199.0, 200.0, free))
	var inv := free.duplicate()
	inv["invasion"] = true
	check("not during an invasion", not RescueRules.should_fire(300.0, 200.0, inv))
	check("full time with six: 150 s to zero", is_equal_approx(RescueRules.drain(1.0, 6, 150.0), 0.0))
	check("three besiegers drain half as fast", is_equal_approx(RescueRules.drain(1.0, 3, 150.0), 0.5))
	check("no besiegers, no drain", is_equal_approx(RescueRules.drain(0.7, 0, 100.0), 0.7))
	check("never below zero", RescueRules.drain(0.1, 6, 100.0) == 0.0)
	check("level 1 mix: 4 minion 2 warrior", RescueRules.kinds_for(1).count("minion") == 4 and RescueRules.kinds_for(1).count("warrior") == 2)
	check("level 5 has an archer", RescueRules.kinds_for(5).has("rogue"))
	check("level 10 has a brute", RescueRules.kinds_for(10).has("brute"))
	for lv in [1, 5, 10, 20]:
		check("always six at level %d" % lv, RescueRules.kinds_for(lv).size() == RescueRules.BESIEGERS)
	quit(1 if failed else 0)
