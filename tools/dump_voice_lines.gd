extends SceneTree
## Writes every voiced line of the game (VoiceData.lines()) with its voice profile and file key as JSON,
## the input of tools/gen_voice.py:
##   godot --path . --headless --script tools/dump_voice_lines.gd -- tools/_voice/lines.json
## The path after "--" is optional (default tools/_voice/lines.json).


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "tools/_voice/lines.json"
	var lines: Array = []
	for entry in VoiceData.lines():
		lines.append({
			"speaker": entry["speaker"],
			"profile": entry["profile"],
			"text": entry["text"],
			"key": VoiceData.key(entry["profile"], entry["text"]),
		})
	var data := {"profiles": VoiceData.PROFILES, "lines": lines}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path).get_base_dir())
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		printerr("cannot write ", out_path)
		quit(1)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	var chars := 0
	for l in lines:
		chars += String(l["text"]).length()
	print("%d lines, %d characters -> %s" % [lines.size(), chars, out_path])
	quit(0)
