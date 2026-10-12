class_name DayNight
extends Node
## Day/night cycle. One game hour lasts day_length_seconds / 24 real seconds.
## Moves the sun and moon, recolours the sky shader, ambient light and fog, switches the
## lamps in group "night_lights" on at night, and emits the phase signals the villagers
## and the night invasion listen to. set_time(h) jumps to a time (debug / tests).

signal dusk_started
signal night_started(night_number: int)
signal dawn_started
signal day_started

enum Phase { DAY, DUSK, NIGHT, DAWN }

const DAWN_HOUR := 5.5
const DAY_HOUR := 7.0
const DUSK_HOUR := 19.5
const NIGHT_HOUR := 20.5
const SUNRISE := 6.0
const SUNSET := 20.0
const SUN_ENERGY := 1.1
const MOON_ENERGY := 0.28
const AMBIENT_COLOR := Color(0.26, 0.33, 0.62)
const SKY_SHADER := preload("res://shaders/sky.gdshader")

# hour, top, horizon, fog, ambient energy, how much of the ambient comes from the sky
const KEYS := [
	[0.0, Color(0.015, 0.03, 0.09), Color(0.045, 0.07, 0.17), Color(0.05, 0.08, 0.16), 0.9, 0.2],
	[5.0, Color(0.03, 0.06, 0.16), Color(0.10, 0.12, 0.26), Color(0.08, 0.10, 0.20), 0.9, 0.25],
	[6.0, Color(0.22, 0.32, 0.58), Color(0.98, 0.62, 0.42), Color(0.75, 0.60, 0.55), 0.7, 0.7],
	[7.5, Color(0.22, 0.48, 0.86), Color(0.72, 0.84, 0.95), Color(0.78, 0.87, 0.96), 0.75, 1.0],
	[17.5, Color(0.22, 0.48, 0.86), Color(0.72, 0.84, 0.95), Color(0.78, 0.87, 0.96), 0.75, 1.0],
	[19.4, Color(0.28, 0.30, 0.55), Color(1.0, 0.55, 0.28), Color(0.85, 0.60, 0.50), 0.7, 0.8],
	[20.3, Color(0.08, 0.10, 0.26), Color(0.42, 0.24, 0.34), Color(0.30, 0.22, 0.30), 0.85, 0.4],
	[21.8, Color(0.015, 0.03, 0.09), Color(0.045, 0.07, 0.17), Color(0.05, 0.08, 0.16), 0.9, 0.2],
	[24.0, Color(0.015, 0.03, 0.09), Color(0.045, 0.07, 0.17), Color(0.05, 0.08, 0.16), 0.9, 0.2],
]

@export var day_length_seconds := 600.0
@export var start_hour := 9.0
@export var running := true

var time_of_day := 9.0          # hours, 0..24
var day_number := 1
var night_number := 0
var phase := Phase.DAY

var _env: Environment
var _sun: DirectionalLight3D
var _moon: DirectionalLight3D
var _sky_mat: ShaderMaterial
var _lamps: Array[Light3D] = []
var _lamp_timer := 0.0
var _lamp_level := -1.0
var _fireflies: CPUParticles3D
var _player: Node3D
var _interiors: Node


func _ready() -> void:
	add_to_group("daynight")
	time_of_day = start_hour
	phase = _phase_for(time_of_day)
	night_number = 1 if phase == Phase.NIGHT and time_of_day >= NIGHT_HOUR else 0
	var main := get_parent()
	var world_env := main.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_env = world_env.environment if world_env else null
	_sun = main.get_node_or_null("Sun") as DirectionalLight3D
	_moon = main.get_node_or_null("Moon") as DirectionalLight3D
	if _env != null and _env.sky != null:
		_sky_mat = ShaderMaterial.new()
		_sky_mat.shader = SKY_SHADER
		_env.sky.sky_material = _sky_mat
		_env.sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
		_env.sky.radiance_size = Sky.RADIANCE_SIZE_64
	_build_fireflies()
	dusk_started.connect(_shelter_villagers.bind(true))
	dawn_started.connect(_shelter_villagers.bind(false))
	_attach_player_lantern.call_deferred()
	_apply(true)


func _process(delta: float) -> void:
	if running:
		var before := time_of_day
		time_of_day += delta * 24.0 / day_length_seconds
		if time_of_day >= 24.0:
			time_of_day -= 24.0
			day_number += 1
		if before != time_of_day:
			_update_phase()
	_apply(false)
	_lamp_timer -= delta
	if _lamp_timer <= 0.0:
		_lamp_timer = 0.25
		_update_lamps()


## Jumps to a time of day (hours). Phase signals fire as if the time had been reached.
func set_time(hour: float) -> void:
	time_of_day = fposmod(hour, 24.0)
	_update_phase()
	_apply(true)
	_update_lamps()


func is_night() -> bool:
	return phase == Phase.NIGHT


func clock_text() -> String:
	var h := int(time_of_day)
	var m := int((time_of_day - float(h)) * 60.0)
	return "%s %d · %02d:%02d" % [Strings.DAY_WORD, day_number, h, m]


## 0 in full daylight, 1 in the dead of night (follows the sun's height).
func darkness() -> float:
	return 1.0 - smoothstep(-0.12, 0.22, _sun_direction().y)


# ------------------------------------------------------------------ phases ----

func _phase_for(hour: float) -> Phase:
	if hour >= NIGHT_HOUR or hour < DAWN_HOUR:
		return Phase.NIGHT
	if hour >= DUSK_HOUR:
		return Phase.DUSK
	if hour >= DAY_HOUR:
		return Phase.DAY
	return Phase.DAWN


func _update_phase() -> void:
	var now := _phase_for(time_of_day)
	if now == phase:
		return
	phase = now
	match now:
		Phase.DUSK:
			dusk_started.emit()
		Phase.NIGHT:
			night_number += 1
			night_started.emit(night_number)
		Phase.DAWN:
			dawn_started.emit()
		Phase.DAY:
			day_started.emit()


# ------------------------------------------------------------------ visuals ----

func _sun_direction() -> Vector3:
	# above the horizon from 06:00 (east) to 20:00 (west)
	var a := (time_of_day - SUNRISE) / (SUNSET - SUNRISE) * PI
	return Vector3(cos(a), sin(a) * 0.86, 0.42).normalized()


func _moon_direction() -> Vector3:
	# above the horizon for the ten hours between sunset and sunrise
	var night_len := 24.0 - (SUNSET - SUNRISE)
	var t := fposmod(time_of_day - SUNSET, 24.0)
	# the rest of the day it travels below the horizon again
	var a := t / night_len * PI if t <= night_len else PI + (t - night_len) / (24.0 - night_len) * PI
	return Vector3(cos(a) * 0.9, sin(a) * 0.8, -0.35).normalized()


func _sample(column: int, hour: float) -> Variant:
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if hour >= a[0] and hour <= b[0]:
			var t: float = (hour - a[0]) / (b[0] - a[0])
			return lerp(a[column], b[column], t)
	return KEYS[0][column]


func _inside() -> bool:
	if _interiors == null:
		_interiors = get_tree().get_first_node_in_group("interiors")
	return _interiors != null and _interiors.is_inside()


func _apply(_force: bool) -> void:
	var sun_dir := _sun_direction()
	var moon_dir := _moon_direction()
	var inside := _inside()

	if _sun != null and not inside:
		var elev := sun_dir.y
		var strength := smoothstep(-0.06, 0.22, elev)
		_sun.basis = Basis.looking_at(-sun_dir, Vector3.UP)
		_sun.light_energy = SUN_ENERGY * strength
		_sun.light_color = Color(1.0, 0.55, 0.3).lerp(Color(1.0, 0.97, 0.92), smoothstep(0.0, 0.5, elev))
		_sun.visible = strength > 0.01
	if _moon != null:
		var up := smoothstep(-0.02, 0.25, moon_dir.y) * darkness()
		_moon.basis = Basis.looking_at(-moon_dir, Vector3.UP)
		_moon.light_energy = MOON_ENERGY * up
		_moon.visible = up > 0.01 and not inside

	if _env == null or inside:
		return
	var top: Color = _sample(1, time_of_day)
	var horizon: Color = _sample(2, time_of_day)
	var fog: Color = _sample(3, time_of_day)
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("top_color", top)
		_sky_mat.set_shader_parameter("horizon_color", horizon)
		_sky_mat.set_shader_parameter("ground_color", horizon * 0.5)
		_sky_mat.set_shader_parameter("sun_dir", sun_dir)
		_sky_mat.set_shader_parameter("sun_color", Color(1.0, 0.6, 0.3).lerp(Color(1.0, 0.95, 0.8), smoothstep(0.0, 0.5, sun_dir.y)))
		_sky_mat.set_shader_parameter("moon_dir", moon_dir)
		_sky_mat.set_shader_parameter("star_amount", smoothstep(0.0, -0.25, sun_dir.y))
	_env.ambient_light_energy = _sample(4, time_of_day)
	_env.ambient_light_sky_contribution = _sample(5, time_of_day)
	_env.ambient_light_color = AMBIENT_COLOR
	_env.fog_light_color = fog
	_env.fog_density = lerpf(0.0006, 0.0011, darkness())


## Outdoor villagers go home at dusk (one by one) and come back at dawn.
func _shelter_villagers(on: bool) -> void:
	for v in get_tree().get_nodes_in_group("villagers"):
		var delay := randf_range(0.0, 14.0) if on else randf_range(0.0, 8.0)
		get_tree().create_timer(delay).timeout.connect(func():
			if is_instance_valid(v) and (phase == Phase.NIGHT or phase == Phase.DUSK) == on:
				v.set_sheltered(on))


# ------------------------------------------------------------------ lights ----

func _update_lamps() -> void:
	var level := darkness()
	if absf(level - _lamp_level) < 0.01 and not _lamps.is_empty():
		return
	_lamp_level = level
	_lamps.clear()
	for n in get_tree().get_nodes_in_group("night_lights"):
		if n is Light3D:
			_lamps.append(n)
	for lamp in _lamps:
		if not lamp.has_meta("base_energy"):
			lamp.set_meta("base_energy", lamp.light_energy)
		lamp.light_energy = float(lamp.get_meta("base_energy")) * level
		lamp.visible = level > 0.03
	if _fireflies != null:
		_fireflies.emitting = level > 0.6 and not _inside()
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D


func _attach_player_lantern() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null or _player.get_node_or_null("Lantern") != null:
		return
	var lamp := OmniLight3D.new()
	lamp.name = "Lantern"
	lamp.position = Vector3(0.0, 2.3, 0.0)
	lamp.light_color = Color(1.0, 0.78, 0.5)
	lamp.light_energy = 1.4
	lamp.omni_range = 11.0
	lamp.add_to_group("night_lights")
	_player.add_child(lamp)


func _build_fireflies() -> void:
	_fireflies = CPUParticles3D.new()
	_fireflies.name = "Fireflies"
	_fireflies.amount = 45
	_fireflies.lifetime = 6.0
	_fireflies.preprocess = 3.0
	_fireflies.emitting = false
	_fireflies.local_coords = false
	_fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_fireflies.emission_box_extents = Vector3(16.0, 2.0, 16.0)
	_fireflies.gravity = Vector3.ZERO
	_fireflies.direction = Vector3.UP
	_fireflies.spread = 180.0
	_fireflies.initial_velocity_min = 0.2
	_fireflies.initial_velocity_max = 0.7
	_fireflies.scale_amount_min = 0.5
	_fireflies.scale_amount_max = 1.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.85, 1.0, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 1.0, 0.35)
	mat.emission_energy_multiplier = 3.0
	quad.material = mat
	_fireflies.mesh = quad
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.5, Color(1, 1, 1, 1))
	_fireflies.color_ramp = fade
	add_child(_fireflies)
	_fireflies.top_level = true


func _physics_process(_delta: float) -> void:
	if _fireflies != null and _player != null:
		_fireflies.global_position = _player.global_position + Vector3(0, 1.5, 0)
