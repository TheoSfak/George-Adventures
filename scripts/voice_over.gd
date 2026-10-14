class_name VoiceOver
## Spoken dialogue from anywhere:   var seconds := VoiceOver.play(speaker, text)
## Looks the line up in assets/audio/voice (see VoiceData) and plays it on the Voice bus. Returns the length of
## the recording in seconds, or 0.0 when the speaker has no voice, the line has no recording or there is no
## SoundManager (tests, tools): the game then simply stays silent. Whatever was being said before is cut off.


static func play(speaker: String, text: String) -> float:
	var manager := _manager()
	if manager == null:
		return 0.0
	manager.stop_voice()
	var profile := VoiceData.profile_for(speaker)
	if profile == "":
		return 0.0
	var path := VoiceData.path(profile, text)
	if not ResourceLoader.exists(path):
		return 0.0
	return manager.play_voice(load(path) as AudioStream)


static func stop() -> void:
	var manager := _manager()
	if manager != null:
		manager.stop_voice()


static func is_speaking() -> bool:
	var manager := _manager()
	return manager != null and manager.is_voice_playing()


static func _manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("sound_manager") if tree != null else null
