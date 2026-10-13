extends SceneTree
## Fishing: the species draw, the bar decision and a whole cast driven through the overlay:
##   godot --path . --headless --script tools/fishing_test.gd
var failed := false
var p: Player
var fishing
var fz   # fishing.gd, loaded


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func fish_spot() -> InteractSpot:
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_FISH:
			return n
	return null


## Starts a cast at the real dock and waits for the bite.
func cast_and_bite() -> void:
	var spot := fish_spot()
	spot.interact(p)
	await create_timer(1.3).timeout                 # the cast takes 1 s
	fishing._wait = 0.05
	await create_timer(0.4).timeout


func _run() -> void:
	await process_frame
	fz = load("res://scripts/fishing.gd")
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	fishing = get_first_node_in_group("fishing")
	check("the fishing overlay exists in the HUD", fishing != null)
	check("there is a fishing spot at the pond", fish_spot() != null)
	if fishing == null or fish_spot() == null:
		quit(1)
		return

	# --- the draw
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var day := {}
	var night := {}
	for i in 4000:
		var d: String = fz.pick_fish(rng, false)
		day[d] = int(day.get(d, 0)) + 1
		var n: String = fz.pick_fish(rng, true)
		night[n] = int(night.get(n, 0)) + 1
	check("by day: no moonfish, sunfish possible (found %d)" % int(day.get("sunfish", 0)), not day.has("moonfish") and day.has("sunfish"))
	check("at night: no sunfish, moonfish possible (found %d)" % int(night.get("moonfish", 0)), not night.has("sunfish") and night.has("moonfish"))
	check("12 species by day", day.size() == 12 and night.size() == 12)
	check("common fish are much more frequent than rare ones", int(day["perch"]) > 5 * int(day["goldfish"]))
	check("the legendary fish does bite, rarely", day.has("king") and int(day["king"]) < int(day["perch"]) / 5)

	# --- the bar decision
	check("a marker inside the zone hits", fz.hit(0.5, 0.5, 0.2) and fz.hit(0.59, 0.5, 0.2))
	check("a marker outside the zone misses", not fz.hit(0.61, 0.5, 0.2) and not fz.hit(0.0, 0.5, 0.2))

	# --- a successful catch
	p.junk = {}
	p.fish_seen = []
	var stand_before := p.global_position
	await cast_and_bite()
	check("a bite after the wait", fishing.state == fz.State.BITE and fishing.species != "")
	check("George is busy while fishing", p.busy)
	var species: String = fishing.species
	fishing._marker = fishing._zone_center
	fishing.press()
	await create_timer(0.6).timeout
	check("the fish %s is in the bag" % species, int(p.junk.get(species, 0)) == 1)
	check("the journal has it", p.fish_seen == [species])
	check("the overlay is idle and George is free again", fishing.state == fz.State.IDLE and not p.busy and not fishing.visible)

	# --- a miss
	await cast_and_bite()
	var zone: float = fishing._zone
	fishing._marker = fishing._zone_center + zone / 2.0 + 0.1 if fishing._zone_center < 0.5 else fishing._zone_center - zone / 2.0 - 0.1
	fishing.press()
	await create_timer(0.6).timeout
	check("a miss catches nothing (still 1 fish)", p.junk.values().reduce(func(a, b): return a + b, 0) == 1 and not p.busy)

	# --- too early
	fish_spot().interact(p)
	await create_timer(1.3).timeout
	check("waiting for a bite", fishing.state == fz.State.WAITING)
	fishing.press()
	await create_timer(0.6).timeout
	check("pulling too early ends the cast without a fish", fishing.state == fz.State.IDLE and p.junk.values().reduce(func(a, b): return a + b, 0) == 1 and not p.busy)

	# --- the fish gets away when you are too slow
	await cast_and_bite()
	fishing._bite_left = 0.05
	await create_timer(0.7).timeout
	check("a slow reaction lets the fish escape", fishing.state == fz.State.IDLE and p.junk.values().reduce(func(a, b): return a + b, 0) == 1 and not p.busy)

	# --- Esc cancels
	fish_spot().interact(p)
	await create_timer(0.8).timeout
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.6).timeout
	check("Esc cancels the cast", fishing.state == fz.State.IDLE and not p.busy)

	# --- a button press during the first 0.3 s is ignored (the press that started the cast)
	check("the player stands near the dock after fishing", p.global_position.distance_to(stand_before) < 200.0)
	quit(1 if failed else 0)
