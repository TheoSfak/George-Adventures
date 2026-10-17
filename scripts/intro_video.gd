class_name IntroVideo
extends CanvasLayer
## Introductory cinematic video overlay shown right after the boot splash screen.
## Plays "Οι Περιπέτειες του Γιώργου στον Άγιο Βλάση" animated cinematic intro (assets/video/intro.ogv).
## Allows skipping via Space, Escape, Enter, or mouse click.
## Once finished or skipped, transitions to the Title Menu.

signal intro_finished

const VIDEO_PATH := "res://assets/video/intro.ogv"

var _player: VideoStreamPlayer
var _hint: Label
var _fade_rect: ColorRect
var _finished := false


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:

	# 1. Solid black background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.01, 0.02, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# 2. Video player filling the screen
	_player = VideoStreamPlayer.new()
	_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player.expand = true
	_player.bus = &"Master"
	_player.volume_db = 0.0
	_player.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_player)

	# 3. Skip hint at bottom right
	_hint = Label.new()
	_hint.text = "[Space / Esc] Παράλειψη"
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.offset_left = -260.0
	_hint.offset_top = -50.0
	_hint.offset_right = -24.0
	_hint.offset_bottom = -16.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 0.75))
	_hint.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06, 0.95))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	# 4. Black fade overlay for smooth transitions
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

	# 5. Load and play video if available and not in headless mode
	if DisplayServer.get_name() != "headless" and ResourceLoader.exists(VIDEO_PATH):
		var stream = load(VIDEO_PATH) as VideoStream
		if stream:
			_player.stream = stream
			_player.finished.connect(_on_video_finished)
			_player.play()
			return

	# If in headless mode or stream not found, finish immediately
	call_deferred("_finish")


func _input(event: InputEvent) -> void:
	if _finished:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode in [KEY_SPACE, KEY_ESCAPE, KEY_ENTER]:
			get_viewport().set_input_as_handled()
			_finish()
	elif event is InputEventMouseButton and event.is_pressed():
		get_viewport().set_input_as_handled()
		_finish()
	elif event is InputEventJoypadButton and event.is_pressed():
		get_viewport().set_input_as_handled()
		_finish()


func _on_video_finished() -> void:
	_finish()


func _finish(animated: bool = true) -> void:
	if _finished:
		return
	_finished = true
	if _player != null and is_instance_valid(_player):
		_player.stop()

	# Gentle quick fade out into the title menu if in tree and animated
	if animated and is_inside_tree() and _fade_rect != null and is_instance_valid(_fade_rect):
		var tween := create_tween()
		if tween:
			tween.tween_property(_fade_rect, "color:a", 1.0, 0.2)
			tween.tween_callback(func():
				intro_finished.emit()
				queue_free()
			)
			return
	intro_finished.emit()
	queue_free()
