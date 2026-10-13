extends SceneTree
## The weather icon in the clock capsule, the new icons and the help line:
##   godot --path . --headless --script tools/weather_hud_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func settle(w, seconds: int) -> void:
	for i in seconds:
		w.step(1.0)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var w = get_first_node_in_group("weather")
	var hud = get_first_node_in_group("hud")
	w.set_process(false)
	check("the clock shows the sun or moon when it is clear", hud._clock_weather == "")

	for entry in [[1, "cloud"], [2, "rain"], [3, "storm"], [0, ""]]:
		w.force(entry[0])
		settle(w, 30)
		await create_timer(0.3).timeout
		check("state %d: the clock icon is '%s' (got '%s')" % [entry[0], entry[1], hud._clock_weather], hud._clock_weather == entry[1])

	# the new icons draw without errors
	var canvas := Control.new()
	canvas.size = Vector2(200, 60)
	canvas.draw.connect(func():
		for i in 3:
			Icons.draw(canvas, Rect2(Vector2(i * 60.0, 0.0), Vector2(28, 28)), ["cloud", "rain", "storm"][i], Color.WHITE))
	root.add_child(canvas)
	canvas.queue_redraw()
	await process_frame
	await process_frame
	check("the cloud, rain and storm icons draw", true)

	# the help page lists F6
	var has_f6 := false
	for row in Strings.CONTROLS_HELP:
		if row[0] == "F6" and row[1] == "Αλλαγή καιρού":
			has_f6 = true
	check("the help page lists F6 (Αλλαγή καιρού)", has_f6)
	quit(1 if failed else 0)
