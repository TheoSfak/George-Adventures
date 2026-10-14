class_name RescueEvent
extends Node
## The "Σώσε τον Αντρέα" event. A few minutes into the game an alert announces that Andreas is
## surrounded by skeletons. His health runs down while the ring hits him; George must kill them all.
## Rules are in rescue_rules.gd. States: WAITING -> ALERT -> ACTIVE -> SAVED | FAILED.

const SITE := Vector2(-70.0, 65.0)                 # an open meadow south-west of the square
const SQUARE_SPOT := Vector3(-7.0, 0.05, 9.0)      # where Andreas stands after the reward
const QUEST_ID := "andreas"
const BAR_SIZE := Vector2i(96, 12)

var state := RescueRules.State.WAITING
var elapsed := 0.0
var limit := 240.0
var health := 1.0
var andreas: Node3D
var _bar: Sprite3D
var _besiegers: Array[Enemy] = []
var _rng := RandomNumberGenerator.new()
var _flinch_timer := 3.0
var _player: Player


func _ready() -> void:
	add_to_group("rescue")
	_rng.randomize()
	limit = RescueRules.pick_limit(_rng)
	Quests.quest_done.connect(_on_quest_done)


func reset() -> void:
	_cleanup()
	state = RescueRules.State.WAITING
	elapsed = 0.0
	health = 1.0
	limit = RescueRules.pick_limit(_rng)


func _process(delta: float) -> void:
	step(delta)


## Advances the event; tests call this directly with their own delta.
func step(delta: float) -> void:
	if not _find_player():
		return
	match state:
		RescueRules.State.WAITING:
			var ctx := _context()
			if RescueRules.is_free(ctx):
				elapsed += delta
			if RescueRules.should_fire(elapsed, limit, ctx):
				trigger_now()
		RescueRules.State.ACTIVE:
			_tick_active(delta)


func _find_player() -> bool:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	return _player != null


func _context() -> Dictionary:
	var interiors := get_tree().get_first_node_in_group("interiors")
	var invasion := get_tree().get_first_node_in_group("invasion")
	return {
		"busy": _player.busy,
		"dead": _player.is_dead,
		"indoors": interiors != null and interiors.is_inside(),
		"region": interiors != null and interiors.in_region(),
		"invasion": invasion != null and bool(invasion.get("active")),
	}


## Shows the alert (tests call this to skip the waiting).
func trigger_now() -> void:
	if state != RescueRules.State.WAITING or not _find_player():
		return
	state = RescueRules.State.ALERT
	_player.busy = true
	Sfx.ui("invasion_horn")
	var alert := RescueAlert.new()
	alert.accepted.connect(_on_alert_accepted)
	get_tree().get_first_node_in_group("hud").add_child(alert)


func _on_alert_accepted() -> void:
	Quests.start_event_quest(QUEST_ID)
	health = 1.0
	_start_scene(RescueRules.kinds_for(_player.level))
	await get_tree().create_timer(0.2).timeout
	var hud := get_tree().get_first_node_in_group("hud")
	if _player and not (hud and hud.is_dialogue_open()):
		_player.busy = false


func _start_scene(kinds: Array) -> void:
	state = RescueRules.State.ACTIVE
	_spawn_andreas(Vector3(SITE.x, 0.05, SITE.y))
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	_besiegers = spawner.spawn_besiegers(kinds, andreas.global_position, andreas)
	_update_bar()


func _spawn_andreas(pos: Vector3) -> void:
	var village := get_tree().get_first_node_in_group("hud").get_parent().get_node("Village")
	andreas = Npc.new()
	andreas.npc_id = "andreas"
	andreas.rest_yaw = PI
	andreas.position = pos
	village.get_node("Npcs").add_child(andreas)
	_bar = Sprite3D.new()
	_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bar.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_bar.shaded = false
	_bar.no_depth_test = true
	_bar.pixel_size = 0.02
	_bar.position = Vector3(0.0, 2.1, 0.0)
	andreas.add_child(_bar)


func _update_bar() -> void:
	if _bar != null:
		_bar.texture = FancyBar.texture(BAR_SIZE.x, BAR_SIZE.y, clampf(health, 0.0, 1.0), Color(0.55, 1.0, 0.5), Color(0.15, 0.6, 0.25))


func _tick_active(delta: float) -> void:
	_besiegers = _besiegers.filter(func(e): return is_instance_valid(e) and not e.is_dead())
	var besieging := 0
	for e in _besiegers:
		if e.is_besieging():
			besieging += 1
	var before := health
	health = RescueRules.drain(health, besieging, delta)
	if absf(before - health) > 0.004:
		_update_bar()
	_flinch_timer -= delta
	if besieging > 0 and _flinch_timer <= 0.0 and andreas != null:
		_flinch_timer = randf_range(2.5, 5.0)
		andreas.flinch()
	if health <= 0.0:
		_fail()
	elif _besiegers.is_empty():
		_succeed()


func _succeed() -> void:
	state = RescueRules.State.SAVED
	if _bar != null:
		_bar.visible = false
	Quests.report_rescue()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner(Strings.RESCUE_SAVED, 3.0)


func _fail() -> void:
	state = RescueRules.State.FAILED
	if _bar != null:
		_bar.visible = false
	if andreas != null:
		andreas.fall()
	Quests.fail_event_quest(QUEST_ID)
	Quests.message.emit(Strings.RESCUE_LOST)
	Sfx.ui("window_close")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_banner(Strings.RESCUE_LOST, 3.5)
	await get_tree().create_timer(20.0).timeout
	for e in _besiegers:
		if is_instance_valid(e):
			e.dissolve()
	_besiegers.clear()
	andreas = null


func _on_quest_done(id: String) -> void:
	if id != QUEST_ID or andreas == null:
		return
	andreas.position = SQUARE_SPOT           # Andreas goes back to the village


func _cleanup() -> void:
	for e in _besiegers:
		if is_instance_valid(e):
			e.queue_free()
	_besiegers.clear()
	if andreas != null and is_instance_valid(andreas):
		andreas.queue_free()
	andreas = null
	_bar = null


# ---------------------------------------------------------------- map & save ----

## Where Andreas is in danger, for the map markers (ZERO when there is no rescue going on).
func andreas_position() -> Vector3:
	if state == RescueRules.State.ACTIVE and andreas != null and is_instance_valid(andreas):
		return andreas.global_position
	return Vector3.ZERO


func save_data() -> Dictionary:
	return {"state": int(state), "elapsed": elapsed, "limit": limit, "health": health, "besiegers": _besiegers.size()}


## Puts a loaded save into the running game (the world already exists).
func load_data(d: Dictionary) -> void:
	_find_player()
	_cleanup()
	state = int(d.get("state", RescueRules.State.WAITING)) as RescueRules.State
	elapsed = float(d.get("elapsed", 0.0))
	limit = float(d.get("limit", limit))
	health = float(d.get("health", 1.0))
	match state:
		RescueRules.State.ALERT:
			state = RescueRules.State.WAITING            # the alert was never answered: show it again
		RescueRules.State.ACTIVE:
			var n := clampi(int(d.get("besiegers", RescueRules.BESIEGERS)), 1, RescueRules.BESIEGERS)
			_start_scene(RescueRules.kinds_for(_player.level if _player else 1).slice(0, n))
		RescueRules.State.SAVED:
			var done: bool = Quests.state[QUEST_ID] == Quests.S.DONE
			_spawn_andreas(SQUARE_SPOT if done else Vector3(SITE.x, 0.05, SITE.y))
			_bar.visible = false
