extends SceneTree
## Read-only call to the real GitHub API; prints what the updater would offer for a given local version:
##   godot --path . --headless --script tools/updater_live_test.gd -- 0.16-beta
func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	GameSettings.ensure_loaded()
	GameSettings.check_updates = true
	var args := OS.get_cmdline_user_args()
	var u := Updater.new()
	if args.size() > 0:
		u.local_version = args[0]
	root.add_child(u)
	u.check()
	var left := 15.0
	while left > 0.0 and u.state == Updater.State.CHECKING:
		await create_timer(0.1).timeout
		left -= 0.1
	print("local ", u.local_version, " -> state ", Updater.State.keys()[u.state])
	print("offered: ", u.release)
	quit()
