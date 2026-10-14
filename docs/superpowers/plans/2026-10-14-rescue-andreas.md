# Rescue Andreas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A few minutes into a game a window announces that Andreas is surrounded by skeletons; George must kill them before Andreas' health runs out.

**Architecture:** Pure rules in `RescueRules` (timer, drain, besieger mix). A `RescueEvent` node in `main.tscn` runs the state machine (WAITING → ALERT → ACTIVE → SAVED/FAILED), shows the alert (`RescueAlert`), spawns Andreas (an `Npc`) and six besiegers (`Enemy.besiege_target`, a new idle stance). The quest `andreas` is an "event" quest that starts ACTIVE through `Quests.start_event_quest`.

**Tech Stack:** Godot 4.7, GDScript, headless `--script` test drivers in `tools/`.

## Global Constraints
- All in-game text Greek; code, comments, file names English. Edit Greek files with the Edit/Write tools.
- Alert text exactly: `Ο φίλος σου ο Αντρέας είναι σε κίνδυνο, ακούω τις φωνές του. Γρήγορα οι σκελετοί τον έχουν περικυκλώσει! Σώσε τον!`
- Constants: `MIN_DELAY` 180 s, `MAX_DELAY` 300 s, `FULL_TIME` 150 s, six besiegers, site `(-70, 65)`, reward 250 XP / 120 gold / 2 potions.
- Tests that touch `SaveGame.save()` back up and restore `savegame.json` and `savegame.bak`. Do not type-reference `RescueEvent`, `Npc`, `Quests` classes in `--script` tests: use `load()` / groups. `RescueRules` has no scene access and may be referenced.
- No AI attribution lines in commit messages (user's global rule).
- Run tests: `godot --path . --headless --script tools/<name>.gd`. After adding a `class_name`, run `godot --headless --import` once.

## File Structure
- Create `scripts/rescue_rules.gd` — pure rules.
- Create `scripts/rescue.gd` (class `RescueEvent`) — the node/state machine.
- Create `scripts/rescue_alert.gd` (class `RescueAlert`) — the modal card.
- Modify `scripts/quest_data.gd` (quest `andreas`, NPC `andreas`, objective doc), `scripts/quests.gd` (FAILED, event quests, `report_rescue`), `scripts/strings_el.gd`, `scripts/enemy.gd` (besiege), `scripts/enemies.gd` (`spawn_besiegers`), `scripts/npc.gd` (`flinch`, `fall`), `scripts/minimap.gd` (marker), `scripts/save_game.gd`, `scripts/game_menu.gd` (reset), `scripts/village.gd` (occupy site), `scenes/main.tscn` (node).
- Create tests `tools/rescue_rules_test.gd`, `tools/rescue_flow_test.gd`, `tools/rescueshot.gd`.

---

### Task 1: RescueRules (pure rules)

**Files:** Create `scripts/rescue_rules.gd`, `tools/rescue_rules_test.gd`.

**Produces:** `RescueRules.State {WAITING, ALERT, ACTIVE, SAVED, FAILED}`; consts `MIN_DELAY`, `MAX_DELAY`, `FULL_TIME`, `BESIEGERS`; `pick_limit(rng: RandomNumberGenerator) -> float`; `is_free(ctx: Dictionary) -> bool`; `should_fire(elapsed: float, limit: float, ctx: Dictionary) -> bool`; `drain(health: float, besieging: int, delta: float) -> float`; `kinds_for(level: int) -> Array[String]`. `ctx` keys: `busy`, `indoors`, `region`, `dead`, `invasion` (bool each).

- [ ] **Step 1: Write the failing test** `tools/rescue_rules_test.gd`

```gdscript
extends SceneTree
## Rescue rules (timer, drain, besieger mix):
##   godot --path . --headless --script tools/rescue_rules_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ok := true
	for i in 200:
		var l := RescueRules.pick_limit(rng)
		ok = ok and l >= RescueRules.MIN_DELAY and l <= RescueRules.MAX_DELAY
	check("limit always in 180..300", ok)
	var free := {"busy": false, "indoors": false, "region": false, "dead": false, "invasion": false}
	check("free outdoors", RescueRules.is_free(free))
	for k in ["busy", "indoors", "region", "dead"]:
		var c := free.duplicate()
		c[k] = true
		check("not free when %s" % k, not RescueRules.is_free(c))
	check("fires at the limit", RescueRules.should_fire(200.0, 200.0, free))
	check("not before the limit", not RescueRules.should_fire(199.0, 200.0, free))
	var inv := free.duplicate()
	inv["invasion"] = true
	check("not during an invasion", not RescueRules.should_fire(300.0, 200.0, inv))
	check("full time with six: 150 s to zero", is_equal_approx(RescueRules.drain(1.0, 6, 150.0), 0.0))
	check("three besiegers drain half as fast", is_equal_approx(RescueRules.drain(1.0, 3, 75.0), 0.5))
	check("no besiegers, no drain", is_equal_approx(RescueRules.drain(0.7, 0, 100.0), 0.7))
	check("never below zero", RescueRules.drain(0.1, 6, 100.0) == 0.0)
	check("level 1 mix: 4 minion 2 warrior", RescueRules.kinds_for(1).count("minion") == 4 and RescueRules.kinds_for(1).count("warrior") == 2)
	check("level 5 has an archer", RescueRules.kinds_for(5).has("rogue"))
	check("level 10 has a brute", RescueRules.kinds_for(10).has("brute"))
	for lv in [1, 5, 10, 20]:
		check("always six at level %d" % lv, RescueRules.kinds_for(lv).size() == RescueRules.BESIEGERS)
	quit(1 if failed else 0)
```

- [ ] **Step 2:** Run it; expect a parse error (class missing).
- [ ] **Step 3: Implement** `scripts/rescue_rules.gd`

```gdscript
class_name RescueRules
## Pure rules of the "Σώσε τον Αντρέα" event (no scene access): when the alert fires, how fast
## Andreas loses health, and which skeletons surround him.

enum State { WAITING, ALERT, ACTIVE, SAVED, FAILED }

const MIN_DELAY := 180.0      # play time before the alert, seconds
const MAX_DELAY := 300.0
const FULL_TIME := 150.0      # seconds until Andreas dies with all besiegers alive
const BESIEGERS := 6


static func pick_limit(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(MIN_DELAY, MAX_DELAY)


## True when the game clock of the event may run: George is outdoors in the village and in control.
static func is_free(ctx: Dictionary) -> bool:
	return not (ctx.get("busy", false) or ctx.get("indoors", false) or ctx.get("region", false) or ctx.get("dead", false))


static func should_fire(elapsed: float, limit: float, ctx: Dictionary) -> bool:
	return elapsed >= limit and is_free(ctx) and not ctx.get("invasion", false)


## Andreas' health (0..1) after `delta` seconds with `besieging` skeletons hitting him.
static func drain(health: float, besieging: int, delta: float) -> float:
	var rate := float(besieging) / float(BESIEGERS) / FULL_TIME
	return maxf(health - rate * delta, 0.0)


static func kinds_for(level: int) -> Array[String]:
	var kinds: Array[String] = ["warrior", "warrior"]
	if level >= 10:
		kinds.append_array(["minion", "minion", "rogue", "brute"])
	elif level >= 5:
		kinds.append_array(["minion", "minion", "minion", "rogue"])
	else:
		kinds.append_array(["minion", "minion", "minion", "minion"])
	return kinds
```

- [ ] **Step 4:** `godot --headless --import`, run the test; expect all PASS, exit 0.
- [ ] **Step 5: Commit** `git add scripts/rescue_rules.gd tools/rescue_rules_test.gd && git commit -m "Rescue: pure rules and test"`

---

### Task 2: Quest plumbing (event quest, FAILED, rescue objective, strings)

**Files:** Modify `scripts/quest_data.gd`, `scripts/quests.gd`, `scripts/strings_el.gd`.

**Produces:** `Quests.S.FAILED`; `Quests.start_event_quest(id)`; `Quests.fail_event_quest(id)`; `Quests.report_rescue()`; quest `"andreas"` with `"event": true`; NPC `"andreas"`; Strings `RESCUE_TITLE`, `RESCUE_TEXT`, `RESCUE_BUTTON`, `RESCUE_LOST`, `RESCUE_SAVED_BANNER`.

- [ ] **Step 1:** In `quests.gd`: add `FAILED` at the END of `enum S`; in `_refresh_availability` add `if QuestData.QUESTS[id].get("event", false): continue` right after the LOCKED check; add after `report_reach`:

```gdscript
## The rescue of Andreas succeeded (all besiegers dead while he lives).
func report_rescue() -> void:
	for id in QuestData.QUESTS:
		if state[id] != S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if o["type"] == "rescue" and progress[id][i] < o["count"]:
				progress[id][i] += 1
		_check_ready(id)
	changed.emit()


## Quests that nobody hands out: an event starts them.
func start_event_quest(id: String) -> void:
	if state[id] != S.LOCKED and state[id] != S.AVAILABLE:
		return
	state[id] = S.ACTIVE
	message.emit(Strings.QUEST_NEW % QuestData.QUESTS[id]["title"])
	Sfx.ui("quest_new")
	changed.emit()


func fail_event_quest(id: String) -> void:
	if state[id] != S.ACTIVE and state[id] != S.READY:
		return
	state[id] = S.FAILED
	changed.emit()
```

- [ ] **Step 2:** In `quest_data.gd` doc header add the line `##   {"type": "rescue", "count": 1, "text": "..."}                  (event quest: Quests.report_rescue)` and `"event": true` explanation. Add NPC (after `manolis`/before closing, copy the dict style):

```gdscript
	# The friend of George: appears at the rescue event (see rescue.gd), later stands in the square.
	"andreas": {
		"name": "Αντρέας",
		"model": "res://assets/characters/Rogue_Hooded.glb",
		"show": [],
		"idle": [
			"Χρωστάω τη ζωή μου σε σένα, Γιώργο. Όποτε με χρειαστείς, εδώ θα είμαι.",
			"Δεν ξαναπάω μόνος μου στο δάσος, στο υπόσχομαι!",
			"Οι σκελετοί αυτοί δεν σταματούν ποτέ. Πρόσεχε, φίλε.",
		],
	},
```
Check how `show` is used (WEAPON_NODES visibility: `n.name in data["show"]`) → empty array hides all weapons. Good.

Add quest at the end of QUESTS (before closing brace, after `f_return`; view file end first to place):

```gdscript
	# ------------------------------------------------ Event: the friend in danger ----
	"andreas": {
		"title": "Σώσε τον Αντρέα",
		"event": true,
		"giver": "andreas",
		"turn_in": "andreas",
		"requires": [],
		"objectives": [
			{"type": "rescue", "count": 1, "text": "Σώσε τον Αντρέα από τους σκελετούς"},
		],
		"offer": [
			"Γιώργο, βοήθεια! Οι σκελετοί με περικύκλωσαν!",
		],
		"progress": [
			"Μη στέκεσαι, Γιώργο! Σκότωσέ τους πριν με φτάσουν!",
		],
		"complete": [
			"Γιώργο! Ήρθες την τελευταία στιγμή… νόμιζα ότι ήταν το τέλος μου.",
			"Βγήκα να μαζέψω βότανα και ξαφνικά ήταν παντού. Σου χρωστάω τη ζωή μου.",
			"Πάρε αυτά, είναι το λιγότερο που μπορώ να κάνω. Θα σε περιμένω στην πλατεία!",
		],
		"reward": {"xp": 250, "gold": 120, "potions": 2},
	},
```

- [ ] **Step 3:** `strings_el.gd` add near `QUEST_NEW`:

```gdscript
const RESCUE_TITLE := "Κίνδυνος!"
const RESCUE_TEXT := "Ο φίλος σου ο Αντρέας είναι σε κίνδυνο, ακούω τις φωνές του. Γρήγορα οι σκελετοί τον έχουν περικυκλώσει! Σώσε τον!"
const RESCUE_BUTTON := "Πάω!"
const RESCUE_LOST := "Ο Αντρέας χάθηκε…"
const RESCUE_SAVED := "Ο Αντρέας σώθηκε!"
```

- [ ] **Step 4:** Add a check script `tools/rescue_quest_test.gd` (headless) that loads main, asserts: `Quests.state["andreas"] == LOCKED/not AVAILABLE` after reset; `start_event_quest` → ACTIVE; `report_rescue` → READY; `dialogue_for("andreas")` kind "complete"; `finish_dialogue` → DONE and gold +120; second quest `fail_event_quest` → FAILED; tracker excludes it. Use `var q = root.get_node("/root/Quests")` and `q.S`. Run it, expect all PASS. Run `questtest` is windowed — instead run headless `part3_data_test` and `gender_test` to catch data-shape regressions.
- [ ] **Step 5: Commit** `Rescue: event quest plumbing`.

---

### Task 3: Besiege stance, spawner, NPC reactions

**Files:** Modify `scripts/enemy.gd`, `scripts/enemies.gd`, `scripts/npc.gd`.

**Produces:** `Enemy.besiege_target: Node3D`, `Enemy.is_besieging() -> bool`; group `besiegers`; `Enemies.spawn_besiegers(kinds: Array, center: Vector3, target: Node3D) -> Array[Enemy]`; `Npc.flinch()`, `Npc.fall()`.

- [ ] **Step 1: enemy.gd** — add `var besiege_target: Node3D = null` and `var _besiege_swing := 0.0` next to `_enraged`; in `_patrol`, directly after the `_can_see_player()` block insert:

```gdscript
	if besiege_target != null and is_instance_valid(besiege_target):
		return _besiege(delta)
```
and add:

```gdscript
## A skeleton of the ring around a victim (the rescue event): it hits the air in front of the target
## until George comes into view. The victim's health is drained by rescue.gd.
func is_besieging() -> bool:
	return _state == State.PATROL and besiege_target != null and is_instance_valid(besiege_target)


func _besiege(delta: float) -> Vector3:
	var to_target := _flat(besiege_target.global_position - global_position)
	_face(to_target, delta)
	if to_target.length() > 5.5:                    # pulled away by a chase: walk back to the ring
		_play("Walking_D_Skeletons", 0.2)
		return _detour(to_target.normalized()) * patrol_speed
	_besiege_swing -= delta
	if _cooldown <= 0.0:
		_cooldown = attack_cooldown * randf_range(0.9, 1.4)
		_besiege_swing = 0.9
		_play(shoot_anim if ranged else (attack_anim if attack_anim != "" else ATTACKS.pick_random()), 0.08, true)
		if not ranged:
			Sfx.play("skel_attack", global_position)
	elif _besiege_swing <= 0.0:
		_play("Idle", 0.2)
	return Vector3.ZERO
```
In `_die` and `dissolve` add `remove_from_group("besiegers")` beside the other `remove_from_group` calls.

- [ ] **Step 2: enemies.gd** add after `spawn_summon`:

```gdscript
## The ring of skeletons around a victim (rescue event). They never respawn; XP, loot and
## quest kills work as for any skeleton.
func spawn_besiegers(kinds: Array, center: Vector3, target: Node3D) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for i in kinds.size():
		var angle := TAU * float(i) / float(kinds.size())
		var enemy := _make(kinds[i], center + Vector3(cos(angle), 0.0, sin(angle)) * 4.0)
		enemy.besiege_target = target
		enemy.patrol_radius = 0.5
		enemy.died.connect(_on_enemy_died.bind(-1))
		add_child(enemy)
		enemy.add_to_group("besiegers")
		out.append(enemy)
	return out
```
Note `_make` calls `_free_spot`, which needs the physics space: callers spawn long after startup, fine.

- [ ] **Step 3: npc.gd** add:

```gdscript
## A short hurt reaction, then back to idle (Andreas while the skeletons hit him).
func flinch() -> void:
	if _anim and _anim.has_animation("Hit_A"):
		_anim.play("Hit_A", 0.1)
		_anim.animation_finished.connect(func(_n): if is_inside_tree(): _anim.play("Idle", 0.2), CONNECT_ONE_SHOT)


## The NPC dies: no more talking, falls, sinks into the ground and disappears.
func fall() -> void:
	remove_from_group("interactables")
	remove_from_group("npcs")
	_marker.visible = false
	if _anim and _anim.has_animation("Death_A"):
		_anim.play("Death_A", 0.1)
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(self, "position:y", position.y - 2.0, 1.5)
	tween.tween_callback(queue_free)
```
(`_marker` is hidden by `_update_marker` too, so also add an early `if not is_in_group("npcs"): return` in `_update_marker`... simpler: in `fall` disconnect `Quests.changed.disconnect(_update_marker)`.) Use disconnect.

Also `fall()` must stop `_process` turning: set `set_process(false)`.

- [ ] **Step 4:** headless sanity: write the flow test in Task 5; for now just `godot --headless --import` and run `guard_snag_test` + `part3_mobs_test` to check `enemy.gd` still parses and behaves. Expect PASS.
- [ ] **Step 5: Commit** `Rescue: besiege stance, spawner, NPC reactions`.

---

### Task 4: RescueEvent node, alert card, wiring

**Files:** Create `scripts/rescue_alert.gd`, `scripts/rescue.gd`; modify `scenes/main.tscn`, `scripts/village.gd`, `scripts/minimap.gd`, `scripts/save_game.gd`, `scripts/game_menu.gd`.

**Produces:** `RescueEvent` (group `rescue`) with `state`, `elapsed`, `limit`, `health`, `andreas: Node3D`, `SITE: Vector2`, `SQUARE_SPOT: Vector3`, `andreas_position() -> Vector3` (ZERO if none), `save_data() -> Dictionary`, `load_data(d)`, `reset()`, `trigger_now()` (tests), `step(delta)` (tests drive time; `_process` calls it).

- [ ] **Step 1: rescue_alert.gd**

```gdscript
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
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(0.92))
	panel.custom_minimum_size = Vector2(560, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = Strings.RESCUE_TITLE
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var text := Label.new()
	text.text = Strings.RESCUE_TEXT
	text.add_theme_font_size_override("font_size", 21)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(520, 0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	var button := UiKit.button(Strings.RESCUE_BUTTON, _accept, 160.0, 22)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(button)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_opened_at = Time.get_ticks_msec() / 1000.0


func _input(event: InputEvent) -> void:
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
```
(The 0.4 s guard stops the key the player is already pressing from closing it.)

- [ ] **Step 2: rescue.gd**

```gdscript
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
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
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
	if state != RescueRules.State.WAITING:
		return
	state = RescueRules.State.ALERT
	_player.busy = true
	Sfx.ui("rescue_alert")
	var alert := RescueAlert.new()
	alert.accepted.connect(_on_alert_accepted)
	get_tree().get_first_node_in_group("hud").add_child(alert)


func _on_alert_accepted() -> void:
	await get_tree().create_timer(0.2).timeout
	if _player and not (get_tree().get_first_node_in_group("hud").is_dialogue_open()):
		_player.busy = false
	Quests.start_event_quest(QUEST_ID)
	health = 1.0
	_start_scene(RescueRules.kinds_for(_player.level))


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
	if besieging > 0 and _flinch_timer <= 0.0 and andreas != null and andreas.has_method("flinch"):
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
	Sfx.ui("quest_fail")
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
			var kinds := RescueRules.kinds_for(_player.level if _player else 1).slice(0, n)
			_start_scene(kinds)
		RescueRules.State.SAVED:
			var done: bool = Quests.state[QUEST_ID] == Quests.S.DONE
			_spawn_andreas(SQUARE_SPOT if done else Vector3(SITE.x, 0.05, SITE.y))
			_bar.visible = false
```

Notes for the implementer: `_player` may be null in `load_data` if `step` has not run; set it at the top of `load_data` with `_player = get_tree().get_first_node_in_group("player") as Player`. Quests.S values compared through `Quests.S.DONE` (fine in-game; tests use load/get_node).

- [ ] **Step 3: Wiring**
  - `scenes/main.tscn`: add `[ext_resource type="Script" path="res://scripts/rescue.gd" id="11_rescue"]`, bump `load_steps` to 15, and append `[node name="Rescue" type="Node" parent="."]` with `script = ExtResource("11_rescue")`.
  - `village.gd` `_build_stable` neighbour (after `_build_stable()` call in `_ready`): add `_occupy(RescueEvent.SITE.x, RescueEvent.SITE.y, 14.0)` before `_build_scatter()`.
  - `game_menu.gd` `_new_game`: after `Quests.reset()` add `get_tree().call_group("rescue", "reset")`.
  - `save_game.gd` `save()`: before `data` is built get `var rescue := tree.get_first_node_in_group("rescue")`; add to the dictionary `"rescue": rescue.save_data() if rescue else {},`. In `apply()` after the quests are applied (`Quests.changed.emit()`): `var rescue := tree.get_first_node_in_group("rescue"); if rescue != null: rescue.load_data(d.get("rescue", {}))`. Update the header comment ("Saved: ... the rescue event").
  - `minimap.gd` `_draw_quest_markers` match: add `"rescue":` branch: `var r := get_tree().get_first_node_in_group("rescue"); if r != null and r.andreas_position() != Vector3.ZERO: _diamond(r.andreas_position()); if big: _label(_to_map(r.andreas_position()) + Vector2(0, -16), "Αντρέας")`.
  - Sounds: `Sfx.ui("rescue_alert")` and `Sfx.ui("quest_fail")` must exist. Check `sfx_ids.gd`; if missing, reuse `"invasion_horn"` and `"quest_ready"`-like existing ids instead of generating audio (do not add synthesis work): use `Sfx.ui("invasion_horn")` for the alert and `Sfx.ui("window_close")` for the loss.

- [ ] **Step 4:** `godot --headless --import`; run `rescue_rules_test` and `rescue_quest_test`; then `godot --path . --headless --script tools/savetest.gd`; expect PASS.
- [ ] **Step 5: Commit** `Rescue: event node, alert card, map marker, save`.

---

### Task 5: Flow test, screenshots, docs

**Files:** Create `tools/rescue_flow_test.gd`, `tools/rescueshot.gd`; modify `CLAUDE.md`, `CHANGELOG.md`.

- [ ] **Step 1: rescue_flow_test.gd** (headless; same header/backup pattern as `tools/kitchen_test.gd`). Steps, each a `check(...)`:
  1. Load main, wait 3 s, get `r = get_first_node_in_group("rescue")`, `p = player`, `q = root.get_node("/root/Quests")`. `p._invulnerable = 99999.0`. `r.set_process(false)`.
  2. Initially `r.state == 0`. `r.step(r.limit - 1.0)` with player busy false → still WAITING. Set `p.busy = true`; `r.step(500)`; still WAITING and elapsed unchanged (not free). `p.busy = false; r.step(2.0)` → state ALERT (1), `get_nodes_in_group("hud")[0]` has a `RescueAlert` child (find by `get_script().get_global_name()`), `p.busy` true.
  3. Call `alert._accept()`; `await create_timer(0.5).timeout`; state ACTIVE (2), `q.state["andreas"] == 2`, 6 nodes in group `besiegers`, `r.andreas` valid and at distance < 10 from `(-70, 65)`.
  4. Drain: `r.step(30.0)` → health < 0.85 and > 0.7 (6 besieging at 30 s: 0.8; besiegers must be PATROL state – they may start chasing if George is within 14 m; the player starts at (0,16), 100 m away).
  5. Success: kill every besieger with `e.take_damage(9999.0, e.global_position + Vector3.RIGHT)`, `await create_timer(0.3)`, `r.step(0.1)` → state SAVED (3), `q.state["andreas"] == 3` (READY). Hand in: `var plan = q.dialogue_for("andreas")`, kind "complete", `q.finish_dialogue(plan)` → state DONE (4), gold rose by 120, `r.andreas.position` equals `SQUARE_SPOT`.
  6. Failure: `r.reset()`, `q.state["andreas"] = 0` (LOCKED... use `q.reset()` then `r.reset()`), `r.trigger_now()`; accept; `r.step(200.0)` in 10 s slices → state FAILED (4 in `RescueState`: WAITING 0, ALERT 1, ACTIVE 2, SAVED 3, FAILED 4), `q.state["andreas"] == 5`, no `andreas` after 20 s (`await create_timer(21)`; use a shorter wait by setting nothing: just await 21 s).
  7. Save round trip in ACTIVE: `r.reset(); q.reset(); r.trigger_now(); accept; r.step(30.0)`; `save.save()`; remember `health`; `r.reset()`; `save.apply(save.read())`; state ACTIVE, health within 0.01, besiegers count 6. Restore `savegame.json`/`.bak` at the end.
  Quit with exit code per `failed`.

- [ ] **Step 2:** Run it, fix until all PASS.
- [ ] **Step 3: rescueshot.gd** (windowed, copy the setup of `tools/propshot.gd` or `mountshot.gd`: read one first): trigger the alert and screenshot it, accept, teleport George to (-50, 65) facing the site, screenshot the ring and the bar, then step 60 s and screenshot again. Run: `godot --path . --resolution 1280x720 --script tools/rescueshot.gd -- tools/_shots`. View the PNGs with the Read tool; verify alert text readable, ring visible, bar above Andreas, no clipping into trees. Adjust `SITE` if it clips (and update the spec).
- [ ] **Step 4: Regression:** `godot --headless --import`, then headless: `rescue_rules_test`, `rescue_quest_test`, `rescue_flow_test`, `savetest`, `part3_data_test`, `gender_test`, `guard_snag_test`, `part3_mobs_test`, `invasion_boss_flow_test`; windowed: `minimaptest`. All must pass.
- [ ] **Step 5: Docs:** add a `**Rescue event**` paragraph to `CLAUDE.md` (files, constants, tests) and a `## Unreleased` entry in `CHANGELOG.md`. Do not bump the version or release unless asked.
- [ ] **Step 6: Commit** `Rescue: tests, screenshots, docs`.

## Self-review
- Spec coverage: trigger/conditions/once-per-game (Tasks 1, 4), window (4), quest (2), scene and drain (3, 4), outcomes (4), save (4), tests (1, 5). "George dies while ACTIVE: timer keeps running" — nothing pauses `_tick_active`. "Invaders do not target Andreas" — nothing links them.
- Names consistent: `RescueEvent`, `RescueRules`, `RescueAlert`, `spawn_besiegers`, `is_besieging`, `report_rescue`, `start_event_quest`, `fail_event_quest`, `andreas_position`, `save_data`/`load_data`.
