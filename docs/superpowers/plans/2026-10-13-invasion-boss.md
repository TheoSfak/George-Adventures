# Invasion Boss Nights Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On night 5 and every 5th night after it, the night invasion ends with a fourth wave: a named boss, "Άρχοντας της Νύχτας", with an escort, that gets stronger every tier.

**Architecture:** The rules (which nights, tier scaling, escort size, numerals, bonus XP) live in a new pure helper class `InvasionBoss` (no scene or autoload access, so tests can type-reference it). The boss is a new `night_lord` entry in `Enemies.KINDS` that reuses the existing summon and enrage code of the necromancer and Malakar; `Enemies.spawn_invader` gets a stat-override argument and `Enemies.spawn_summon` makes the helpers of an invader invaders too. `Invasion` gets a `waves_total` (3, or 4 on a boss night), spawns the boss wave when wave 3 is cleared, merges unlisted invaders (helpers) into its alive list, and gives boss rewards.

**Tech Stack:** Godot 4.7 GDScript (tabs), headless `--script` test drivers in `tools/`.

## Global Constraints

- All in-game text is Greek (strings in `scripts/strings_el.gd`, names in `scripts/enemies.gd`); code, comments and file names are English.
- GDScript files use TAB indentation. Write/Edit Greek text with the Write/Edit tools (UTF-8), never with a shell heredoc.
- Boss on night 5, then every 5th night (10, 15, ...); other nights unchanged. The boss arrives as its own wave 4 after waves 1 to 3. Same boss each tier, stronger.
- Tier scaling: health and damage times `1 + 0.4 * (tier - 1)`; `summon_max` plus `tier - 1`, capped at 8; escort `4 + 2 * tier` skeletons; bonus XP `200 * tier`; name gets a Roman numeral suffix from tier 2 ("Άρχοντας της Νύχτας II").
- Boss night rewards: normal rewards, plus the bonus XP, one power potion, one speed potion, and a golden chest with double gold. Banner "Ο Άρχοντας της Νύχτας έπεσε! Το χωριό σώθηκε!".
- Out of scope: saving an invasion in progress, different bosses per tier, themed nights, new music.
- In `--script` tests never type-reference `Invasion` (its script mentions `Quests`): use `get_first_node_in_group("invasion")` untyped. `InvasionBoss`, `Player`, `DayNight`, `Enemy`, `Strings` are safe.
- Headless tests are run with `timeout` (a script error in a coroutine leaves Godot hanging). Never kill Theodore's editor/game processes (`--editor`, `--remote-debug`).
- Git: Theodore is the sole author. NO `Co-Authored-By` or "Generated with" lines in commit messages. Commit on a feature branch `feature/invasion-boss`; do not push, tag or release (only when he asks).
- After adding a `class_name` script run `godot --headless --import` once. Commit the generated `.uid` files.

## File Structure

- Create `scripts/invasion_boss.gd` (`class_name InvasionBoss`): the pure rules.
- Create `tools/invasion_boss_test.gd`: headless test of the pure rules.
- Create `tools/invasion_boss_world_test.gd`: headless test of the `night_lord` kind, `spawn_invader` overrides and invader helpers.
- Create `tools/invasion_boss_flow_test.gd`: headless test of a whole boss night.
- Create `tools/bossnighttest.gd`: windowed screenshot driver.
- Modify `scripts/strings_el.gd` (3 strings), `scripts/enemies.gd` (kind, BOSSES, `spawn_invader`, `spawn_summon`), `scripts/enemy.gd` (summon passes `self`, roar, enrage text), `scripts/minimap.gd`, `scripts/sound_manager.gd` (boss lists), `scripts/invasion.gd` (flow, rewards).
- Modify `CLAUDE.md` and `HANDOVER.md` (docs).

---

### Task 1: The pure rules (`InvasionBoss`) and the Greek strings

**Files:**
- Create: `scripts/invasion_boss.gd`
- Create: `tools/invasion_boss_test.gd`
- Modify: `scripts/strings_el.gd` (after the line `const INVASION_WON := "Το χωριό σώθηκε!"`)

**Interfaces:**
- Produces (all `static`, on `class_name InvasionBoss`):
  - consts `KIND := "night_lord"`, `EVERY := 5`
  - `is_boss_night(night: int) -> bool`
  - `tier_of(night: int) -> int`
  - `total_waves(night: int, base: int) -> int`
  - `factor(tier: int) -> float`
  - `summon_cap(base: int, tier: int) -> int`
  - `escort_size(tier: int) -> int`
  - `bonus_xp(tier: int) -> int`
  - `roman(n: int) -> String`
  - `title(base_name: String, tier: int) -> String`
  - `overrides(tier: int, base: Dictionary) -> Dictionary` with keys `max_health`, `attack_damage`, `summon_max`, `display_name`
- Produces (on `Strings`): `INVASION_BOSS_COMING`, `INVASION_BOSS_WON`, `NIGHT_LORD_ENRAGE`.

- [ ] **Step 1: Write the failing test** — create `tools/invasion_boss_test.gd`:

```gdscript
extends SceneTree
## The rules of the invasion boss nights (no world needed):
##   godot --path . --headless --script tools/invasion_boss_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func approx(a: float, b: float) -> bool:
	return absf(a - b) < 0.001


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	check("night 0 is no boss night", not InvasionBoss.is_boss_night(0))
	check("night 4 is no boss night", not InvasionBoss.is_boss_night(4))
	check("night 5 is a boss night", InvasionBoss.is_boss_night(5))
	check("night 6 is no boss night", not InvasionBoss.is_boss_night(6))
	check("night 10 and 15 are boss nights", InvasionBoss.is_boss_night(10) and InvasionBoss.is_boss_night(15))
	check("tiers: 5 -> 1, 10 -> 2, 15 -> 3", InvasionBoss.tier_of(5) == 1 and InvasionBoss.tier_of(10) == 2 and InvasionBoss.tier_of(15) == 3)
	check("waves: 3 on night 4, 4 on night 5", InvasionBoss.total_waves(4, 3) == 3 and InvasionBoss.total_waves(5, 3) == 4)
	check("factor 1.0 / 1.4 / 1.8", approx(InvasionBoss.factor(1), 1.0) and approx(InvasionBoss.factor(2), 1.4) and approx(InvasionBoss.factor(3), 1.8))
	check("summon cap grows by 1 per tier and stops at 8", InvasionBoss.summon_cap(4, 1) == 4 and InvasionBoss.summon_cap(4, 2) == 5 and InvasionBoss.summon_cap(4, 9) == 8)
	check("escort 6 / 8 / 10", InvasionBoss.escort_size(1) == 6 and InvasionBoss.escort_size(2) == 8 and InvasionBoss.escort_size(3) == 10)
	check("bonus xp 200 / 400", InvasionBoss.bonus_xp(1) == 200 and InvasionBoss.bonus_xp(2) == 400)
	check("roman numerals", InvasionBoss.roman(1) == "I" and InvasionBoss.roman(4) == "IV" and InvasionBoss.roman(9) == "IX" and InvasionBoss.roman(14) == "XIV")
	check("tier 1 keeps the plain name", InvasionBoss.title("Άρχοντας", 1) == "Άρχοντας")
	check("tier 2 and 3 get a numeral", InvasionBoss.title("Άρχοντας", 2) == "Άρχοντας II" and InvasionBoss.title("Άρχοντας", 3) == "Άρχοντας III")
	var base := {"max_health": 900.0, "attack_damage": 28.0, "summon_max": 4, "display_name": "Άρχοντας της Νύχτας"}
	var t1 := InvasionBoss.overrides(1, base)
	check("tier 1 overrides equal the base", approx(t1["max_health"], 900.0) and approx(t1["attack_damage"], 28.0) and t1["summon_max"] == 4 and t1["display_name"] == "Άρχοντας της Νύχτας")
	var t2 := InvasionBoss.overrides(2, base)
	check("tier 2 overrides: 1260 hp, 39.2 damage, 5 helpers, numeral", approx(t2["max_health"], 1260.0) and approx(t2["attack_damage"], 39.2) and t2["summon_max"] == 5 and t2["display_name"] == "Άρχοντας της Νύχτας II")
	check("the strings exist", Strings.INVASION_BOSS_COMING != "" and Strings.INVASION_BOSS_WON != "" and Strings.NIGHT_LORD_ENRAGE != "")
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `timeout 100 godot --path . --headless --script tools/invasion_boss_test.gd 2>&1 | grep "^PASS\|^FAIL\|SCRIPT ERROR\|Parse Error"`
Expected: a parse error / SCRIPT ERROR mentioning `InvasionBoss` (not declared).

- [ ] **Step 3: Add the strings.** In `scripts/strings_el.gd`, use Edit with `old_string`:

```
const INVASION_WON := "Το χωριό σώθηκε!"
```

`new_string`:

```
const INVASION_WON := "Το χωριό σώθηκε!"
const INVASION_BOSS_COMING := "Ο Άρχοντας της Νύχτας έρχεται!"
const INVASION_BOSS_WON := "Ο Άρχοντας της Νύχτας έπεσε! Το χωριό σώθηκε!"
const NIGHT_LORD_ENRAGE := "Ο Άρχοντας της Νύχτας καλεί τους νεκρούς!"
```

- [ ] **Step 4: Create `scripts/invasion_boss.gd`:**

```gdscript
class_name InvasionBoss
extends RefCounted
## The rules of the invasion boss nights. On night 5 and every 5th night after it a fourth
## wave brings the Night Lord ("night_lord" in enemies.gd KINDS), stronger each time.
## Pure functions, no scene access, so tests can use them directly.

const KIND := "night_lord"
const EVERY := 5                 # a boss comes on nights 5, 10, 15 ...
const GROWTH := 0.4              # extra health and damage per tier after the first
const SUMMON_CAP := 8


static func is_boss_night(night: int) -> bool:
	return night > 0 and night % EVERY == 0


## 1 for night 5, 2 for night 10 ... (0 on nights without a boss).
static func tier_of(night: int) -> int:
	return night / EVERY


## The invasion has one more wave than usual on a boss night.
static func total_waves(night: int, base: int) -> int:
	return base + 1 if is_boss_night(night) else base


static func factor(tier: int) -> float:
	return 1.0 + GROWTH * float(maxi(tier, 1) - 1)


static func summon_cap(base: int, tier: int) -> int:
	return mini(base + maxi(tier, 1) - 1, SUMMON_CAP)


static func escort_size(tier: int) -> int:
	return 4 + 2 * maxi(tier, 1)


static func bonus_xp(tier: int) -> int:
	return 200 * tier


static func roman(n: int) -> String:
	var values: Array[int] = [10, 9, 5, 4, 1]
	var symbols: Array[String] = ["X", "IX", "V", "IV", "I"]
	var out := ""
	var left := n
	for i in values.size():
		while left >= values[i]:
			out += symbols[i]
			left -= values[i]
	return out


## "Άρχοντας της Νύχτας", then "... II", "... III" for the later tiers.
static func title(base_name: String, tier: int) -> String:
	return base_name if tier <= 1 else "%s %s" % [base_name, roman(tier)]


## Stats to put on the boss of this tier. `base` is its entry in Enemies.KINDS.
static func overrides(tier: int, base: Dictionary) -> Dictionary:
	var f := factor(tier)
	return {
		"max_health": float(base["max_health"]) * f,
		"attack_damage": float(base["attack_damage"]) * f,
		"summon_max": summon_cap(int(base["summon_max"]), tier),
		"display_name": title(String(base["display_name"]), tier),
	}
```

- [ ] **Step 5: Refresh the class cache, then run the test**

Run: `godot --path . --headless --import 2>&1 | grep -i "error" ; timeout 100 godot --path . --headless --script tools/invasion_boss_test.gd 2>&1 | grep "^PASS\|^FAIL\|SCRIPT ERROR\|Parse Error"`
Expected: 17 lines `PASS  ...`, no FAIL, no errors.

- [ ] **Step 6: Commit**

```bash
git switch -c feature/invasion-boss
git add scripts/invasion_boss.gd scripts/invasion_boss.gd.uid scripts/strings_el.gd tools/invasion_boss_test.gd tools/invasion_boss_test.gd.uid
git commit -m "Invasion boss: the pure rules (nights, tiers, scaling) and Greek strings"
```

---

### Task 2: The `night_lord` kind, overrides for invaders, helpers that march

**Files:**
- Modify: `scripts/enemies.gd` (KINDS, BOSSES, `spawn_invader`, `spawn_summon`)
- Modify: `scripts/enemy.gd` (`_summon`, `_aggro_sound`, `_enrage`)
- Modify: `scripts/minimap.gd` (`_draw_enemies`), `scripts/sound_manager.gd` (boss list)
- Create: `tools/invasion_boss_world_test.gd`

**Interfaces:**
- Consumes: `InvasionBoss.overrides`, `Strings.NIGHT_LORD_ENRAGE` (Task 1).
- Produces:
  - `Enemies.KINDS["night_lord"]`
  - `Enemies.spawn_invader(kind: String, pos: Vector3, target: Vector3 = Vector3.ZERO, overrides: Dictionary = {}) -> Enemy`
  - `Enemies.spawn_summon(kind: String, pos: Vector3, summoner: Enemy = null) -> Enemy`: the helper is an invader with the summoner's `march_target` when the summoner is an invader.

- [ ] **Step 1: Write the failing test** — create `tools/invasion_boss_world_test.gd`:

```gdscript
extends SceneTree
## The Night Lord kind, stat overrides on invaders and invader helpers:
##   godot --path . --headless --script tools/invasion_boss_world_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func approx(a: float, b: float) -> bool:
	return absf(a - b) < 0.01


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var spawner = get_first_node_in_group("enemy_spawner")
	check("KINDS has night_lord", spawner.KINDS.has("night_lord"))
	var base: Dictionary = spawner.KINDS["night_lord"]
	check("it is a named boss that does not come back", base["display_name"] == "Άρχοντας της Νύχτας" and base["respawn"] == false)
	check("it summons and enrages", base["summon_kind"] == "minion" and base["enrage_below"] == 0.5 and base["enrage_summon"] == "warrior")
	check("it is listed among the bosses (always drops a charm)", "night_lord" in spawner.BOSSES)

	var boss = spawner.spawn_invader("night_lord", Vector3(0, 0.05, 60), Vector3.ZERO, InvasionBoss.overrides(2, base))
	await process_frame
	check("the boss is an invader", boss.invader and boss.is_in_group("invaders"))
	check("tier 2 health is 1260 (max and current)", approx(boss.max_health, 1260.0) and approx(boss.health, 1260.0))
	check("tier 2 damage is 39.2", approx(boss.attack_damage, 39.2))
	check("tier 2 may keep 5 helpers and is named II", boss.summon_max == 5 and boss.display_name == "Άρχοντας της Νύχτας II")

	boss.call("_summon")
	var helpers: Array = boss.get("_summons")
	check("the boss calls two helpers", helpers.size() == 2)
	var all_march := helpers.size() > 0
	for h in helpers:
		if not (h.invader and h.is_in_group("invaders") and h.march_target == boss.march_target):
			all_march = false
	check("the helpers of an invader are invaders marching to the same place", all_march)

	var plain = spawner.spawn_extra("minion", Vector3(40, 0.05, 40))
	plain.summon_kind = "minion"
	plain.call("_summon")
	var plain_helpers: Array = plain.get("_summons")
	var none_invade := plain_helpers.size() > 0
	for h in plain_helpers:
		if h.invader:
			none_invade = false
	check("the helpers of an ordinary skeleton are not invaders", none_invade)
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `timeout 100 godot --path . --headless --script tools/invasion_boss_world_test.gd 2>&1 | grep "^PASS\|^FAIL\|SCRIPT ERROR\|Parse Error"`
Expected: FAIL on the first checks (`KINDS has night_lord`) and a SCRIPT ERROR (invalid index "night_lord").

- [ ] **Step 3: Add the kind.** In `scripts/enemies.gd`, Edit `old_string`:

```
	# Quest bosses (they do not respawn)
```

`new_string`:

```
	# Boss of every fifth night's invasion (invasion_boss.gd scales it by tier; it calls
	# minions while fighting and enrages at half health, like Malakar)
	"night_lord": {
		"kind_id": "night_lord", "respawn": false, "tint_color": Color(0.25, 0.20, 0.65, 0.34),
		"display_name": "Άρχοντας της Νύχτας", "model_scale": 2.4,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 900.0, "attack_damage": 28.0, "chase_speed": 4.0, "attack_range": 3.8,
		"attack_hit_time": 0.65, "attack_cooldown": 1.9, "aggro_range": 26.0, "leash_range": 60.0,
		"patrol_radius": 4.0,
		"summon_kind": "minion", "summon_interval": 12.0, "summon_max": 4,
		"enrage_below": 0.5, "enrage_summon": "warrior",
		"xp_reward": 500, "gold_min": 120, "gold_max": 160, "potion_chance": 1.0,
	},
	# Quest bosses (they do not respawn)
```

- [ ] **Step 4: Add it to BOSSES.** Edit `old_string`:

```
const BOSSES: Array[String] = ["captain", "king", "warden_bone", "warden_flame", "warden_shadow", "necromancer", "giant_skeleton", "malakar"]
```

`new_string`:

```
const BOSSES: Array[String] = ["captain", "king", "warden_bone", "warden_flame", "warden_shadow", "necromancer", "giant_skeleton", "malakar", "night_lord"]
```

- [ ] **Step 5: `spawn_summon` takes the summoner.** Edit `old_string`:

```
## Helpers called by a boss (the necromancer's skeletons): they never come back.
func spawn_summon(kind: String, pos: Vector3) -> Enemy:
	var enemy := _make(kind, pos)
	enemy.aggro_range = 30.0
```

`new_string`:

```
## Helpers called by a boss (the necromancer's skeletons): they never come back. The
## helpers of a night invader march on the well too, so the invasion counts them.
func spawn_summon(kind: String, pos: Vector3, summoner: Enemy = null) -> Enemy:
	var enemy := _make(kind, pos)
	enemy.aggro_range = 30.0
	if summoner != null and summoner.invader:
		enemy.invader = true
		enemy.march_target = summoner.march_target
```

- [ ] **Step 6: `spawn_invader` takes overrides.** Edit `old_string`:

```
func spawn_invader(kind: String, pos: Vector3, target: Vector3 = Vector3.ZERO) -> Enemy:
	var enemy := _make(kind, pos)
	enemy.invader = true
```

`new_string`:

```
## `overrides` are stats set before the enemy enters the tree (the Night Lord's tier scaling).
func spawn_invader(kind: String, pos: Vector3, target: Vector3 = Vector3.ZERO, overrides: Dictionary = {}) -> Enemy:
	var enemy := _make(kind, pos)
	for key in overrides:
		enemy.set(key, overrides[key])
	enemy.invader = true
```

- [ ] **Step 7: `enemy.gd`.** Three Edits.

(a) in `_summon`, `old_string`:

```
		var helper = spawner.spawn_summon(summon_kind, global_position + Vector3(cos(angle), 0.0, sin(angle)) * 3.0)
```
`new_string`:
```
		var helper = spawner.spawn_summon(summon_kind, global_position + Vector3(cos(angle), 0.0, sin(angle)) * 3.0, self)
```

(b) in `_aggro_sound`, `old_string`:

```
		"captain", "king", "giant_skeleton", "malakar":
```
`new_string`:
```
		"captain", "king", "giant_skeleton", "malakar", "night_lord":
```

(c) in `_enrage`, `old_string`:

```
		player.message.emit(Strings.MALAKAR_ENRAGE)
```
`new_string`:
```
		player.message.emit(Strings.NIGHT_LORD_ENRAGE if kind_id == "night_lord" else Strings.MALAKAR_ENRAGE)
```

- [ ] **Step 8: Minimap and music.** `scripts/minimap.gd`, Edit `old_string`:

```
		var boss := kind == "captain" or kind == "king" or kind == "warlord"
```
`new_string`:
```
		var boss := kind == "captain" or kind == "king" or kind == "warlord" or kind == "night_lord"
```
`scripts/sound_manager.gd`, Edit `old_string`:

```
["captain", "king", "warlord", "warden_bone", "warden_flame", "warden_shadow", "necromancer", "giant_skeleton", "malakar"]
```
`new_string`:
```
["captain", "king", "warlord", "night_lord", "warden_bone", "warden_flame", "warden_shadow", "necromancer", "giant_skeleton", "malakar"]
```

- [ ] **Step 9: Run the test (and the two older tests that touch these functions)**

Run:
```bash
godot --path . --headless --import 2>&1 | grep -i "error"
for t in invasion_boss_world_test part3_mobs_test; do echo "== $t"; timeout 120 godot --path . --headless --script tools/$t.gd 2>&1 | grep "^PASS\|^FAIL\|SCRIPT ERROR"; done
```
Expected: every line `PASS`, no `FAIL`, no `SCRIPT ERROR` (the world test prints 11 PASS lines).

- [ ] **Step 10: Commit**

```bash
git add scripts/enemies.gd scripts/enemy.gd scripts/minimap.gd scripts/sound_manager.gd tools/invasion_boss_world_test.gd tools/invasion_boss_world_test.gd.uid
git commit -m "Night Lord: new boss kind, stat overrides for invaders, helpers of invaders march too"
```

---

### Task 3: The boss wave in `Invasion`

**Files:**
- Modify: `scripts/invasion.gd`
- Create: `tools/invasion_boss_flow_test.gd`

**Interfaces:**
- Consumes: everything from Tasks 1 and 2.
- Produces: `Invasion.waves_total: int` (public var; 3, or 4 on a boss night, set in `start`); the `updated` signal now sends `waves_total`.

- [ ] **Step 1: Write the failing test** — create `tools/invasion_boss_flow_test.gd`:

```gdscript
extends SceneTree
## A whole boss night:  godot --path . --headless --script tools/invasion_boss_flow_test.gd
var failed := false
var banners := []


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _kill_all(p: Player) -> void:
	for e in get_nodes_in_group("invaders"):
		e.take_damage(99999.0, p.global_position)


func _night_lord():
	for e in get_nodes_in_group("invaders"):
		if e.kind_id == "night_lord":
			return e
	return null


## Kills every invader round by round until the invasion reaches `target_wave` (or ends).
func _play_to_wave(inv, p: Player, target_wave: int) -> bool:
	var early_boss := false
	var guard := 0
	while inv.active and inv.wave < target_wave and guard < 24:
		if _night_lord() != null:
			early_boss = true
		_kill_all(p)
		await create_timer(0.8).timeout
		guard += 1
	return early_boss


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	var inv = get_first_node_in_group("invasion")
	dn.running = false
	p.max_health = 50000.0
	p.health = 50000.0
	p.teleport(Vector3(0, 0.05, 12), 0.0)
	inv.banner.connect(func(t, _s): banners.append(t))

	# ---- night 1: an ordinary night, three waves, no boss
	dn.set_time(20.6)
	await create_timer(5.0).timeout
	check("night 1 has 3 waves", dn.night_number == 1 and inv.waves_total == 3)
	var saw_boss := await _play_to_wave(inv, p, 99)
	check("night 1 is won without a boss", inv.last_success and not saw_boss and inv.wave == 3)

	# ---- night 5: the boss night
	dn.set_time(5.9)
	await create_timer(1.0).timeout
	dn.night_number = 4
	dn.set_time(20.6)
	await create_timer(5.0).timeout
	check("night 5 is a boss night with 4 waves", dn.night_number == 5 and inv.active and inv.waves_total == 4)
	var early := await _play_to_wave(inv, p, 4)
	check("the boss does not come before wave 4", not early)
	await create_timer(0.3).timeout
	var boss = _night_lord()
	check("wave 4 brings the Night Lord", boss != null and inv.wave == 4)
	check("tier 1: 900 hp, plain name", boss != null and absf(boss.max_health - 900.0) < 0.01 and boss.display_name == "Άρχοντας της Νύχτας")
	check("the boss has an escort of 6", get_nodes_in_group("invaders").size() == 7)
	check("the boss was announced", banners.has(Strings.INVASION_BOSS_COMING))

	boss.call("_summon")
	await create_timer(1.0).timeout            # a tick of the invasion merges the helpers into its list
	var helpers: Array = boss.get("_summons")
	check("the boss called two helpers", helpers.size() == 2)
	var keep = helpers[0]
	for e in get_nodes_in_group("invaders"):
		if e != keep:
			e.take_damage(99999.0, p.global_position)
	await create_timer(1.5).timeout
	check("the night is not won while a helper is alive", inv.active and not inv.last_success)

	var power_before: int = p.consumables["power"]
	var xp_before := p.xp
	keep.take_damage(99999.0, p.global_position)
	await create_timer(1.5).timeout
	check("the night is won when the helper is dead", inv.last_success and not inv.active)
	check("the boss victory banner", banners.has(Strings.INVASION_BOSS_WON))
	check("a power potion and a speed potion as reward", p.consumables["power"] >= power_before + 1 and p.consumables["speed"] >= 1)
	check("xp was gained", p.xp != xp_before or p.level > 1)
	var found := false
	for c in main.get_node("Village/Chests").get_children():
		if c.get("golden") == true and int(c.get("gold_min")) == 2 * (30 + 15 * 5):
			found = true
	check("the golden chest has double gold", found)

	# ---- night 10: tier 2, and the dawn takes it away
	dn.set_time(5.9)
	await create_timer(1.0).timeout
	dn.night_number = 9
	dn.set_time(20.6)
	await create_timer(5.0).timeout
	await _play_to_wave(inv, p, 4)
	await create_timer(0.3).timeout
	boss = _night_lord()
	check("night 10 brings a stronger Night Lord II", boss != null and absf(boss.max_health - 1260.0) < 0.01 and boss.display_name == "Άρχοντας της Νύχτας II")
	check("tier 2 escort of 8", get_nodes_in_group("invaders").size() == 9)
	dn.set_time(5.6)
	await create_timer(3.5).timeout
	check("at dawn the boss and everyone else crumble", get_nodes_in_group("invaders").size() == 0 and not inv.active)
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `timeout 240 godot --path . --headless --script tools/invasion_boss_flow_test.gd 2>&1 | grep "^PASS\|^FAIL\|SCRIPT ERROR"`
Expected: SCRIPT ERROR (`waves_total` is not a member of `Invasion`) and/or FAILs from the night-5 checks.

- [ ] **Step 3: `invasion.gd` — the variable and `start`.** Edit `old_string`:

```
var last_success := false

var _alive: Array[Enemy] = []
```
`new_string`:
```
var last_success := false
var waves_total := WAVES            # 4 on a boss night (the last wave is the Night Lord's)

var _alive: Array[Enemy] = []
```
Edit `old_string`:

```
	last_success = false
	_alive.clear()
	_wave_size = 0
	_say(Strings.INVASION_BANNER, 5.0)
```
`new_string`:
```
	last_success = false
	waves_total = InvasionBoss.total_waves(night, WAVES)
	_alive.clear()
	_wave_size = 0
	_say(Strings.INVASION_BANNER, 5.0)
```

- [ ] **Step 4: `_process` — merge helpers, use `waves_total`.** Edit `old_string`:

```
	_alive = _alive.filter(func(e): return is_instance_valid(e) and not e.is_dead())
	var near := 0
```
`new_string`:
```
	_alive = _alive.filter(func(e): return is_instance_valid(e) and not e.is_dead())
	for e in get_tree().get_nodes_in_group("invaders"):      # helpers a boss called also have to die
		if e is Enemy and not _alive.has(e):
			_alive.append(e)
	var near := 0
```
Edit `old_string`:

```
	if wave < WAVES:
		if float(_alive.size())
```
`new_string`:
```
	if wave < waves_total:
		if float(_alive.size())
```

- [ ] **Step 5: `_spawn_wave` — pool helper and the boss branch.** Edit `old_string`:

```
	_wave_size = clampi(3 + night * 2 + wave - 1, 4, 14)
	var pool := ["minion", "minion", "warrior", "warrior"]
	if level >= 3:
		pool.append_array(["rogue", "rogue"])
	if level >= 6:
		pool.append("mage")
	if level >= 9:
		pool.append("brute")
	# every wave comes through two gates; the last wave through three
	var gates := GATES.duplicate()
	gates.shuffle()
	var gate_count := 3 if wave == WAVES else 2
```
`new_string`:
```
	var pool := _kind_pool(level)
	var gates := GATES.duplicate()
	gates.shuffle()
	if InvasionBoss.is_boss_night(night) and wave == waves_total:
		_spawn_boss_wave(spawner, pool, gates)
		return
	_wave_size = clampi(3 + night * 2 + wave - 1, 4, 14)
	# every wave comes through two gates; the last wave through three
	var gate_count := 3 if wave == WAVES else 2
```
Then add the two new functions: Edit `old_string`:

```
# ----------------------------------------------------------------- results ----
```
`new_string`:
```
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
```

- [ ] **Step 6: Rewards.** Edit `old_string`:

```
	var xp := 80 + 40 * night
	var gold := 40 + 25 * night
	if player:
		player.gain_xp(xp)
		player.collect("gold", gold)
		player.collect("potion", 2 + night / 2)
	_spawn_reward_chest()
	Quests.report_defense()
	_say(Strings.INVASION_WON, 5.0)
```
`new_string`:
```
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
```
Edit `old_string`:

```
func _spawn_reward_chest() -> void:
	var chests := get_parent().get_node_or_null("Village/Chests")
	var chest := Chest.new()
	chest.golden = true
	chest.gold_min = 30 + 15 * night
	chest.gold_max = 50 + 25 * night
```
`new_string`:
```
func _spawn_reward_chest(boss_night: bool = false) -> void:
	var chests := get_parent().get_node_or_null("Village/Chests")
	var chest := Chest.new()
	chest.golden = true
	var share := 2 if boss_night else 1
	chest.gold_min = (30 + 15 * night) * share
	chest.gold_max = (50 + 25 * night) * share
```

- [ ] **Step 7: Failure, signal.** Edit `old_string` (in `_fail`):

```
	for e in _alive:
		if is_instance_valid(e):
			e.dissolve()
	_alive.clear()
```
`new_string`:
```
	for e in get_tree().get_nodes_in_group("invaders"):      # includes the helpers of a boss
		e.dissolve()
	_alive.clear()
```
Edit `old_string`:

```
	updated.emit(active, wave, WAVES, _alive.size(), safety)
```
`new_string`:
```
	updated.emit(active, wave, waves_total, _alive.size(), safety)
```

- [ ] **Step 8: Run the test**

Run: `timeout 240 godot --path . --headless --script tools/invasion_boss_flow_test.gd 2>&1 | grep "^PASS\|^FAIL\|SCRIPT ERROR"`
Expected: 18 lines `PASS`, no FAIL, no SCRIPT ERROR. If "the night is not won while a helper is alive" fails, the merge in `_process` did not run (check Step 4). If a wave check fails by timing, raise the `create_timer` waits, not the rules.

- [ ] **Step 9: Re-run the older headless suites that touch invasions or enemies**

Run:
```bash
for t in invasion_boss_test invasion_boss_world_test part3_mobs_test guard_snag_test; do echo "== $t"; timeout 150 godot --path . --headless --script tools/$t.gd 2>&1 | grep "^FAIL\|SCRIPT ERROR"; done
```
Expected: no output after each `==` line (no FAIL, no SCRIPT ERROR).

- [ ] **Step 10: Commit**

```bash
git add scripts/invasion.gd tools/invasion_boss_flow_test.gd tools/invasion_boss_flow_test.gd.uid
git commit -m "Invasion: a boss wave on every 5th night, helpers counted, boss rewards"
```

---

### Task 4: Look at it, check normal nights and frame rate, document

**Files:**
- Create: `tools/bossnighttest.gd`
- Modify: `CLAUDE.md` (the "Day/night & night invasion" paragraph), `HANDOVER.md` (section 0 and backlog E)

- [ ] **Step 1: Create the screenshot driver `tools/bossnighttest.gd`:**

```gdscript
extends SceneTree
## Boss night, screenshots and frame rate:
##   godot --path . --resolution 1920x1080 --script tools/bossnighttest.gd -- <outdir>
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _night_lord():
	for e in get_nodes_in_group("invaders"):
		if e.kind_id == "night_lord":
			return e
	return null


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	var inv = get_first_node_in_group("invasion")
	dn.running = false
	p.max_health = 50000.0
	p.health = 50000.0
	p.teleport(Vector3(0, 0.05, 12), 0.0)
	var banners := []
	inv.banner.connect(func(t, _s): banners.append(t))

	dn.night_number = 4
	dn.set_time(20.6)                      # night 5
	await create_timer(5.0).timeout
	var guard := 0
	while inv.active and inv.wave < 4 and guard < 24:
		for e in get_nodes_in_group("invaders"):
			e.take_damage(99999.0, p.global_position)
		await create_timer(0.8).timeout
		guard += 1
	await create_timer(0.5).timeout
	var boss = _night_lord()
	print("boss present: ", boss != null, "  wave ", inv.wave, "/", inv.waves_total, "  invaders ", get_nodes_in_group("invaders").size())
	print("banners: ", banners)
	if boss == null:
		quit(1)
		return
	var gate_pos: Vector3 = boss.global_position
	var toward_well := Vector3(-gate_pos.x, 0.0, -gate_pos.z).normalized()
	p.teleport(gate_pos + toward_well * 34.0 + Vector3(0, 0.05, 0), atan2(-toward_well.x, -toward_well.z))
	await create_timer(1.0).timeout
	await shot("boss_arrives")
	print("fps while the wave marches: ", Engine.get_frames_per_second())

	await create_timer(5.0).timeout       # the boss notices George and fights
	boss.call("_summon")
	await create_timer(1.5).timeout
	await shot("boss_summons")
	boss.take_damage(boss.max_health * 0.55, p.global_position)   # below half: enrage
	await create_timer(1.5).timeout
	await shot("boss_enraged")
	print("enraged: ", boss.get("_enraged"), "  fps in the fight: ", Engine.get_frames_per_second())

	for i in 6:
		for e in get_nodes_in_group("invaders"):
			e.take_damage(99999.0, p.global_position)
		await create_timer(0.8).timeout
	await shot("boss_won")
	print("success: ", inv.last_success, "  banners: ", banners)
	quit()
```

- [ ] **Step 2: Run it (windowed; if it fails with `Couldn't create Vulkan image`, Theodore's game holds the GPU: ask him to stop it)**

Run: `timeout 300 godot --path . --resolution 1920x1080 --script tools/bossnighttest.gd -- tools/_shots/bossnight`
Expected: `boss present: true  wave 4/4`, banners include "Ο Άρχοντας της Νύχτας έρχεται!", `enraged: true`, `success: true`, banners include the victory banner, fps 55 or more. The four PNGs appear in `tools/_shots/bossnight/`.

- [ ] **Step 3: Look at the four screenshots** (Read tool on each PNG): the boss must be clearly bigger than the escort, with a name tag and health bar; the escort must be visible; the enraged shot must show helpers. If the boss is invisible or clipped into the ground, fix `model_scale`/spawn height before going on.

- [ ] **Step 4: Check that ordinary nights are unchanged**

Run: `timeout 300 godot --path . --resolution 1280x720 --script tools/eventtest.gd -- tools/_shots/eventtest 2>&1 | tail -25`
Expected: night 1 `success: true`, night 2 "village fell", night 3 "invaders before dawn N after 0 active false"; no SCRIPT ERROR. Then the frame rate:

Run: `timeout 300 godot --path . --resolution 1280x720 --script tools/perftest.gd -- night 2>&1 | tail -8`
Expected: 55 fps or more (re-run once before suspecting a regression; another process on the GPU can lower it).

- [ ] **Step 5: Document.** In `CLAUDE.md`, Edit the "Day/night & night invasion" paragraph: `old_string`:

```
New side quest "Η Νύχτα της Εισβολής" (objective type `defend`) from Παπά-Σταύρος. Tests: `daytest`, `eventtest`, `nightinterior`, `shelter`, `skytest`, `perftest -- night`.
```
`new_string`:
```
New side quest "Η Νύχτα της Εισβολής" (objective type `defend`) from Παπά-Σταύρος. **Boss nights** (`invasion_boss.gd`, class `InvasionBoss`, pure rules): on night 5 and every 5th night after it (`is_boss_night`, tier = night / 5) the invasion has a 4th wave (`Invasion.waves_total`, the HUD shows "Κύμα 4/4") with the boss `night_lord` ("Άρχοντας της Νύχτας", `Enemies.KINDS`; "... II", "... III" from tier 2): it comes from one gate with an escort of `4 + 2*tier` skeletons once wave 3 is cleared by the usual rule, calls minions while fighting (`summon_kind`) and enrages at half health (calls warriors; text `Strings.NIGHT_LORD_ENRAGE`). Tier scaling (`InvasionBoss.overrides`, passed to `Enemies.spawn_invader(kind, pos, target, overrides)`): health and damage x `1 + 0.4*(tier-1)`, helper cap +1 per tier (max 8). The helpers of an invader are invaders too (`Enemies.spawn_summon(kind, pos, summoner)`), and `Invasion._process` adds every member of group `invaders` it did not spawn itself to its alive list, so the night is won only when they are dead too. Boss night rewards: +200 XP x tier, a power and a speed potion, a golden chest with double gold, banner `INVASION_BOSS_WON`. Tests: `daytest`, `eventtest`, `nightinterior`, `shelter`, `skytest`, `perftest -- night`, `invasion_boss_test`, `invasion_boss_world_test`, `invasion_boss_flow_test` (headless), `bossnighttest` (screenshots + fps).
```
In `HANDOVER.md`, Edit `old_string`:

```
**E. More invasion variety (e.g. a boss on night 5).**
```
`new_string`:
```
**E. More invasion variety. DONE on branch `feature/invasion-boss` (boss on night 5 and every 5th night, see `CLAUDE.md`; not released yet). Still open from this idea: themed nights (archers only, brutes only) and a different boss per tier.** Original notes:
```

- [ ] **Step 6: Commit**

```bash
git add tools/bossnighttest.gd tools/bossnighttest.gd.uid CLAUDE.md HANDOVER.md
git commit -m "Invasion boss nights: screenshot driver and docs"
```

- [ ] **Step 7: Report to Theodore** (short, honest): what was built, the test results, any FAIL, that the boss was judged from screenshots only (size, colour, health values are easy to tune in `Enemies.KINDS["night_lord"]` and `InvasionBoss`), that the boss roar reuses `boss_roar` and was not heard, and that nothing was pushed, tagged or released.
