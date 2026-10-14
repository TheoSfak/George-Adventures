extends SceneTree
## Every voiced line has its recording in assets/audio/voice (fails when a line was edited and
## tools/gen_voice.py was not run again):  godot --path . --headless --script tools/voice_files_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var missing := 0
	var total := 0
	for l in VoiceData.lines():
		total += 1
		if not ResourceLoader.exists(VoiceData.path(l["profile"], l["text"])):
			missing += 1
			if missing <= 5:
				print("  missing: ", l["speaker"], ": ", String(l["text"]).substr(0, 50))
	check("%d of %d lines have a recording" % [total - missing, total], missing == 0)
	var stream := load(VoiceData.path(VoiceData.lines()[0]["profile"], VoiceData.lines()[0]["text"])) as AudioStream
	check("a recording loads and has a length", stream != null and stream.get_length() > 1.0)
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
