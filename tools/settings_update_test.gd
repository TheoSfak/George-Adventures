extends SceneTree
## The update flag in settings.json:  godot --path . --headless --script tools/settings_update_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var had := FileAccess.file_exists(GameSettings.PATH)
	var backup := FileAccess.get_file_as_bytes(GameSettings.PATH) if had else PackedByteArray()
	if had:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	GameSettings.load_file()
	check("default is on", GameSettings.check_updates)
	GameSettings.set_check_updates(false)
	GameSettings.load_file()
	check("off survives a reload", not GameSettings.check_updates)
	check("the file keeps the other settings", FileAccess.get_file_as_string(GameSettings.PATH).contains("\"volumes\""))
	GameSettings.set_check_updates(true)
	GameSettings.load_file()
	check("on again", GameSettings.check_updates)
	# restore the real file
	if had:
		var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		f.store_buffer(backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	GameSettings.load_file()
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
