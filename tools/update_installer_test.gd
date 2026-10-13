extends SceneTree
## The file work of the updater in a temporary folder under user://:
##   godot --path . --headless --script tools/update_installer_test.gd
var failed := false
var tmp := ""


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func make_zip(path: String, entries: Dictionary) -> void:
	var zp := ZIPPacker.new()
	zp.open(path)
	for name in entries:
		zp.start_file(name)
		zp.write_file(String(entries[name]).to_utf8_buffer())
		zp.close_file()
	zp.close()


func write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func read(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _run() -> void:
	await process_frame
	tmp = ProjectSettings.globalize_path("user://update_installer_test")
	UpdateInstaller.remove_tree(tmp)
	DirAccess.make_dir_recursive_absolute(tmp)
	# --- extract
	make_zip(tmp + "/good.zip", {"GeorgeAdventures.exe": "NEWEXE", "Play-Mobile-Renderer.bat": "NEWBAT"})
	var ex := UpdateInstaller.extract(tmp + "/good.zip", tmp + "/stage", "GeorgeAdventures.exe")
	check("extract ok", ex["ok"] and ex["files"].size() == 2)
	check("extracted exe content", read(tmp + "/stage/GeorgeAdventures.exe") == "NEWEXE")
	check("extracted bat content", read(tmp + "/stage/Play-Mobile-Renderer.bat") == "NEWBAT")
	make_zip(tmp + "/slip.zip", {"GeorgeAdventures.exe": "X", "../evil.txt": "EVIL"})
	var slip := UpdateInstaller.extract(tmp + "/slip.zip", tmp + "/stage_slip", "GeorgeAdventures.exe")
	check("zip-slip entry refused", not slip["ok"] and slip["error"] == "zip")
	check("nothing escaped the stage folder", not FileAccess.file_exists(tmp + "/evil.txt"))
	make_zip(tmp + "/noexe.zip", {"readme.txt": "hi"})
	check("zip without the exe refused", not UpdateInstaller.extract(tmp + "/noexe.zip", tmp + "/stage_noexe", "GeorgeAdventures.exe")["ok"])
	check("missing zip refused", not UpdateInstaller.extract(tmp + "/nope.zip", tmp + "/stage_nope", "GeorgeAdventures.exe")["ok"])
	# --- swap
	var inst := tmp + "/install"
	DirAccess.make_dir_recursive_absolute(inst)
	write(inst + "/GeorgeAdventures.exe", "OLDEXE")
	write(inst + "/Play-Mobile-Renderer.bat", "OLDBAT")
	var sw := UpdateInstaller.swap(tmp + "/stage", inst, ex["files"], "GeorgeAdventures.exe")
	check("swap ok", sw["ok"])
	check("new exe in place", read(inst + "/GeorgeAdventures.exe") == "NEWEXE")
	check("old exe kept as .old", read(inst + "/GeorgeAdventures.exe.old") == "OLDEXE")
	check("bat replaced", read(inst + "/Play-Mobile-Renderer.bat") == "NEWBAT")
	check("no .new files left", not FileAccess.file_exists(inst + "/GeorgeAdventures.exe.new") and not FileAccess.file_exists(inst + "/Play-Mobile-Renderer.bat.new"))
	# a second update with a leftover .old
	write(inst + "/GeorgeAdventures.exe", "EXE2")
	var sw2 := UpdateInstaller.swap(tmp + "/stage", inst, ex["files"], "GeorgeAdventures.exe")
	check("swap over an existing .old ok", sw2["ok"] and read(inst + "/GeorgeAdventures.exe.old") == "EXE2")
	# first install into a folder without an exe
	var inst2 := tmp + "/install2"
	DirAccess.make_dir_recursive_absolute(inst2)
	check("swap into a folder without an exe", UpdateInstaller.swap(tmp + "/stage", inst2, ex["files"], "GeorgeAdventures.exe")["ok"] and read(inst2 + "/GeorgeAdventures.exe") == "NEWEXE")
	# an install folder that does not exist changes nothing and fails
	var bad := UpdateInstaller.swap(tmp + "/stage", tmp + "/no_such_folder", ex["files"], "GeorgeAdventures.exe")
	check("swap into a missing folder fails", not bad["ok"] and bad["error"] == "write")
	check("...and created nothing", not DirAccess.dir_exists_absolute(tmp + "/no_such_folder"))
	# --- cleanup
	write(inst + "/Play-Mobile-Renderer.bat.new", "x")
	write(inst + "/other.old", "keep")
	UpdateInstaller.cleanup(inst)
	check("cleanup removed GeorgeAdventures.exe.old", not FileAccess.file_exists(inst + "/GeorgeAdventures.exe.old"))
	check("cleanup removed a .bat.new", not FileAccess.file_exists(inst + "/Play-Mobile-Renderer.bat.new"))
	check("cleanup kept the exe and unrelated files", FileAccess.file_exists(inst + "/GeorgeAdventures.exe") and FileAccess.file_exists(inst + "/other.old"))
	check("is_leftover table", UpdateInstaller.is_leftover("GeorgeAdventures.exe.old") and UpdateInstaller.is_leftover("Play-X.bat.new")
		and not UpdateInstaller.is_leftover("GeorgeAdventures.exe") and not UpdateInstaller.is_leftover("other.old") and not UpdateInstaller.is_leftover("godot.exe.new"))
	# --- remove_tree
	UpdateInstaller.remove_tree(tmp)
	check("remove_tree removed everything", not DirAccess.dir_exists_absolute(tmp))
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
