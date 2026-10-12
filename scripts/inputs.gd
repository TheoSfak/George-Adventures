extends Node
## Registers all game controls in code (autoload "Inputs").
## Keys use PHYSICAL positions, so WASD works on a Greek keyboard layout too.
## To change a control, edit the lines in _ready().

func _ready() -> void:
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
	_key("potion", KEY_H)
	_button("potion", JOY_BUTTON_Y)
	# Action bar: keys 1-8 (physical keys, so they work on the Greek layout too)
	for i in 8:
		_key("slot_%d" % (i + 1), KEY_1 + i)
	_key("skillbook", KEY_P)
	_key("talents", KEY_T)
	_key("equipment", KEY_I)
	_key("interact", KEY_R)
	_button("interact", JOY_BUTTON_B)
	_key("block", KEY_K)
	_key("block", KEY_CTRL)
	_button("block", JOY_BUTTON_LEFT_SHOULDER)

	# Camera (gamepad right stick; mouse look is handled in player.gd)
	_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)


func _add(action: StringName, ev: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	InputMap.action_add_event(action, ev)


func _key(action: StringName, keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	_add(action, ev)


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
