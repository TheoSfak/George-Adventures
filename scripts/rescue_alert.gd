class_name RescueAlert
extends Control
## The "Andreas is in danger" card: dark glass panel, a title, the text, one button.
## Space / Enter / R / click close it.

signal accepted

var _opened_at := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(0.92))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.text = Strings.RESCUE_TITLE
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var text := Label.new()
	text.text = Strings.RESCUE_TEXT
	text.add_theme_font_size_override("font_size", 22)
	text.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(520, 0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	var button := UiKit.button(Strings.RESCUE_BUTTON, _accept, 160.0, 22)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(button)
	_opened_at = Time.get_ticks_msec() / 1000.0


func _input(event: InputEvent) -> void:
	# a short guard, so the key George is already pressing does not close the card at once
	if not visible or Time.get_ticks_msec() / 1000.0 - _opened_at < 0.4:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		_accept()
		get_viewport().set_input_as_handled()


func _accept() -> void:
	if not visible:
		return
	visible = false
	accepted.emit()
	queue_free()
