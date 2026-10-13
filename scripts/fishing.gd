class_name Fishing
extends Control
## The fishing mini-game, a HUD overlay. Press R at the dock: the line is cast, you wait 2 to 6 s,
## the float dips and a bar appears with a green zone and a moving marker: press the button
## (R, Enter, Space, left click) while the marker is in the zone. One input only, so it works over
## AnyDesk. Which fish bites comes from ShopData.JUNK (entries with "fish": true).

signal finished(caught: String)           # the species id, "" when nothing was caught

enum State { IDLE, CASTING, WAITING, BITE }

const CAST_TIME := 1.0
const WAIT_MIN := 2.0
const WAIT_MAX := 6.0
const BITE_WINDOW := 2.5
const PANEL := Vector2(470.0, 118.0)
const BAR := Rect2(26.0, 56.0, 418.0, 28.0)

var state := State.IDLE
var species := ""                          # the fish on the line (chosen at the bite)

var _player: Player
var _bobber: MeshInstance3D
var _target := Vector3.ZERO
var _t := 0.0                              # seconds in the current state
var _wait := 0.0
var _bite_left := 0.0
var _marker := 0.0                         # 0..1 along the bar
var _dir := 1.0
var _zone := 0.3                           # width of the green zone (share of the bar)
var _zone_center := 0.5
var _speed := 0.7
var _open_time := 0.0
var _rng := RandomNumberGenerator.new()
var _panel_box: StyleBoxFlat
var _track := StyleBoxFlat.new()
var _zone_box := StyleBoxFlat.new()


func _ready() -> void:
	name = "Fishing"
	add_to_group("fishing")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_rng.randomize()
	_panel_box = UiKit.panel_style(0.88)
	_track.bg_color = Color(0.03, 0.04, 0.07, 0.85)
	_track.border_color = Color(1, 1, 1, 0.18)
	_track.set_border_width_all(1)
	_track.set_corner_radius_all(14)
	_track.anti_aliasing = true
	_zone_box.bg_color = Color(0.36, 0.85, 0.42, 0.95)
	_zone_box.border_color = Color(0.75, 1.0, 0.78, 0.9)
	_zone_box.set_border_width_all(1)
	_zone_box.set_corner_radius_all(10)
	_zone_box.anti_aliasing = true


## A random species by weight. Day-only and night-only fish are left out at the wrong time.
static func pick_fish(rng: RandomNumberGenerator, night: bool) -> String:
	var ids: Array[String] = []
	var total := 0.0
	for id in ShopData.fish_ids():
		var only: String = ShopData.JUNK[id].get("only", "")
		if (only == "night" and not night) or (only == "day" and night):
			continue
		ids.append(id)
		total += float(ShopData.JUNK[id]["weight"])
	var roll := rng.randf() * total
	for id in ids:
		roll -= float(ShopData.JUNK[id]["weight"])
		if roll <= 0.0:
			return id
	return ids[ids.size() - 1]


## True when the marker is inside the zone around `center` (both 0..1, zone = full width).
static func hit(marker: float, center: float, zone: float) -> bool:
	return absf(marker - center) <= zone / 2.0


func is_active() -> bool:
	return state != State.IDLE


## Starts a cast: George stands at `stand` facing the water spot `target`.
func begin(player: Player, stand: Vector3, target: Vector3) -> void:
	if state != State.IDLE or player.busy:
		return
	_player = player
	_target = target
	player.busy = true
	player.teleport(stand, atan2(target.x - stand.x, target.z - stand.z))
	_make_bobber()
	state = State.CASTING
	_t = 0.0
	_open_time = Time.get_ticks_msec() / 1000.0
	visible = true
	Sfx.play("fish_cast", target)
	queue_redraw()


func _make_bobber() -> void:
	_bobber = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.14
	sphere.height = 0.28
	_bobber.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.15, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.1, 0.08)
	mat.emission_energy_multiplier = 0.6
	_bobber.material_override = mat
	_bobber.position = _target + Vector3(0.0, 3.0, 0.0)
	_bobber.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_player.get_parent().add_child(_bobber)


func _process(delta: float) -> void:
	if state == State.IDLE:
		return
	_t += delta
	match state:
		State.CASTING:
			var k := clampf(_t / CAST_TIME, 0.0, 1.0)
			_bobber.position = _target + Vector3(0.0, 0.1 + (1.0 - k) * (1.0 - k) * 3.0, 0.0)
			if _t >= CAST_TIME:
				state = State.WAITING
				_t = 0.0
				_wait = _rng.randf_range(WAIT_MIN, WAIT_MAX)
		State.WAITING:
			_bobber.position = _target + Vector3(0.0, 0.1 + sin(_t * 3.0) * 0.02, 0.0)
			_wait -= delta
			if _wait <= 0.0:
				_bite()
		State.BITE:
			_bobber.position = _target + Vector3(0.0, 0.02 + sin(_t * 18.0) * 0.03, 0.0)
			_marker += _dir * _speed * delta
			if _marker >= 1.0:
				_marker = 1.0
				_dir = -1.0
			elif _marker <= 0.0:
				_marker = 0.0
				_dir = 1.0
			_bite_left -= delta
			if _bite_left <= 0.0:
				_end("", Strings.MSG_FISH_ESCAPED, "fish_escape")
	queue_redraw()


func _bite() -> void:
	var daynight := get_tree().get_first_node_in_group("daynight")
	var night: bool = daynight != null and daynight.darkness() > 0.6
	species = pick_fish(_rng, night)
	var f: Dictionary = ShopData.JUNK[species]
	_zone = float(f["zone"])
	_speed = float(f["speed"])
	_zone_center = _rng.randf_range(_zone / 2.0 + 0.06, 1.0 - _zone / 2.0 - 0.06)
	_marker = 0.0
	_dir = 1.0
	_bite_left = BITE_WINDOW
	state = State.BITE
	_t = 0.0
	Sfx.play("fish_bite", _target)


func _input(event: InputEvent) -> void:
	if state == State.IDLE or Time.get_ticks_msec() / 1000.0 - _open_time < 0.3:
		return
	if event.is_action_pressed("ui_cancel"):
		_end("")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept") \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		press()
		get_viewport().set_input_as_handled()


## The one button: too early ends the cast, in time during the bite decides by the marker.
func press() -> void:
	match state:
		State.CASTING, State.WAITING:
			_end("", Strings.MSG_FISH_EARLY, "fish_escape")
		State.BITE:
			if hit(_marker, _zone_center, _zone):
				var caught := species
				_player.add_fish(caught)
				_end(caught, "", "fish_catch")
			else:
				_end("", Strings.MSG_FISH_ESCAPED, "fish_escape")


func _end(caught: String, message: String = "", sound: String = "") -> void:
	if state == State.IDLE:
		return
	if message != "":
		_player.message.emit(message)
	if sound != "":
		Sfx.ui(sound)
	if is_instance_valid(_bobber):
		_bobber.queue_free()
	_bobber = null
	state = State.IDLE
	visible = false
	finished.emit(caught)
	# keep George still for a moment so the same press does not start the next cast
	await get_tree().create_timer(0.25).timeout
	if state == State.IDLE and _player != null:
		_player.busy = false


func _draw() -> void:
	if state == State.IDLE:
		return
	var origin := Vector2((size.x - PANEL.x) / 2.0, size.y * 0.58)
	draw_style_box(_panel_box, Rect2(origin, PANEL))
	var font := UiKit.font()
	var text := Strings.FISH_CAST
	var color := UiKit.CREAM
	if state == State.WAITING:
		text = Strings.FISH_WAIT
	elif state == State.BITE:
		text = Strings.FISH_BITE
		color = UiKit.GOLD_TEXT
	draw_string(font, origin + Vector2(26.0, 38.0), text, HORIZONTAL_ALIGNMENT_LEFT, PANEL.x - 52.0, 22, color)
	if state == State.BITE:
		var bar := Rect2(origin + BAR.position, BAR.size)
		draw_style_box(_track, bar)
		draw_style_box(_zone_box, Rect2(bar.position.x + (_zone_center - _zone / 2.0) * bar.size.x, bar.position.y + 3.0,
				_zone * bar.size.x, bar.size.y - 6.0))
		var mx := bar.position.x + _marker * bar.size.x
		draw_rect(Rect2(mx - 3.0, bar.position.y - 5.0, 6.0, bar.size.y + 10.0), Color(1.0, 0.96, 0.8))
	draw_string(font, origin + Vector2(26.0, 108.0), Strings.FISH_HINT, HORIZONTAL_ALIGNMENT_LEFT, PANEL.x - 52.0, 14, UiKit.MUTED)
