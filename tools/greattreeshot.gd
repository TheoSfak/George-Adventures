extends SceneTree
## Screenshots of the Great Tree area and the frame rate in it:
##   godot --path . --resolution 1920x1080 --script tools/greattreeshot.gd -- tools/_shots/greattreeshot [day|night]
## Without the last word both parts run in one process; on a GPU shared with other programs run them one
## after the other (a long run can run out of memory).
var out := "."
var part := "both"

# [name, position (local to the area centre), look-at target (local), measure fps]
const VIEWS := [
	["01_approach", Vector3(-62.0, 0.05, 0.0), Vector3(0.0, 12.0, 0.0), true],
	["02_shore", Vector3(-52.0, 0.05, 2.5), Vector3(-24.0, 3.0, 3.0), false],
	["03_entry_island", Vector3(-24.0, 3.0, 3.0), Vector3(4.0, 22.0, -1.0), false],
	["04_causeway", Vector3(4.0, 5.2, -16.5), Vector3(18.0, 7.0, -8.0), false],
	["05_plateau", Vector3(11.0, 7.0, 4.0), Vector3(4.0, 8.0, -1.0), true],
	["06_south_island", Vector3(-10.0, 5.6, 21.0), Vector3(4.0, 14.0, 0.0), false],
	["07_far_island", Vector3(28.0, 4.0, -4.0), Vector3(4.0, 8.0, 0.0), false],
	["08_in_the_water", Vector3(-12.0, 0.05, -16.0), Vector3(4.0, 14.0, -1.0), false],
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		part = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func sample(label: String, secs: float) -> void:
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		frames += 1
	print("PERF ", label, ": ", snappedf(frames / secs, 0.1), " fps, draw calls ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


## George stands at `local` (relative to the area centre) and looks at `target` (also local).
func visit(p: Player, local: Vector3, target: Vector3) -> void:
	var c := Vector3(172.0, 0.0, -40.0)
	var pos := c + local
	var look := c + target
	p.teleport(pos, atan2(look.x - pos.x, look.z - pos.z))
	await create_timer(1.6).timeout


func run_views(p: Player, prefix: String, measure: bool) -> void:
	for v in VIEWS:
		await visit(p, v[1], v[2])
		await shot("%s_%s" % [prefix, v[0]])
		if measure and v[3]:
			await sample("%s %s" % [prefix, v[0]], 3.0)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	p._invulnerable = 99999.0
	dn.running = false
	if part != "night":
		dn.set_time(12.0)
		await create_timer(1.0).timeout
		await run_views(p, "day", true)
	if part == "day":
		quit()
		return
	dn.set_time(22.0)
	await create_timer(2.0).timeout
	for v in [VIEWS[0], VIEWS[4], VIEWS[2]]:
		await visit(p, v[1], v[2])
		await shot("night_%s" % v[0])
		await sample("night %s" % v[0], 3.0)
	quit()
