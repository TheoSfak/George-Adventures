class_name GraphicsMode
## The graphics setting: which renderer the game starts with. A renderer cannot change while the game
## runs, so the choice is written to override.cfg next to the exe (Godot reads it at start and it
## overrides rendering/renderer/rendering_method) and the exe is started again.
## See docs/superpowers/specs/2026-10-13-graphics-setting-design.md.

const MARKER := "; written by the game's graphics setting"
const FILE_NAME := "override.cfg"
const DEFAULT_ID := "forward_plus"


static func ids() -> PackedStringArray:
	return PackedStringArray(["forward_plus", "mobile", "gl_compatibility"])


static func is_valid(id: String) -> bool:
	return ids().has(id)


static func label(id: String) -> String:
	match id:
		"forward_plus":
			return Strings.GFX_HIGH
		"mobile":
			return Strings.GFX_MEDIUM
		"gl_compatibility":
			return Strings.GFX_COMPAT
	return id


static func description(id: String) -> String:
	match id:
		"forward_plus":
			return Strings.GFX_DESC_HIGH
		"mobile":
			return Strings.GFX_DESC_MEDIUM
		"gl_compatibility":
			return Strings.GFX_DESC_COMPAT
	return ""


## The renderer in use right now.
static func current() -> String:
	return RenderingServer.get_current_rendering_method()


## Only the exported game on Windows can restart itself (a script or editor run would start Godot itself).
static func can_restart() -> bool:
	return not OS.has_feature("editor") and OS.get_name() == "Windows"


static func exe_dir() -> String:
	return OS.get_executable_path().get_base_dir()


static func override_text(id: String) -> String:
	return "%s\n[rendering]\n\nrenderer/rendering_method=\"%s\"\n" % [MARKER, id]


## The mode written by this game in `dir`/override.cfg, or "" (no file, or a file somebody else made).
static func read_override(dir: String) -> String:
	var path := dir.path_join(FILE_NAME)
	if not FileAccess.file_exists(path):
		return ""
	var text := FileAccess.get_file_as_string(path)
	if not text.begins_with(MARKER):
		return ""
	for id in ids():
		if text.contains("renderer/rendering_method=\"%s\"" % id):
			return id
	return ""


## Writes the choice next to the exe. forward_plus (the default) removes the game's own file instead.
## Never touches an override.cfg that the game did not write. Returns false when it cannot.
static func write_override(dir: String, id: String) -> bool:
	if not is_valid(id) or not DirAccess.dir_exists_absolute(dir):
		return false
	var path := dir.path_join(FILE_NAME)
	var exists := FileAccess.file_exists(path)
	var ours := exists and FileAccess.get_file_as_string(path).begins_with(MARKER)
	if id == DEFAULT_ID:
		if ours:
			return DirAccess.remove_absolute(path) == OK
		return true
	if exists and not ours:
		return false
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(override_text(id))
	f.close()
	return true


## The command line wins over override.cfg, so the restart is explicit.
static func restart_args(id: String, user_args: PackedStringArray) -> PackedStringArray:
	var args := PackedStringArray(["--rendering-method", id])
	if not user_args.is_empty():
		args.append("--")
		args.append_array(user_args)
	return args


## Saves the choice and starts the game again. The caller quits when "ok" is true.
## {"ok": bool, "error": "" | "invalid" | "editor" | "write"}
static func apply(id: String, dir: String = "") -> Dictionary:
	if not is_valid(id):
		return {"ok": false, "error": "invalid"}
	if not can_restart():
		return {"ok": false, "error": "editor"}
	if dir == "":
		dir = exe_dir()
	if not write_override(dir, id):
		return {"ok": false, "error": "write"}
	OS.create_process(OS.get_executable_path(), restart_args(id, OS.get_cmdline_user_args()))
	return {"ok": true, "error": ""}
