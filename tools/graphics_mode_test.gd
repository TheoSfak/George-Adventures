extends SceneTree
## The graphics mode logic (no menu): godot --path . --headless --script tools/graphics_mode_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _run() -> void:
	await process_frame
	# --- ids, labels
	check("three modes", GraphicsMode.ids() == PackedStringArray(["forward_plus", "mobile", "gl_compatibility"]))
	check("valid ids", GraphicsMode.is_valid("mobile") and GraphicsMode.is_valid("forward_plus") and GraphicsMode.is_valid("gl_compatibility"))
	check("invalid ids", not GraphicsMode.is_valid("") and not GraphicsMode.is_valid("vulkan") and not GraphicsMode.is_valid("Mobile"))
	var labels_ok := true
	for id in GraphicsMode.ids():
		labels_ok = labels_ok and GraphicsMode.label(id) != ""
	check("every mode has a Greek label", labels_ok)
	var desc_ok := true
	for id in GraphicsMode.ids():
		desc_ok = desc_ok and GraphicsMode.description(id) != ""
	check("every mode has a description", desc_ok and GraphicsMode.description("bogus") == "")
	check("current renderer is one of the modes (%s)" % GraphicsMode.current(), GraphicsMode.is_valid(GraphicsMode.current()))
	# --- override.cfg text
	var txt := GraphicsMode.override_text("mobile")
	check("override text has the marker", txt.begins_with(GraphicsMode.MARKER))
	check("override text sets the renderer", txt.contains("[rendering]") and txt.contains("renderer/rendering_method=\"mobile\""))
	# --- writing and reading in a temporary folder
	var tmp := ProjectSettings.globalize_path("user://graphics_mode_test")
	UpdateInstaller.remove_tree(tmp)
	DirAccess.make_dir_recursive_absolute(tmp)
	check("nothing there yet", GraphicsMode.read_override(tmp) == "")
	check("write mobile", GraphicsMode.write_override(tmp, "mobile"))
	check("file exists", FileAccess.file_exists(tmp + "/override.cfg"))
	check("read it back", GraphicsMode.read_override(tmp) == "mobile")
	check("write gl_compatibility over it", GraphicsMode.write_override(tmp, "gl_compatibility") and GraphicsMode.read_override(tmp) == "gl_compatibility")
	check("forward_plus removes the game's own file", GraphicsMode.write_override(tmp, "forward_plus") and not FileAccess.file_exists(tmp + "/override.cfg"))
	check("forward_plus with no file is fine", GraphicsMode.write_override(tmp, "forward_plus"))
	# a hand-made override.cfg is never deleted or read as ours
	write(tmp + "/override.cfg", "[display]\n\nwindow/size/mode=3\n")
	check("a foreign file reads as no choice", GraphicsMode.read_override(tmp) == "")
	check("forward_plus leaves a foreign file alone", GraphicsMode.write_override(tmp, "forward_plus") and FileAccess.file_exists(tmp + "/override.cfg"))
	check("a foreign file is not overwritten by a mode", not GraphicsMode.write_override(tmp, "mobile") and FileAccess.get_file_as_string(tmp + "/override.cfg").contains("window/size/mode"))
	check("an invalid id writes nothing", not GraphicsMode.write_override(tmp + "/empty_sub", "bogus"))
	check("a missing folder fails", not GraphicsMode.write_override(tmp + "/no_such_folder", "mobile"))
	# --- restart arguments
	check("restart args", GraphicsMode.restart_args("mobile", PackedStringArray()) == PackedStringArray(["--rendering-method", "mobile"]))
	check("restart args keep user args", GraphicsMode.restart_args("forward_plus", PackedStringArray(["a"])) == PackedStringArray(["--rendering-method", "forward_plus", "--", "a"]))
	# --- apply
	check("can_restart is false in a script run", not GraphicsMode.can_restart())
	var r := GraphicsMode.apply("mobile", tmp)
	check("apply refuses outside the exported game", not r["ok"] and r["error"] == "editor")
	check("...and writes nothing", GraphicsMode.read_override(tmp) == "")
	check("apply with an invalid id", GraphicsMode.apply("bogus", tmp)["error"] == "invalid")
	UpdateInstaller.remove_tree(tmp)
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
