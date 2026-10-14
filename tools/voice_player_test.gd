extends SceneTree
## VoiceOver and the SoundManager voice: playing, silence for unknown lines, the Voice bus, the duck, the
## volume setting. It asserts on return values and bus state, not on audible output (headless audio is a dummy):
##   godot --path . --headless --script tools/voice_player_test.gd
## Needs the recordings (python tools/gen_voice.py).
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var line: Dictionary = VoiceData.lines()[0]
	check("without a SoundManager nothing plays", VoiceOver.play(line["speaker"], line["text"]) == 0.0 and not VoiceOver.is_speaking())

	var had := FileAccess.file_exists(GameSettings.PATH)
	var backup := FileAccess.get_file_as_bytes(GameSettings.PATH) if had else PackedByteArray()
	GameSettings.load_file()

	# loaded at run time: the script mentions autoloads, which do not exist while this file compiles
	var sound: Node = (load("res://scripts/sound_manager.gd") as GDScript).new()
	root.add_child(sound)
	await process_frame
	check("the Voice bus exists", AudioServer.get_bus_index("Voice") >= 0)
	check("Voice is a GameSettings volume with a default of 1.0", GameSettings.BUS_NAMES.has("voice") and GameSettings.DEFAULT_VOLUMES["voice"] == 1.0)

	var seconds := VoiceOver.play(line["speaker"], line["text"])
	check("a voiced line returns its length (%.1f s)" % seconds, seconds > 2.0 and seconds < 40.0)
	check("and is speaking", VoiceOver.is_speaking())
	# the duck: music and ambience sink while the voice runs
	for i in 40:
		await process_frame
	var music_duck := AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0) as AudioEffectAmplify
	var ambient_duck := AudioServer.get_bus_effect(AudioServer.get_bus_index("Ambient"), 0) as AudioEffectAmplify
	check("music and ambience are lowered while someone speaks", music_duck.volume_db < -3.0 and ambient_duck.volume_db < -3.0)
	check("sound effects are not", AudioServer.get_bus_effect_count(AudioServer.get_bus_index("SFX")) == 0)
	VoiceOver.stop()
	check("stop() silences it", not VoiceOver.is_speaking())
	await create_timer(0.8).timeout
	check("the duck comes back", music_duck.volume_db > -0.1 and ambient_duck.volume_db > -0.1)

	# a new line replaces the old one; unknown ones cut it off and stay silent
	VoiceOver.play(line["speaker"], line["text"])
	var second: Dictionary = VoiceData.lines()[1]
	var s2 := VoiceOver.play(second["speaker"], second["text"])
	check("the next line replaces the one before", s2 > 0.0 and VoiceOver.is_speaking())
	check("a speaker without a voice returns 0 and cuts the voice off", VoiceOver.play("Τυχαίος Χωριανός", "Καλημέρα!") == 0.0 and not VoiceOver.is_speaking())
	check("a line without a recording returns 0", VoiceOver.play(line["speaker"], line["text"] + " (αλλαγμένο)") == 0.0)

	# the volume setting drives the bus
	GameSettings.set_volume("voice", 0.5)
	var idx := AudioServer.get_bus_index("Voice")
	check("the Voice bus follows the slider", absf(AudioServer.get_bus_volume_db(idx) - linear_to_db(0.5)) < 0.01)
	GameSettings.set_volume("voice", 0.0)
	check("zero is silent", AudioServer.get_bus_volume_db(idx) <= -79.0)

	# an old settings.json without "voice" loads with the default
	var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
	f.store_string('{"version": 1, "volumes": {"master": 0.7, "music": 0.8, "sfx": 0.9, "ambient": 0.8}}')
	f.close()
	GameSettings.load_file()
	check("an old settings file gets the default voice volume", GameSettings.volumes["voice"] == 1.0 and GameSettings.volumes["master"] == 0.7)

	# restore the real settings file
	if had:
		var r := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		r.store_buffer(backup)
		r.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	GameSettings.load_file()
	GameSettings.apply_audio()
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
