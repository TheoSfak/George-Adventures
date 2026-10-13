extends SceneTree
## The weather state machine: picking, blending, fading outdoors, messages, icons, F6.
##   godot --path . --headless --script tools/weather_logic_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func approx(a: float, b: float) -> bool:
	return absf(a - b) < 0.001


## Runs the weather for `seconds` of simulated time (the node's own _process is switched off in this test).
func settle(w, seconds: int) -> void:
	for i in seconds:
		w.step(1.0)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var wz = load("res://scripts/weather.gd")

	# --- picking the next state (static, no world needed)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var after := {0: {}, 1: {}, 2: {}, 3: {}}
	for cur in 4:
		for i in 6000:
			var n: int = wz.pick_next(cur, rng)
			after[cur][n] = int(after[cur].get(n, 0)) + 1
	for cur in 4:
		check("state %d is never followed by itself" % cur, not after[cur].has(cur))
	check("a storm only comes after rain", not after[0].has(3) and not after[1].has(3) and after[2].has(3))
	check("from clear: rain is a bit more likely than fog", int(after[0][2]) > int(after[0][1]) and int(after[0][1]) > 2000)
	var visits := {0: 0, 1: 0, 2: 0, 3: 0}
	var cur := 0
	for i in 40000:
		cur = wz.pick_next(cur, rng)
		visits[cur] = int(visits[cur]) + 1
	check("over a long time: clear > rain > fog > storm " + str(visits), visits[0] > visits[2] and visits[2] > visits[1] and visits[1] > visits[3] and visits[3] > 0)
	check("the lightning flash curve", wz.flash_curve(0.0) == 1.0 and wz.flash_curve(0.08) == 0.0 and wz.flash_curve(0.2) > 0.1 and wz.flash_curve(0.2) < 0.8 and wz.flash_curve(0.3) == 0.0)

	# --- the node in the real world
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var w = get_first_node_in_group("weather")
	var p := get_first_node_in_group("player") as Player
	var interiors = get_first_node_in_group("interiors")
	check("the Weather node is in the scene", w != null)
	if w == null:
		quit(1)
		return
	check("it starts clear, with nothing in the air and the first change at least 100 s away (the minimap picture is taken now)",
			w.state == 0 and w.overcast == 0.0 and w.fog == 0.0 and w.rain == 0.0 and w.storm == 0.0 and w.wet == 0.0 and w.time_to_next > 100.0)
	w.set_process(false)
	var msgs: Array = []
	p.message.connect(func(t): msgs.append(t))

	# --- messages and names
	w.force(2)
	check("rain starts with its Greek message", msgs.back() == Strings.WEATHER_RAIN)
	w.force(3)
	check("storm message", msgs.back() == Strings.WEATHER_STORM)
	w.force(1)
	check("fog message", msgs.back() == Strings.WEATHER_FOG)
	w.force(0)
	check("clear message", msgs.back() == Strings.WEATHER_CLEAR)
	check("state names are Greek", w.state_name() == "Καθαρός" and Strings.WEATHER_NAMES.size() == 4)

	# --- blending toward the targets
	w.force(3)
	settle(w, 10)
	check("after 10 s the storm is only part of the way (overcast %.2f)" % w.overcast, w.overcast > 0.2 and w.overcast < 0.7)
	settle(w, 20)
	check("after 30 s the storm values are there", approx(w.overcast, 1.0) and approx(w.fog, 0.35) and approx(w.rain, 1.0) and approx(w.storm, 1.0))
	check("the ground is wet", approx(w.wet, 1.0))
	check("the icon of a storm", w.icon_id() == "storm")
	w.force(0)
	settle(w, 30)
	check("30 s later it is clear again", approx(w.overcast, 0.0) and approx(w.rain, 0.0) and approx(w.storm, 0.0) and approx(w.fog, 0.0))
	check("the ground dries slowly (wet %.2f)" % w.wet, w.wet > 0.5 and w.wet < 0.8)
	check("no icon when clear", w.icon_id() == "")
	w.force(2, true)
	settle(w, 7)
	check("a forced change is fast: rain 0.7 within 7 s", approx(w.rain, 0.7) and approx(w.overcast, 0.75))
	check("the icon of rain", w.icon_id() == "rain")
	w.force(1, true)
	settle(w, 7)
	check("the icon of fog is a cloud", w.icon_id() == "cloud" and approx(w.fog, 1.0))

	# --- F6 cycles the four states
	w.force(0)
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_F6
	ev.pressed = true
	var seen: Array = []
	for i in 5:
		w._unhandled_input(ev)
		seen.append(w.state)
	check("F6 cycles fog, rain, storm, clear, fog: " + str(seen), seen == [1, 2, 3, 0, 1])
	w.force(0)
	settle(w, 30)

	# --- the Frontier is outdoors but has no weather
	w.force(3)
	settle(w, 30)
	check("in a storm outdoors rain is 1", approx(w.rain, 1.0))
	interiors.enter_region("frontier", Vector3(0.0, 0.05, -150.0), 0.0, p)
	for i in 100:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	check("George is in the Frontier", interiors.in_region())
	settle(w, 3)
	check("there the weather has faded out", w.rain == 0.0 and w.overcast == 0.0 and w.fog == 0.0 and w.storm == 0.0 and w.wet == 0.0 and w.flash == 0.0)
	check("but the storm goes on underneath", w.rain_raw > 0.9)
	msgs.clear()
	w.force(2)
	check("no message in the Frontier", msgs.is_empty())
	interiors.exit_region(p)
	for i in 100:
		await create_timer(0.1).timeout
		if not interiors.in_region() and not p.busy:
			break
	check("George is back in the village", not interiors.in_region())
	settle(w, 3)
	check("and the weather is back", w.rain > 0.5 and w.outdoor == 1.0)

	# --- a house
	w.force(3)
	settle(w, 30)
	interiors.enter("tavern_weather", "tavern", Vector3(-59, 0.05, 5), 0.0, p)
	for i in 60:
		await create_timer(0.1).timeout
		if interiors.is_inside() and not p.busy:
			break
	check("George is inside the tavern", interiors.is_inside())
	settle(w, 3)
	check("indoors nothing is seen: rain, fog, overcast, flash are 0", w.rain == 0.0 and w.overcast == 0.0 and w.fog == 0.0 and w.flash == 0.0)
	check("but it still rains outside (rain_raw)", w.rain_raw > 0.9)
	msgs.clear()
	w.force(0)
	check("no message indoors", msgs.is_empty())
	check("the save file does not know about the weather", not FileAccess.get_file_as_string("res://scripts/save_game.gd").to_lower().contains("weather"))
	quit(1 if failed else 0)
