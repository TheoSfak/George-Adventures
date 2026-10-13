class_name Weather
extends Node
## The village weather: clear, fog, rain and thunderstorms, picked at random and blended smoothly.
## Atmosphere only (no gameplay effect). Four internal values glide toward the targets of the current
## state; the public values (overcast, fog, rain, storm, flash, wet) are those values multiplied by
## `outdoor`, which fades to 0 indoors and in the Frontier, so everybody else just reads them.
## DayNight (sky, light, fog), the ground shaders (wetness), SoundManager and the HUD read this node;
## it never writes to the Environment itself.

signal state_changed(new_state: int)

enum State { CLEAR, FOG, RAIN, STORM }

## Target of each internal value per state (the look is tuned from these numbers).
const TARGETS := {
	State.CLEAR: {"overcast": 0.0, "fog": 0.0, "rain": 0.0, "storm": 0.0},
	State.FOG: {"overcast": 0.5, "fog": 1.0, "rain": 0.0, "storm": 0.0},
	State.RAIN: {"overcast": 0.75, "fog": 0.25, "rain": 0.7, "storm": 0.0},
	State.STORM: {"overcast": 1.0, "fog": 0.35, "rain": 1.0, "storm": 1.0},
}
const WEIGHTS := {State.CLEAR: 45.0, State.FOG: 20.0, State.RAIN: 25.0, State.STORM: 10.0}
const BLEND_SECONDS := 25.0           # a full change
const FAST_BLEND_SECONDS := 6.0       # a change forced with F6
const CHANGE_MIN := 120.0             # real seconds until the next random change
const CHANGE_MAX := 300.0
const OUTDOOR_FADE_SECONDS := 1.5
const WET_RISE_SECONDS := 20.0
const WET_DRY_SECONDS := 90.0
const STORM_MIN := 0.6                # lightning only while the storm is this strong
const BOLT_MIN := 6.0
const BOLT_MAX := 18.0
const BOLT_SECONDS := 0.25

var state := State.CLEAR
# What everybody reads (already multiplied by `outdoor`):
var overcast := 0.0
var fog := 0.0
var rain := 0.0
var storm := 0.0
var flash := 0.0                      # 0..1 during a lightning flash
var wet := 0.0                        # how wet the ground looks
var outdoor := 1.0                    # 1 outside in the village, 0 indoors and in the Frontier
var rain_raw := 0.0                   # the rain without the outdoor fade (the roof sound uses it)
var time_to_next := 0.0
var bolts := 0                        # lightning flashes so far
var thunders := 0                     # thunder claps played so far

var _blend := {"overcast": 0.0, "fog": 0.0, "rain": 0.0, "storm": 0.0}
var _blend_seconds := BLEND_SECONDS
var _wet_raw := 0.0
var _bolt_t := -1.0                   # seconds into the current flash, -1 = none
var _bolt_timer := 5.0
var _thunder_in := 0.0
var _thunder_pending := false
var _rng := RandomNumberGenerator.new()
var _player: Player
var _interiors: Node
var _wet_sent := -1.0
var _clouds: Node
var _cloud_mat: StandardMaterial3D
var _clouds_tinted := false


func _ready() -> void:
	add_to_group("weather")
	_rng.randomize()
	time_to_next = _rng.randf_range(CHANGE_MIN, CHANGE_MAX)


## The state that follows `current`, by weight. Never the same state; a storm only comes after rain.
static func pick_next(current: int, rng: RandomNumberGenerator) -> int:
	var options: Array[int] = []
	var total := 0.0
	for s in WEIGHTS:
		if s == current:
			continue
		if s == State.STORM and current != State.RAIN:
			continue
		options.append(s)
		total += float(WEIGHTS[s])
	var roll := rng.randf() * total
	for s in options:
		roll -= float(WEIGHTS[s])
		if roll <= 0.0:
			return s
	return options[options.size() - 1]


## Brightness of a lightning flash `t` seconds after it started: a bright flash, a gap, a second
## flash that fades out.
static func flash_curve(t: float) -> float:
	if t < 0.06:
		return 1.0
	if t < 0.11:
		return 0.0
	if t < BOLT_SECONDS:
		return 0.8 * (1.0 - (t - 0.11) / 0.14)
	return 0.0


## Changes the weather now. `fast` = a 6 s blend instead of 25 s (F6).
func force(new_state: int, fast := false) -> void:
	state = new_state as State
	_blend_seconds = FAST_BLEND_SECONDS if fast else BLEND_SECONDS
	time_to_next = _rng.randf_range(CHANGE_MIN, CHANGE_MAX)
	_announce(new_state)
	state_changed.emit(new_state)


## F6: the next state in the order clear, fog, rain, storm.
func cycle() -> void:
	force((int(state) + 1) % 4, true)


func state_name() -> String:
	return Strings.WEATHER_NAMES[int(state)]


## The picture next to the clock: "" = the usual sun or moon.
func icon_id() -> String:
	if storm > 0.5:
		return "storm"
	if rain > 0.3:
		return "rain"
	if fog > 0.5 or overcast > 0.5:
		return "cloud"
	return ""


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F6:
		cycle()


func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	step(delta)
	apply_effects()


## Advances the weather by `delta` seconds (public so a test can drive time).
func step(delta: float) -> void:
	time_to_next -= delta
	if time_to_next <= 0.0:
		force(pick_next(int(state), _rng))
	var target: Dictionary = TARGETS[state]
	var rate := delta / _blend_seconds
	for k in _blend:
		_blend[k] = move_toward(float(_blend[k]), float(target[k]), rate)
	outdoor = move_toward(outdoor, _outdoor_target(), delta / OUTDOOR_FADE_SECONDS)
	# the ground gets wet fairly fast and dries slowly
	var rain_now := float(_blend["rain"])
	var wet_seconds := WET_RISE_SECONDS if rain_now > _wet_raw else WET_DRY_SECONDS
	_wet_raw = move_toward(_wet_raw, rain_now, delta / wet_seconds)
	overcast = float(_blend["overcast"]) * outdoor
	fog = float(_blend["fog"]) * outdoor
	rain = rain_now * outdoor
	storm = float(_blend["storm"]) * outdoor
	rain_raw = rain_now
	wet = _wet_raw * outdoor
	_update_lightning(delta)


## 1 outside in the village, 0 inside a building, the catacombs or the Frontier.
func _outdoor_target() -> float:
	if _interiors == null:
		_interiors = get_tree().get_first_node_in_group("interiors")
	if _interiors != null and (_interiors.is_inside() or _interiors.in_region()):
		return 0.0
	return 1.0


func _announce(new_state: int) -> void:
	if outdoor < 0.5 or _player == null:
		return
	_player.message.emit(Strings.WEATHER_MESSAGES[new_state])


# ------------------------------------------------------------------ lightning ----

func _update_lightning(delta: float) -> void:
	var strong := float(_blend["storm"]) > STORM_MIN
	if _bolt_t >= 0.0:
		_bolt_t += delta
		flash = flash_curve(_bolt_t) * outdoor
		if _bolt_t > BOLT_SECONDS:
			_bolt_t = -1.0
			flash = 0.0
	else:
		flash = 0.0
		if strong:
			_bolt_timer -= delta
			if _bolt_timer <= 0.0:
				_start_bolt()
		else:
			_bolt_timer = _rng.randf_range(3.0, 8.0)
	if _thunder_pending:
		_thunder_in -= delta
		if _thunder_in <= 0.0:
			_thunder_pending = false
			_play_thunder()


func _start_bolt() -> void:
	_bolt_t = 0.0
	flash = flash_curve(0.0) * outdoor
	_bolt_timer = _rng.randf_range(BOLT_MIN, BOLT_MAX)
	_thunder_in = _rng.randf_range(0.3, 2.0)       # the distance of the lightning
	_thunder_pending = true
	bolts += 1


func _play_thunder() -> void:
	if _interiors != null and (_interiors.in_region() or _interiors.current_kind == "catacombs"):
		return
	thunders += 1
	Sfx.ui("thunder", 0.0 if outdoor > 0.5 else -10.0)


## Applies the numbers to the world: the wet ground, the clouds (and the rain, see _apply_rain).
func apply_effects() -> void:
	if absf(wet - _wet_sent) > 0.002:
		_wet_sent = wet
		RenderingServer.global_shader_parameter_set("wetness", wet)
	_tint_clouds()


## In the overcast all the clouds share one grey material (the models are plain white, nothing is lost);
## when the sky is clear again they get their own look back.
func _tint_clouds() -> void:
	if _clouds == null:
		var village := get_parent().get_node_or_null("Village")
		_clouds = village.get_node_or_null("Clouds") if village != null else null
		if _clouds == null:
			return
	var tinted := overcast > 0.02
	if not tinted and not _clouds_tinted:
		return
	if tinted:
		if _cloud_mat == null:
			_cloud_mat = StandardMaterial3D.new()
			_cloud_mat.roughness = 1.0
		_cloud_mat.albedo_color = Color(1.0, 1.0, 1.0).lerp(Color(0.34, 0.36, 0.40), overcast)
	if tinted != _clouds_tinted:
		_clouds_tinted = tinted
		for m in _clouds.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).material_override = _cloud_mat if tinted else null
