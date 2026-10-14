extends SceneTree
## The dialogue box with voices: the text types in step with a recording, a line without one keeps the old fast
## typewriter, the voice stops when the talk ends and when a shop window takes over:
##   godot --path . --headless --script tools/dialogue_voice_test.gd
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
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var hud = get_first_node_in_group("hud")
	var p := get_first_node_in_group("player") as Player
	check("the world has a SoundManager", get_first_node_in_group("sound_manager") != null)

	# --- a voiced line: the prologue
	hud.show_dialogue(Strings.NARRATOR, QuestData.PROLOGUE)
	await process_frame
	var seconds: float = hud._dlg_voice_seconds
	check("the prologue line is voiced (%.1f s)" % seconds, seconds > 3.0)
	check("the voice is playing", VoiceOver.is_speaking())
	check("the text has only just started", hud._dlg_text.visible_ratio < 0.2)
	await create_timer(seconds * 0.5).timeout
	var half: float = hud._dlg_text.visible_ratio
	check("half way through the voice the text is about half typed (%.2f)" % half, half > 0.3 and half < 0.65)
	hud._advance_dialogue()
	check("the first press shows the whole line and the voice keeps speaking", hud._dlg_text.visible_ratio == 1.0 and VoiceOver.is_speaking())
	hud._advance_dialogue()
	await process_frame
	check("the second press goes to the next line, which is voiced too", hud._dlg_voice_seconds > 3.0 and VoiceOver.is_speaking() and hud._dlg_index == 1)
	hud._advance_dialogue()
	hud._advance_dialogue()
	await process_frame
	hud._advance_dialogue()
	hud._advance_dialogue()
	await create_timer(0.4).timeout
	check("after the last line the dialogue is closed and the voice is silent", not hud.is_dialogue_open() and not VoiceOver.is_speaking() and hud._dlg_voice_seconds == 0.0)

	# --- a line without a recording: the old behaviour
	hud.show_dialogue("Τυχαίος Χωριανός", ["Καλημέρα!"])
	await process_frame
	check("an unvoiced line has no voice", hud._dlg_voice_seconds == 0.0 and not VoiceOver.is_speaking())
	await create_timer(0.7).timeout
	check("and types fast as before", hud._dlg_text.visible_ratio >= 0.99)
	hud._advance_dialogue()
	await create_timer(0.4).timeout
	check("it closes", not hud.is_dialogue_open())

	# --- a shop greeting hands over to the shop window and the voice is gone
	var greeting: Array = ShopData.SHOPS["market"]["greeting"]
	hud.show_dialogue("Κυρά-Ελένη", greeting, func(): hud.open_shop("market", p))
	await process_frame
	check("the shopkeeper's greeting is voiced", hud._dlg_voice_seconds > 3.0 and VoiceOver.is_speaking())
	hud._advance_dialogue()
	hud._advance_dialogue()
	await create_timer(0.5).timeout
	check("the shop window is open and the voice has stopped", hud.is_shop_open() and not VoiceOver.is_speaking())

	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
