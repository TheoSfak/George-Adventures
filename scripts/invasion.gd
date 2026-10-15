class_name Invasion
extends Node
## The night invasion. When night falls the dead march on the village well in three
## waves from four gates. While invaders stand around the well the "village safety"
## drains; if it hits zero the village falls (George loses some gold). Killing every
## invader saves the village: XP, gold, potions and a golden chest in the square.
## At dawn whatever is left crumbles to dust.

signal updated(active: bool, wave: int, waves: int, alive: int, safety: float)
signal banner(text: String, seconds: float)
signal finished(success: bool)

const WELL := Vector3.ZERO
const GATE_DISTANCE := 150.0
const WELL_RADIUS := 14.0
const WAVES := 3
const WAVE_TIMEOUT := 70.0       # next wave comes after this long even if many are alive
const WAVE_CLEARED := 0.3        # ...or when this share of the wave is still alive
const FIRST_WAVE_DELAY := 4.0
const TICK := 0.5
const DRAIN := 0.15              # safety lost per invader at the well per tick
const GATES := [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)]

var active := false
var wave := 0
var safety := 100.0
var night := 0
var last_success := false
var waves_total := WAVES            # 4 on a boss night (the last wave is the Night Lord's)

var _alive: Array[Enemy] = []
var _wave_size := 0
var _wave_time := 0.0
var _tick := 0.0
var _wave_pending := false


func _ready() -> void:
	add_to_group("invasion")
	var daynight := get_parent().get_node_or_null("DayNight") as DayNight
	if daynight:
		daynight.night_started.connect(start)
		daynight.dusk_started.connect(func(): _say(Strings.DUSK_FALLS, 3.5))
		daynight.dawn_started.connect(_on_dawn)


func start(night_number: int) -> void:
	if active:
		return
	var interiors := get_tree().get_first_node_in_group("interiors")
	if interiors != null and interiors.in_region():      # George is in the Frontier: the village holds without him
		_say(Strings.INVASION_SKIPPED, 5.0)
		return
	active = true
	night = night_number
	wave = 0
	safety = 100.0
	last_success = false
	waves_total = InvasionBoss.total_waves(night, WAVES)
	_alive.clear()
	_wave_size = 0
	_say(Strings.INVASION_BANNER, 5.0)
	Sfx.ui("invasion_horn")
	for k in 3:
		get_tree().create_timer(0.8 + k * 3.2).timeout.connect(func(): Sfx.ui("bell_toll", -3.0))
	_emit()
	_wave_pending = true
	await get_tree().create_timer(FIRST_WAVE_DELAY).timeout
	_wave_pending = false
	if active:
		_spawn_guards()
		_spawn_wave()


## What the save game remembers of a night invasion in progress.
func save_data() -> Dictionary:
	if not active:
		return {"active": false}
	return {"active": true, "night": night, "wave": wave, "safety": snappedf(safety, 0.1)}


## Loading a save: an invasion that is running now is dropped quietly, and the saved one (if there was one and it is
## night) comes back: the wave that was in progress marches in again from the gates, the safety is as it was.
func load_data(d: Dictionary) -> void:
	if d.is_empty():
		return
	if active:
		_dismiss_guards()
		active = false
	for e in get_tree().get_nodes_in_group("invaders"):
		e.queue_free()
	_alive.clear()
	if not bool(d.get("active", false)):
		return
	var daynight := get_parent().get_node_or_null("DayNight") as DayNight
	if daynight == null or daynight.phase != DayNight.Phase.NIGHT:
		return
	await resume(int(d.get("night", 1)), int(d.get("wave", 1)), float(d.get("safety", 100.0)))


func resume(night_number: int, saved_wave: int, saved_safety: float) -> void:
	if active:
		return
	active = true
	night = night_number
	waves_total = InvasionBoss.total_waves(night, WAVES)
	wave = maxi(saved_wave - 1, 0)           # _spawn_wave() counts up to the saved wave again
	safety = saved_safety
	last_success = false
	_alive.clear()
	_wave_size = 0
	_say(Strings.INVASION_RESUMED, 4.0)
	Sfx.ui("invasion_horn")
	_emit()
	_wave_pending = true
	await get_tree().create_timer(FIRST_WAVE_DELAY).timeout
	_wave_pending = false
	if active:
		_spawn_guards()
		_spawn_wave()


func _process(delta: float) -> void:
	if not active or _wave_pending:
		return
	_wave_time += delta
	_tick += delta
	if _tick < TICK:
		return
	_tick = 0.0
	_alive = _alive.filter(func(e): return is_instance_valid(e) and not e.is_dead())
	for e in get_tree().get_nodes_in_group("invaders"):      # helpers a boss called also have to die
		if e is Enemy and not _alive.has(e):
			_alive.append(e)
	var near := 0
	for e in _alive:
		if _flat_distance(e.global_position, WELL) < WELL_RADIUS:
			near += 1
	safety = maxf(safety - DRAIN * near, 0.0)
	_emit()
	if safety <= 0.0:
		_fail()
		return
	if wave < waves_total:
		if float(_alive.size()) <= float(_wave_size) * WAVE_CLEARED or _wave_time >= WAVE_TIMEOUT:
			_spawn_wave()
	elif _alive.is_empty():
		_succeed()


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# ------------------------------------------------------------------ waves ----

func _spawn_wave() -> void:
	wave += 1
	_wave_time = 0.0
	var spawner := get_parent().get_node_or_null("Enemies")
	var player := get_tree().get_first_node_in_group("player") as Player
	if spawner == null:
		return
	var level: int = player.level if player else 1
	var pool := _kind_pool(level)
	var gates := GATES.duplicate()
	gates.shuffle()
	if InvasionBoss.is_boss_night(night) and wave == waves_total:
		_spawn_boss_wave(spawner, pool, gates)
		return
	_wave_size = clampi(3 + night * 2 + wave - 1, 4, 14)
	# every wave comes through two gates; the last wave through three
	var gate_count := 3 if wave == WAVES else 2
	for i in _wave_size:
		var kind: String = pool.pick_random()
		var gate: Vector3 = gates[i % gate_count]
		var side := Vector3(gate.z, 0, gate.x)
		var pos: Vector3 = gate * GATE_DISTANCE + side * randf_range(-10.0, 10.0)
		_alive.append(spawner.spawn_invader(kind, pos, WELL))
	if wave == WAVES and night >= 3:
		var gate: Vector3 = gates[0]
		_alive.append(spawner.spawn_invader("warlord", gate * GATE_DISTANCE, WELL))
		_wave_size += 1
	_say(Strings.INVASION_WAVE_BANNER % wave, 3.0)
	if wave > 1:
		Sfx.ui("wave_horn")
	_emit()


## The kinds an ordinary invader can be, by George's level.
func _kind_pool(level: int) -> Array:
	var pool := ["minion", "minion", "warrior", "warrior"]
	if level >= 3:
		pool.append_array(["rogue", "rogue"])
	if level >= 6:
		pool.append("mage")
	if level >= 9:
		pool.append("brute")
	return pool


## The last wave of a boss night: the Night Lord from one gate, an escort through two others.
func _spawn_boss_wave(spawner: Node, pool: Array, gates: Array) -> void:
	var tier := InvasionBoss.tier_of(night)
	var escort := InvasionBoss.escort_size(tier)
	var boss_gate: Vector3 = gates[0]
	var boss: Enemy = spawner.spawn_invader(InvasionBoss.KIND, boss_gate * GATE_DISTANCE, WELL,
			InvasionBoss.overrides(tier, spawner.KINDS[InvasionBoss.KIND]))
	_alive.append(boss)
	for i in escort:
		var kind: String = pool.pick_random()
		var gate: Vector3 = gates[1 + i % 2]
		var side := Vector3(gate.z, 0, gate.x)
		var pos: Vector3 = gate * GATE_DISTANCE + side * randf_range(-10.0, 10.0)
		_alive.append(spawner.spawn_invader(kind, pos, WELL))
	_wave_size = escort + 1
	_say(Strings.INVASION_BOSS_COMING, 4.0)
	Sfx.ui("wave_horn")
	Sfx.ui("boss_roar", -3.0)
	_emit()


# ----------------------------------------------------------------- results ----

## Captain Βασίλης sends his guards to the well: 2, plus one for each of his quests George finished.
func _spawn_guards() -> void:
	var count := 2
	for id in ["archers", "mages", "brutes", "totems"]:
		if Quests.state[id] == Quests.S.DONE:
			count += 1
	var holder := get_parent().get_node_or_null("Enemies")
	if holder == null:
		return
	for i in count:
		var a := TAU * float(i) / float(count) + 0.4
		var guard := Guard.new()
		guard.home = Vector3(cos(a) * 9.0, 0.0, sin(a) * 9.0)
		guard.position = guard.home + Vector3(0, 0.05, 0)
		guard.damage = 9.0 + float(count) * 1.2
		holder.add_child(guard)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_message(Strings.GUARDS_ARRIVE % count)


func _dismiss_guards() -> void:
	for g in get_tree().get_nodes_in_group("guards"):
		g.dismiss()


func _succeed() -> void:
	_dismiss_guards()
	active = false
	last_success = true
	var player := get_tree().get_first_node_in_group("player") as Player
	var boss_night := InvasionBoss.is_boss_night(night)
	var xp := 80 + 40 * night
	var gold := 40 + 25 * night
	if boss_night:
		xp += InvasionBoss.bonus_xp(InvasionBoss.tier_of(night))
	if player:
		player.gain_xp(xp)
		player.collect("gold", gold)
		player.collect("potion", 2 + night / 2)
		if boss_night:
			player.collect("power_potion", 1)
			player.collect("speed_potion", 1)
	_spawn_reward_chest(boss_night)
	Quests.report_defense()
	_say(Strings.INVASION_BOSS_WON if boss_night else Strings.INVASION_WON, 5.0)
	Sfx.ui("village_saved")
	_emit()
	finished.emit(true)


func _fail() -> void:
	_dismiss_guards()
	active = false
	last_success = false
	for e in get_tree().get_nodes_in_group("invaders"):      # includes the helpers of a boss
		e.dissolve()
	_alive.clear()
	var player := get_tree().get_first_node_in_group("player") as Player
	var lost := 0
	if player:
		lost = int(player.gold * 0.15)
		player.gold -= lost
		player.inventory_changed.emit(player.gold, player.potions)
	_say(Strings.INVASION_LOST, 6.0)
	Sfx.ui("village_fell")
	if lost > 0:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message(Strings.INVASION_LOST_GOLD % lost)
	_emit()
	finished.emit(false)


func _on_dawn() -> void:
	if not active:
		return
	_dismiss_guards()
	active = false
	for e in get_tree().get_nodes_in_group("invaders"):
		e.dissolve()
	_alive.clear()
	_say(Strings.INVASION_DAWN, 5.0)
	_emit()
	finished.emit(false)


func _spawn_reward_chest(boss_night: bool = false) -> void:
	var chests := get_parent().get_node_or_null("Village/Chests")
	var chest := Chest.new()
	chest.golden = true
	var share := 2 if boss_night else 1
	chest.gold_min = (30 + 15 * night) * share
	chest.gold_max = (50 + 25 * night) * share
	chest.potions = 1
	chest.position = Vector3(6.0, 0.05, 8.0)
	chest.rotation_degrees.y = 200.0
	(chests if chests else get_parent()).add_child(chest)


func _say(text: String, seconds: float) -> void:
	banner.emit(text, seconds)


func _emit() -> void:
	updated.emit(active, wave, waves_total, _alive.size(), safety)
