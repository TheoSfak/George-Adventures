class_name UpdateInstaller
## The file work of the updater. Every path is absolute (use ProjectSettings.globalize_path for user://).
## The running exe is renamed to <exe>.old (Windows allows that), the new one takes its place, and the
## next start deletes the leftovers. See docs/superpowers/specs/2026-10-13-auto-update-design.md.


## Unzips into `dest_dir`. Refuses zips with unsafe entry names or without `exe_name`.
## Returns {"ok": true, "files": [names]} or {"ok": false, "error": "zip" | "files"}.
static func extract(zip_path: String, dest_dir: String, exe_name: String) -> Dictionary:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return {"ok": false, "error": "zip"}
	var files: Array[String] = []
	for entry in reader.get_files():
		if entry.ends_with("/"):
			continue
		if not UpdateLogic.safe_entry_name(entry):
			reader.close()
			return {"ok": false, "error": "zip"}
		files.append(entry)
	if not files.has(exe_name):
		reader.close()
		return {"ok": false, "error": "zip"}
	DirAccess.make_dir_recursive_absolute(dest_dir)
	for entry in files:
		var f := FileAccess.open(dest_dir.path_join(entry), FileAccess.WRITE)
		if f == null:
			reader.close()
			return {"ok": false, "error": "files"}
		f.store_buffer(reader.read_file(entry))
		f.close()
	reader.close()
	return {"ok": true, "files": files}


## Copies the staged files next to the game as <name>.new (a failure here changes nothing), then renames
## the old exe to .old and the new one into place, then replaces the other files.
static func swap(stage_dir: String, install_dir: String, files: Array, exe_name: String) -> Dictionary:
	var copied: Array[String] = []
	for name in files:
		var target := install_dir.path_join(name) + ".new"
		if DirAccess.copy_absolute(stage_dir.path_join(name), target) != OK:
			_drop(copied)
			return {"ok": false, "error": "write"}
		copied.append(target)
	var exe := install_dir.path_join(exe_name)
	var old := exe + ".old"
	if FileAccess.file_exists(old):
		DirAccess.remove_absolute(old)
	var had_exe := FileAccess.file_exists(exe)
	if had_exe and DirAccess.rename_absolute(exe, old) != OK:
		_drop(copied)
		return {"ok": false, "error": "rename"}
	if DirAccess.rename_absolute(exe + ".new", exe) != OK:
		if had_exe:
			DirAccess.rename_absolute(old, exe)
		_drop(copied)
		return {"ok": false, "error": "rename"}
	for name in files:
		if name == exe_name:
			continue
		var path := install_dir.path_join(name)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		DirAccess.rename_absolute(path + ".new", path)
	return {"ok": true, "error": ""}


static func _drop(paths: Array[String]) -> void:
	for p in paths:
		DirAccess.remove_absolute(p)


## Files left by an update: GeorgeAdventures*.old/.new and Play-*.old/.new next to the exe.
static func is_leftover(name: String) -> bool:
	if not (name.ends_with(".old") or name.ends_with(".new")):
		return false
	return name.begins_with("GeorgeAdventures") or name.begins_with("Play-")


static func cleanup(install_dir: String) -> void:
	if not DirAccess.dir_exists_absolute(install_dir):
		return
	for f in DirAccess.get_files_at(install_dir):
		if is_leftover(f):
			DirAccess.remove_absolute(install_dir.path_join(f))


static func remove_tree(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		remove_tree(dir.path_join(d))
	DirAccess.remove_absolute(dir)
