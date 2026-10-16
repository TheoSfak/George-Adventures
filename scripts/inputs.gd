extends Node
## Registers all game controls in code (autoload "Inputs").
## Keys use PHYSICAL positions, so WASD works on a Greek keyboard layout too.
## To change a control, edit the lines in _ready().

var _diag_layer: CanvasLayer
var _diag: Label
var _last_key := "-"
const WATCHED := ["move_forward", "move_back", "turn_left", "turn_right", "strafe_left", "strafe_right", "jump", "attack", "kick", "dodge", "interact"]


func _ready() -> void:
	get_window().window_input.connect(_on_window_input)
	_register_defaults()
	GameSettings.apply_keys()          # keys the player re-bound in the settings window

	if not Engine.is_editor_hint() and DisplayServer.get_name() != "headless":
		var args := OS.get_cmdline_args()
		var is_test_run := false
		for a in args:
			if a == "-s" or a.begins_with("--script"):
				is_test_run = true
				break
		if not is_test_run:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Back to the built-in controls (settings window: "Επαναφορά").
func restore_defaults() -> void:
	InputMap.load_from_project_settings()
	_register_defaults()
	GameSettings.apply_keys()


func _register_defaults() -> void:
	# Movement, World-of-Warcraft style:
	#   W/S forward/back, A/D turn (or strafe while right mouse is held), Q/E strafe.
	#   Hold RIGHT mouse = look + steer. Hold LEFT mouse = orbit camera only.
	#   Both mouse buttons = run forward. Mouse wheel = zoom. (Handled in player.gd.)
	_key("move_forward", KEY_W)
	_key("move_forward", KEY_UP)
	_key("move_back", KEY_S)
	_key("move_back", KEY_DOWN)
	_key("turn_left", KEY_A)
	_key("turn_left", KEY_LEFT)
	_key("turn_right", KEY_D)
	_key("turn_right", KEY_RIGHT)
	_key("strafe_left", KEY_Q)
	_key("strafe_right", KEY_E)
	# Gamepad left stick moves relative to the camera (separate actions).
	_axis("pad_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("pad_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("pad_forward", JOY_AXIS_LEFT_Y, -1.0)
	_axis("pad_back", JOY_AXIS_LEFT_Y, 1.0)

	# Actions (a quick left click, without dragging, also attacks - see player.gd)
	_key("jump", KEY_SPACE)
	_button("jump", JOY_BUTTON_A)
	_key("run", KEY_SHIFT)
	_button("run", JOY_BUTTON_LEFT_STICK)
	_key("attack", KEY_F)
	_key("attack", KEY_J)
	_button("attack", JOY_BUTTON_X)
	_key("dodge", KEY_V)              # the dodge roll
	_button("dodge", JOY_BUTTON_RIGHT_SHOULDER)
	_key("kick", KEY_C)               # front kick
	_button("kick", JOY_BUTTON_LEFT_STICK)
	_key("mount", KEY_G)              # ride the horse (once it is bought at the stable)
	_key("unstuck", KEY_U)            # emergency teleport to village center if stuck
	_key("potion", KEY_H)
	_button("potion", JOY_BUTTON_Y)
	# Action bar: keys 1-8, 9, 0, -, = (physical keys, so they work on the Greek layout too)
	const ACTION_BAR_KEYS: Array[Key] = [
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8,
		KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL
	]
	for i in ACTION_BAR_KEYS.size():
		_key("slot_%d" % (i + 1), ACTION_BAR_KEYS[i])
	_key("slot_9", KEY_KP_9)
	_key("slot_10", KEY_KP_0)
	_key("slot_11", KEY_KP_SUBTRACT)
	for i in range(12, 24):
		var act := "slot_%d" % (i + 1)
		if not InputMap.has_action(act):
			InputMap.add_action(act, 0.2)
	_key("skillbook", KEY_P)
	_key("talents", KEY_T)
	_key("equipment", KEY_I)
	_key("map", KEY_M)
	_key("interact", KEY_R)
	_key("interact", KEY_ENTER)       # remote-desktop tools often mangle letter keys; Enter and the arrow keys still arrive
	_key("interact", KEY_KP_ENTER)
	_button("interact", JOY_BUTTON_B)
	_key("block", KEY_K)
	_key("block", KEY_CTRL)
	_button("block", JOY_BUTTON_LEFT_SHOULDER)

	# Camera (gamepad right stick; mouse look is handled in player.gd)
	_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)


## F12 shows a diagnostics overlay: the last key the game received and what it matched.
## (window_input sees every real key press, even ones the UI consumes; _input also sees
## synthetic events.)
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F12:
		_toggle_diag()
	_on_window_input(event)


func _on_window_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.echo:
		return
	var matched: Array = []
	for a in WATCHED:
		if key.is_action(a):
			matched.append(a)
	_last_key = "%s  [φυσικό: %s | λογικό: %s]  ->  %s" % ["πάτημα" if key.pressed else "άφημα", OS.get_keycode_string(key.physical_keycode), OS.get_keycode_string(key.keycode), ", ".join(matched) if not matched.is_empty() else "καμία ενέργεια"]


func _toggle_diag() -> void:
	if _diag_layer == null:
		_diag_layer = CanvasLayer.new()
		_diag_layer.layer = 100
		_diag_layer.visible = false      # the toggle below shows it
		add_child(_diag_layer)
		_diag = Label.new()
		_diag.position = Vector2(20, 240)
		_diag.add_theme_font_size_override("font_size", 16)
		_diag.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
		_diag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_diag.add_theme_constant_override("outline_size", 6)
		_diag_layer.add_child(_diag)
	_diag_layer.visible = not _diag_layer.visible


func _process(_delta: float) -> void:
	if _diag_layer == null or not _diag_layer.visible:
		return
	var held: Array = []
	for a in WATCHED:
		if Input.is_action_pressed(a):
			held.append(a)
	var player := get_tree().get_first_node_in_group("player")
	var hud := get_tree().get_first_node_in_group("hud")
	var sm := get_tree().get_first_node_in_group("sound_manager")
	var lines := [
		"ΔΙΑΓΝΩΣΤΙΚΑ  [F12 κλείνει]",
		"Τελευταίο πλήκτρο: %s" % _last_key,
		"Πατημένες ενέργειες: %s" % (", ".join(held) if not held.is_empty() else "-"),
		"Παίκτης κλειδωμένος (busy): %s    Διάλογος ανοιχτός: %s" % [str(player.get("busy")) if player else "-", str(hud.is_dialogue_open()) if hud else "-"],
		"Συσκευή ήχου: %s (%d Hz)  [F9 αλλαγή]" % [AudioServer.output_device, int(AudioServer.get_mix_rate())],
		"Μουσική: %s    Master: %s" % [str(sm.get("_music_id")) if sm else "-", "ΣΙΓΑΣΗ" if AudioServer.is_bus_mute(0) else "ok"],
	]
	_diag.text = "\n".join(lines)


## F11 switches between the 1920x1080 window and borderless fullscreen.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F11:
		var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


func _add(action: StringName, ev: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	InputMap.action_add_event(action, ev)


## Every key is bound twice: by physical position (works on any keyboard layout) and by the
## logical key (works when a remote-control tool or odd driver sends no scan code).
func _key(action: StringName, keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	_add(action, ev)
	var logical := InputEventKey.new()
	logical.keycode = keycode
	_add(action, logical)


func _mouse(action: StringName, button: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	_add(action, ev)


func _button(action: StringName, button: JoyButton) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	_add(action, ev)


func _axis(action: StringName, axis: JoyAxis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	_add(action, ev)
