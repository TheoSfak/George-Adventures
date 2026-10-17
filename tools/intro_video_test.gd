@tool
extends SceneTree

const IntroVideoClass := preload("res://scripts/intro_video.gd")
const GameMenuClass := preload("res://scripts/game_menu.gd")

var _passed := 0
var _failed := 0


func _check(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % msg)
	else:
		_failed += 1
		print("  FAIL: %s" % msg)


func _init() -> void:
	print("--- Running Intro Cinematic Video Test Suite ---")

	_test_video_asset_and_format()
	_test_intro_video_node_structure()
	_test_skip_input_and_signals()
	_test_game_menu_integration()
	_test_export_preset_configuration()

	print("==================================================")
	print("Summary: %d Passed, %d Failed" % [_passed, _failed])
	print("==================================================")
	quit(_failed)


func _test_video_asset_and_format() -> void:
	print("\n[1] Testing Video Asset & VideoStreamTheora...")
	_check(FileAccess.file_exists("res://assets/video/intro.ogv"), "Video file 'res://assets/video/intro.ogv' exists")

	var stream = ResourceLoader.load("res://assets/video/intro.ogv")
	_check(stream != null, "VideoStream resource loaded successfully")
	if stream != null:
		_check(stream is VideoStreamTheora, "Stream is instance of VideoStreamTheora")
		_check(stream.get_class() == "VideoStreamTheora", "Stream class name is VideoStreamTheora")


func _test_intro_video_node_structure() -> void:
	print("\n[2] Testing IntroVideo Node & Visual Layout...")
	var intro: CanvasLayer = IntroVideoClass.new()
	_check(intro.layer >= 100, "IntroVideo layer is >= 100 (renders on top of all HUD and UI)")
	_check(intro.process_mode == Node.PROCESS_MODE_ALWAYS, "IntroVideo process_mode is PROCESS_MODE_ALWAYS")

	# Call _ready() to build UI
	intro._ready()

	# Verify children
	var has_bg := false
	var has_video := false
	var has_hint := false
	var has_fade := false

	for c in intro.get_children():
		if c is ColorRect and c.color.a >= 0.99:
			has_bg = true
		elif c is VideoStreamPlayer:
			has_video = true
			_check(c.expand == true, "VideoStreamPlayer expand property is true")
			_check(c.bus == &"Master", "VideoStreamPlayer audio bus is Master")
		elif c is Label:
			has_hint = true
			_check("Παράλειψη" in c.text, "Skip hint contains Greek text 'Παράλειψη'")
		elif c is ColorRect and c.color.a == 0.0:
			has_fade = true

	_check(has_bg, "Black solid background ColorRect exists")
	_check(has_video, "Fullscreen VideoStreamPlayer exists")
	_check(has_hint, "Skip hint Label exists")
	_check(has_fade, "Fade ColorRect overlay exists")

	intro.queue_free()


func _test_skip_input_and_signals() -> void:
	print("\n[3] Testing Skip Input & Finish Flow...")
	var intro = IntroVideoClass.new()
	var signal_emitted := [false]
	intro.intro_finished.connect(func(): signal_emitted[0] = true)

	# Test finishing directly without animation
	intro._finish(false)
	_check(signal_emitted[0], "Calling _finish(false) emitted intro_finished signal")
	_check(intro.get("_finished") == true, "_finished flag is set to true")

	# Calling second time should be idempotent
	signal_emitted[0] = false
	intro._finish(false)
	_check(signal_emitted[0] == false, "Subsequent _finish() calls are idempotent")


func _test_game_menu_integration() -> void:
	print("\n[4] Testing GameMenu Integration & Test Bypasses...")
	var menu: GameMenu = GameMenuClass.new()
	root.add_child(menu)

	# In headless mode or tests, _is_headless_or_test must be true
	_check(menu.has_method("_start_with_intro_or_title"), "GameMenu has _start_with_intro_or_title method")
	_check(menu.has_method("_play_intro_video"), "GameMenu has _play_intro_video method")
	_check(menu.has_method("_is_headless_or_test"), "GameMenu has _is_headless_or_test method")

	var is_test: bool = menu.call("_is_headless_or_test")
	_check(is_test == true, "_is_headless_or_test() correctly returns true in headless test environment")

	menu.queue_free()


func _test_export_preset_configuration() -> void:
	print("\n[5] Testing Export Preset Configuration...")
	var cfg_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check("*.ogv" in cfg_text, "export_presets.cfg includes '*.ogv' in include_filter")
