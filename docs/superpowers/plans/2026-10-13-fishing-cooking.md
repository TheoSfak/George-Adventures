# Fishing and Tavern Food Buffs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** George can fish at the village pond with a one-button timing mini-game, collect 13 species (with a journal), sell them at the market or cook them with the new tavern cook Θανάσης into meals that give timed buffs.

**Architecture:** Fish are new entries in `ShopData.JUNK` (so they live in the already-saved `Player.junk` and the market buys them with no new code). A new HUD overlay `Fishing` runs the cast / wait / bite / timing-bar flow. Meals are data in `ShopData.MEALS`; `Player.food` holds the active meal and feeds `Stats` through a new source `"food"`, exactly like equipment and talents. The cook is a shopkeeper NPC (`"shop": "kitchen"`) and `ShopWindow` gets a kitchen layout with two tabs.

**Tech Stack:** Godot 4.7.2 / GDScript (tabs), Python 3 + numpy for the generated sounds. Spec: `docs/superpowers/specs/2026-10-13-fishing-cooking-design.md`.

## Global Constraints

- **ALL IN-GAME TEXT IS GREEK.** Code, comments and file names are English. Edit Greek files only with the Edit/Write tools (UTF-8), never with shell heredocs or Python on Windows. A bash heredoc containing quotes or Greek can fail with "unexpected EOF"; use the Write tool.
- GDScript files use **tabs**. Use `var x: bool = ...` / `var s: String = dict["k"]` when a type would otherwise be inferred from a `Variant`.
- Only one input is needed for fishing and it must work over AnyDesk: `interact` (R / Enter), `jump` (Space), `ui_accept` or the left mouse button.
- In `--script` test drivers: start with `await process_frame`, set `root.get_node("/root/Quests").intro_seen = true`, and do not type-reference classes whose scripts mention autoloads (`Npc`, `Chest`, `SaveGame`, `Frontier`, ...); use `load("res://scripts/...gd")` and untyped access. `Player`, `Interiors`, `ShopData`, `Strings`, `QuestData`, `Stats` are safe.
- After adding a `class_name` script or assets run `godot --headless --import`.
- Tests that call `SaveGame.save()` must back up and restore `user://savegame.json` AND `user://savegame.bak` (pattern in `tools/part3_hooks_test.gd`).
- Git: Theodore is the sole author. **No `Co-Authored-By`, no "Generated with Claude Code", no attribution trailer** in any commit message. Commit locally per task on branch `feature/fishing-cooking`. Do NOT push, tag, bump `config/version` or create a release: Theodore asks for that separately.
- Do not kill Theodore's Godot processes. If a windowed test fails with "Couldn't create Vulkan image", ask him to stop his game. Run headless tests with `timeout 100 godot ... > file 2>&1` (a script error inside a coroutine otherwise hangs the process).
- Village random generation must not change: do not add or remove calls to `_rng` in `village.gd` (the pond rocks loop keeps consuming the same random numbers).

## File Structure

| File | Responsibility |
|---|---|
| `scripts/shop_data.gd` | 13 fish in `JUNK`, `MEALS`, the `kitchen` shop, helpers (`fish_ids`, `fish_by_rarity`, `can_prepare`, `fish_to_use`, `fish_need_text`, `meal_mods`). |
| `scripts/fishing.gd` (new) | The HUD overlay: cast, wait, bite, timing bar, result; `pick_fish`, `hit`. |
| `scripts/player.gd` | `food`, `eat`, `prepare_meal`, `fish_seen`, `add_fish`, buff timer, `buff_time("food")`. |
| `scripts/shop_window.gd` | Kitchen layout (tabs Φαγητά / Μαγείρεμα). |
| `scripts/hud.gd`, `scripts/hero_window.gd` | Food pill, `start_fishing`, journal line. |
| `scripts/village.gd` | The dock, bucket and the fishing spot. |
| `scripts/interiors.gd`, `scripts/quest_data.gd` | The cook inside the tavern. |
| `scripts/icons.gd`, `scripts/strings_el.gd`, `scripts/save_game.gd` | Icons `fish` and `food`, strings, `fish_seen` in the save. |
| `tools/audio/sfx.py` | `fish_cast`, `fish_bite`, `fish_catch`, `fish_escape`, `eat`. |
| `tools/fish_data_test.gd`, `kitchen_test.gd`, `kitchen_window_test.gd`, `fishing_test.gd`, `fishshot.gd` (new) | Tests and screenshots. |

Test commands (Git Bash, project folder `C:/Users/user/Desktop/George Adventures`):
- logic test: `timeout 100 godot --path . --headless --script tools/<name>.gd > /tmp/t.txt 2>&1; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt`
- screenshot test: `godot --path . --resolution 1920x1080 --script tools/<name>.gd -- tools/_shots/<name>`

---

### Task 1: Fish, meals and the kitchen as data

**Files:**
- Modify: `scripts/strings_el.gd`, `scripts/shop_data.gd`, `scripts/quest_data.gd`
- Create: `tools/fish_data_test.gd`

**Interfaces:**
- Produces:
  - `ShopData.JUNK` gains 13 entries with `"fish": true`, `"rarity"` ("common"|"uncommon"|"rare"|"legendary"), `"zone"` (share of the bar), `"speed"` (bar widths per second), `"weight"` (draw weight), optional `"only"` ("day"|"night"). Ids: `goby perch sazani carp barbel trout eel catfish pike sunfish moonfish goldfish king`.
  - `ShopData.MEALS: Dictionary` id -> `{"name", "desc", "tab": "buy"|"cook", "duration": float, "mods": Dictionary, "cost": {"gold": int, "fish": {rarity: count}}}`. Ids: `fasolada tyropita kreas fried soup grilled feast`.
  - `ShopData.SHOPS["kitchen"]` (`"kind": "kitchen"`), `ShopData.RARITY_ORDER`.
  - `static func fish_ids() -> Array[String]`, `fish_by_rarity(rarity: String) -> Array[String]` (cheapest first), `fish_have(junk: Dictionary, rarity: String) -> int`, `can_prepare(meal_id: String, gold: int, junk: Dictionary) -> bool`, `fish_to_use(meal_id: String, junk: Dictionary) -> Dictionary` (junk id -> count, cheapest first), `fish_need_text(meal_id: String, junk: Dictionary) -> String`, `meal_mods(food: Dictionary) -> Dictionary`.
  - NPC id `thanasis` in `QuestData.NPCS` with `"shop": "kitchen"`.
  - Strings listed in Step 3.

- [ ] **Step 0: Create the working branch**

```bash
cd "C:/Users/user/Desktop/George Adventures" && git switch -c feature/fishing-cooking && git status --short
```
Expected: `Switched to a new branch 'feature/fishing-cooking'`, clean tree.

- [ ] **Step 1: Write the failing data test**

Create `tools/fish_data_test.gd`:

```gdscript
extends SceneTree
## The fish, the meals and the kitchen as data (no world needed):
##   godot --path . --headless --script tools/fish_data_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var ids: Array = ShopData.fish_ids()
	check("13 species (found %d)" % ids.size(), ids.size() == 13)
	if ids.size() != 13:
		quit(1)
		return
	var counts := {}
	for id in ids:
		var f: Dictionary = ShopData.JUNK[id]
		counts[f["rarity"]] = int(counts.get(f["rarity"], 0)) + 1
		check("%s has name, price, icon, desc, zone, speed and weight" % id,
				f.has("name") and f.has("price") and f["icon"] == "fish" and f.has("desc") and float(f["zone"]) > 0.0 and float(f["speed"]) > 0.0 and float(f["weight"]) > 0.0)
	check("rarities 5 / 4 / 3 / 1: " + str(counts), counts == {"common": 5, "uncommon": 4, "rare": 3, "legendary": 1})
	check("sunfish is day only, moonfish night only", ShopData.JUNK["sunfish"]["only"] == "day" and ShopData.JUNK["moonfish"]["only"] == "night")
	check("rarer fish have narrower zones", float(ShopData.JUNK["goby"]["zone"]) > float(ShopData.JUNK["trout"]["zone"]) and float(ShopData.JUNK["trout"]["zone"]) > float(ShopData.JUNK["goldfish"]["zone"]) and float(ShopData.JUNK["goldfish"]["zone"]) > float(ShopData.JUNK["king"]["zone"]))
	check("the old junk is still there", ShopData.JUNK.has("bone") and ShopData.JUNK.has("rust") and ShopData.JUNK.has("charm"))

	# cheapest first inside a rarity
	var common: Array = ShopData.fish_by_rarity("common")
	check("common fish sorted cheapest first: " + str(common), common == ["goby", "perch", "sazani", "carp", "barbel"])

	# meals
	check("7 meals", ShopData.MEALS.size() == 7)
	for id in ShopData.MEALS:
		var m: Dictionary = ShopData.MEALS[id]
		var keys_ok := true
		for k in m["mods"]:
			if not Stats.NAMES.has(k):
				keys_ok = false
		check("meal %s: name, desc, tab, duration, valid Stats keys, gold cost" % id,
				m.has("name") and m.has("desc") and m["tab"] in ["buy", "cook"] and float(m["duration"]) >= 600.0 and keys_ok and int(m["cost"]["gold"]) > 0)
	check("3 meals to buy and 4 to cook", ShopData.MEALS.values().filter(func(m): return m["tab"] == "buy").size() == 3 and ShopData.MEALS.values().filter(func(m): return m["tab"] == "cook").size() == 4)
	check("the feast lasts 15 minutes", float(ShopData.MEALS["feast"]["duration"]) == 900.0)

	# cooking rules
	var junk := {"goby": 2, "perch": 3, "trout": 1}
	check("fried fish needs 3 common fish and 5 gold", ShopData.can_prepare("fried", 5, junk) and not ShopData.can_prepare("fried", 4, junk) and not ShopData.can_prepare("fried", 5, {"goby": 2}))
	check("fish_to_use takes the cheapest first", ShopData.fish_to_use("fried", junk) == {"goby": 2, "perch": 1})
	check("soup needs 2 uncommon fish", not ShopData.can_prepare("soup", 100, junk))
	check("a gold meal needs only gold", ShopData.can_prepare("fasolada", 25, {}) and not ShopData.can_prepare("fasolada", 24, {}))
	check("fish_have counts a rarity", ShopData.fish_have(junk, "common") == 5 and ShopData.fish_have(junk, "uncommon") == 1)
	check("need text is Greek and shows what George has: " + ShopData.fish_need_text("fried", junk), ShopData.fish_need_text("fried", junk).contains("3") and ShopData.fish_need_text("fried", junk).contains("5"))
	check("meal_mods of nothing is empty", ShopData.meal_mods({}).is_empty())
	check("meal_mods of a meal", ShopData.meal_mods({"id": "fasolada", "time": 10.0}) == {"hp_add": 30})

	# the kitchen and its cook
	check("the kitchen shop exists", ShopData.SHOPS.has("kitchen") and ShopData.SHOPS["kitchen"]["kind"] == "kitchen")
	check("the cook exists and runs the kitchen", QuestData.NPCS.has("thanasis") and QuestData.NPCS["thanasis"]["shop"] == "kitchen")
	check("the cook's greeting is Greek text", ShopData.SHOPS["kitchen"]["greeting"].size() > 0)
	check("strings exist", Strings.PROMPT_FISH != "" and Strings.MSG_FISH_CAUGHT.contains("%s") and Strings.KITCHEN_EAT != "")
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `timeout 100 godot --path . --headless --script tools/fish_data_test.gd > /tmp/t.txt 2>&1; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: a script error (`fish_ids` not found) or `FAIL  13 species`, exit code 1.

- [ ] **Step 3: Add the strings**

In `scripts/strings_el.gd` Edit (single line anchor):

old_string:
```
const MSG_NO_MAP := "Ο χάρτης του χωριού δεν δείχνει αυτά τα βουνά."
```
new_string:
```
const MSG_NO_MAP := "Ο χάρτης του χωριού δεν δείχνει αυτά τα βουνά."

# --- fishing and the kitchen
const PROMPT_FISH := "[R] Ψάρεμα"
const FISH_CAST := "Ρίχνεις την πετονιά…"
const FISH_WAIT := "Περιμένεις να τσιμπήσει…"
const FISH_BITE := "Τσιμπάει! Πάτα τώρα!"
const FISH_HINT := "[R] / Space / κλικ: τράβηγμα     Esc: ακύρωση"
const MSG_FISH_CAUGHT := "Έπιασες: %s"
const MSG_FISH_NEW := "Νέο είδος! (%d/%d)"
const MSG_FISH_ESCAPED := "Το ψάρι ξέφυγε"
const MSG_FISH_EARLY := "Τράβηξες πολύ νωρίς"
const FISH_JOURNAL := "Ψάρια: %d/%d"
const KITCHEN_TAB_MEALS := "Φαγητά"
const KITCHEN_TAB_COOK := "Μαγείρεμα"
const KITCHEN_EAT := "Φάε"
const KITCHEN_NEEDS := "Χρειάζεται: %s"
const MEAL_DURATION := "Διάρκεια: %d λεπτά"
const MSG_MEAL_EATEN := "Έφαγες: %s"
const MSG_MEAL_NO_FISH := "Δεν έχεις αρκετά ψάρια"
const MSG_MEAL_OVER := "Η δύναμη του φαγητού πέρασε: %s"
```

- [ ] **Step 4: Add the fish, the meals and the kitchen to `ShopData`**

In `scripts/shop_data.gd` replace the end of `JUNK`. old_string:

```
	"charm": {"name": "Φυλαχτό των Νεκρών", "price": 25, "color": Color(0.55, 0.95, 0.65), "icon": "star", "desc": "Λάμπει με ένα ψυχρό πράσινο φως."},
}
```
new_string:

```
	"charm": {"name": "Φυλαχτό των Νεκρών", "price": 25, "color": Color(0.55, 0.95, 0.65), "icon": "star", "desc": "Λάμπει με ένα ψυχρό πράσινο φως."},
	# --- fish of the pond (fishing.gd). "zone" = share of the catch bar that counts as a hit, "speed" = bar widths
	# per second of the marker, "weight" = how often it bites, "only" = "day" or "night" (missing = always).
	"goby": {"name": "Γοβιός", "price": 6, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Μικρό και γρήγορο, ζει στα ρηχά.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"perch": {"name": "Πέρκα", "price": 8, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Ασημένια πέρκα με ριγέ πλευρές.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"sazani": {"name": "Σαζάνι", "price": 10, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Το άγριο σαζάνι της λίμνης.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"carp": {"name": "Κυπρίνος", "price": 12, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Χοντρός κυπρίνος· χορταίνει δύο.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"barbel": {"name": "Γριβάδι", "price": 14, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Γριβάδι με μουστάκια, αγαπά το ρεύμα.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"trout": {"name": "Πέστροφα", "price": 20, "color": Color(0.45, 0.85, 0.55), "icon": "fish", "desc": "Πέστροφα με κόκκινα στίγματα, από τα πιο νόστιμα.",
		"fish": true, "rarity": "uncommon", "zone": 0.20, "speed": 0.95, "weight": 4.0},
	"eel": {"name": "Χέλι", "price": 25, "color": Color(0.45, 0.85, 0.55), "icon": "fish", "desc": "Γλιστερό χέλι, δύσκολο στο πιάσιμο.",
		"fish": true, "rarity": "uncommon", "zone": 0.20, "speed": 0.95, "weight": 4.0},
	"catfish": {"name": "Γλάνος", "price": 30, "color": Color(0.45, 0.85, 0.55), "icon": "fish", "desc": "Ο γλάνος: ένα τεράστιο ψάρι με μουστάκια.",
		"fish": true, "rarity": "uncommon", "zone": 0.20, "speed": 0.95, "weight": 4.0},
	"pike": {"name": "Λούτσος", "price": 35, "color": Color(0.45, 0.85, 0.55), "icon": "fish", "desc": "Λούτσος με μυτερά δόντια· ο κυνηγός της λίμνης.",
		"fish": true, "rarity": "uncommon", "zone": 0.20, "speed": 0.95, "weight": 4.0},
	"sunfish": {"name": "Ηλιόψαρο", "price": 50, "color": Color(0.45, 0.68, 1.0), "icon": "fish", "desc": "Λάμπει χρυσό στο φως της ημέρας. Τσιμπάει μόνο τη μέρα.",
		"fish": true, "rarity": "rare", "zone": 0.12, "speed": 1.20, "weight": 2.0, "only": "day"},
	"moonfish": {"name": "Φεγγαρόψαρο", "price": 55, "color": Color(0.45, 0.68, 1.0), "icon": "fish", "desc": "Ασημένιο και απαλό σαν το φεγγάρι. Τσιμπάει μόνο τη νύχτα.",
		"fish": true, "rarity": "rare", "zone": 0.12, "speed": 1.20, "weight": 2.0, "only": "night"},
	"goldfish": {"name": "Χρυσόψαρο του Αγίου", "price": 70, "color": Color(0.45, 0.68, 1.0), "icon": "fish", "desc": "Λένε πως φέρνει την ευλογία του Αγίου.",
		"fish": true, "rarity": "rare", "zone": 0.12, "speed": 1.20, "weight": 1.5},
	"king": {"name": "Ο Βασιλιάς της Λίμνης", "price": 150, "color": Color(1.0, 0.78, 0.30), "icon": "fish", "desc": "Ο γέρο-Γιάννης λέει πως τον είδε πριν πενήντα χρόνια.",
		"fish": true, "rarity": "legendary", "zone": 0.07, "speed": 1.60, "weight": 0.5},
}

const RARITY_ORDER: Array[String] = ["common", "uncommon", "rare", "legendary"]
## "3 συχνά ψάρια", "1 σπάνιο ψάρι": the adjective of each rarity, singular and plural.
const RARITY_ONE := {"common": "συχνό", "uncommon": "ασυνήθιστο", "rare": "σπάνιο", "legendary": "θρυλικό"}
const RARITY_MANY := {"common": "συχνά", "uncommon": "ασυνήθιστα", "rare": "σπάνια", "legendary": "θρυλικά"}

## Meals of the tavern kitchen. "tab" "buy" = paid with gold only, "cook" = made from fish. "cost" has the gold
## and, for cooked meals, {"fish": {rarity: count}}; the cheapest fish of the rarity is used. "mods" use the
## keys of stats.gd; the buff lasts "duration" seconds (a game day is 600 s).
const MEALS := {
	"fasolada": {
		"name": "Φασολάδα", "desc": "Η φασολάδα του Θανάση: ζεστή, χορταστική, με λάδι.", "tab": "buy", "duration": 600.0,
		"mods": {"hp_add": 30}, "cost": {"gold": 25},
	},
	"tyropita": {
		"name": "Τυρόπιτα", "desc": "Τραγανή τυρόπιτα με φύλλο, φρέσκια από τον φούρνο.", "tab": "buy", "duration": 600.0,
		"mods": {"speed_mult": 0.08}, "cost": {"gold": 30},
	},
	"kreas": {
		"name": "Κρέας με Πατάτες", "desc": "Χοιρινό με πατάτες στο φούρνο· δίνει δύναμη στο χέρι.", "tab": "buy", "duration": 600.0,
		"mods": {"damage_mult": 0.10}, "cost": {"gold": 40},
	},
	"fried": {
		"name": "Τηγανητά Ψαράκια", "desc": "Τηγανητά ψαράκια της λίμνης με λεμόνι.", "tab": "cook", "duration": 600.0,
		"mods": {"hp_add": 50, "regen": 1.0}, "cost": {"gold": 5, "fish": {"common": 3}},
	},
	"soup": {
		"name": "Ψαρόσουπα", "desc": "Ψαρόσουπα με λαχανικά· ζεσταίνει και θεραπεύει.", "tab": "cook", "duration": 600.0,
		"mods": {"hp_add": 80, "regen": 2.0, "defense": 0.05}, "cost": {"gold": 8, "fish": {"uncommon": 2}},
	},
	"grilled": {
		"name": "Ψητό του Αγίου", "desc": "Ψάρι ψημένο στα κάρβουνα, όπως το ψήνουν οι ψαράδες του Αγίου.", "tab": "cook", "duration": 600.0,
		"mods": {"damage_mult": 0.15, "crit": 0.10, "speed_mult": 0.10}, "cost": {"gold": 10, "fish": {"rare": 1}},
	},
	"feast": {
		"name": "Γιορτινό του Βασιλιά", "desc": "Το γιορτινό τραπέζι του Βασιλιά της Λίμνης. Θα το θυμάσαι για δεκαπέντε λεπτά.", "tab": "cook", "duration": 900.0,
		"mods": {"damage_mult": 0.20, "defense": 0.12, "hp_add": 100, "crit": 0.08, "lifesteal": 0.03},
		"cost": {"gold": 20, "fish": {"legendary": 1}},
	},
}
```

Add the kitchen shop. old_string:
```
		"buys": "gear",
	},
}
```
new_string:
```
		"buys": "gear",
	},
	# The tavern kitchen: no stock or selling, the window shows MEALS in two tabs (see shop_window.gd)
	"kitchen": {
		"title": "Κουζίνα",
		"keeper": "Θανάσης ο Μάγειρας",
		"kind": "kitchen",
		"greeting": [
			"Καλώς τον Γιώργο! Φασολάδα, τυρόπιτα, κρέας με πατάτες… Και αν μου φέρεις ψάρια από τη λίμνη, θα σου φτιάξω πιάτα που δεν έχεις ξαναφάει!",
		],
		"stock": [],
		"buys": "",
	},
}
```

Add the helpers before `equipment_mods`. old_string:
```
## Modifiers of everything equipped: {key: value}.
```
new_string:
```
## Ids of all fish species, in the order of JUNK.
static func fish_ids() -> Array[String]:
	var out: Array[String] = []
	for id in JUNK:
		if JUNK[id].get("fish", false):
			out.append(id)
	return out


## Fish of one rarity, cheapest first.
static func fish_by_rarity(rarity: String) -> Array[String]:
	var out: Array[String] = []
	for id in fish_ids():
		if JUNK[id]["rarity"] == rarity:
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool: return int(JUNK[a]["price"]) < int(JUNK[b]["price"]))
	return out


## How many fish of a rarity are in the bag (junk: id -> count).
static func fish_have(junk: Dictionary, rarity: String) -> int:
	var n := 0
	for id in fish_by_rarity(rarity):
		n += int(junk.get(id, 0))
	return n


static func can_prepare(meal_id: String, gold: int, junk: Dictionary) -> bool:
	var cost: Dictionary = MEALS[meal_id]["cost"]
	if gold < int(cost["gold"]):
		return false
	var need: Dictionary = cost.get("fish", {})
	for rarity in need:
		if fish_have(junk, rarity) < int(need[rarity]):
			return false
	return true


## The fish a meal would use, cheapest first: {junk id: count}.
static func fish_to_use(meal_id: String, junk: Dictionary) -> Dictionary:
	var used := {}
	var need: Dictionary = MEALS[meal_id]["cost"].get("fish", {})
	for rarity in need:
		var left := int(need[rarity])
		for id in fish_by_rarity(rarity):
			if left <= 0:
				break
			var n := mini(left, int(junk.get(id, 0)))
			if n > 0:
				used[id] = int(used.get(id, 0)) + n
				left -= n
	return used


## "3 συχνά ψάρια (έχεις 2)" for the kitchen window.
static func fish_need_text(meal_id: String, junk: Dictionary) -> String:
	var parts: Array[String] = []
	var need: Dictionary = MEALS[meal_id]["cost"].get("fish", {})
	for rarity in need:
		var n := int(need[rarity])
		var word: String = RARITY_MANY[rarity] if n > 1 else RARITY_ONE[rarity]
		parts.append("%d %s %s (έχεις %d)" % [n, word, "ψάρια" if n > 1 else "ψάρι", fish_have(junk, rarity)])
	return ", ".join(parts)


## The Stats modifiers of the meal George is digesting ({} when none).
static func meal_mods(food: Dictionary) -> Dictionary:
	if food.is_empty():
		return {}
	return MEALS[food["id"]]["mods"]


## Modifiers of everything equipped: {key: value}.
```

- [ ] **Step 5: Add the cook**

In `scripts/quest_data.gd` Edit (one-tab anchor, single line, no leading whitespace in `old_string`):

old_string:
```
# Part 3: the refugee camp in the Frontier (see frontier.gd).
```
new_string:
```
# The cook of the tavern: fish are cooked into meals (see shop_data.gd, SHOPS["kitchen"]).
	"thanasis": {
		"name": "Θανάσης ο Μάγειρας",
		"model": "res://assets/characters/Barbarian.glb",
		"show": ["Mug"],
		"shop": "kitchen",
		"idle": ["Ένα καλό φαγητό αξίζει όσο ένα καλό σπαθί.", "Φέρε μου ψάρια και θα δεις τι μπορώ να κάνω."],
	},
	# Part 3: the refugee camp in the Frontier (see frontier.gd).
```

- [ ] **Step 6: Run the test**

Run: `timeout 100 godot --path . --headless --script tools/fish_data_test.gd > /tmp/t.txt 2>&1; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: every line `PASS`, no `FAIL`, no `SCRIPT ERROR`.

Also run the existing shop test to see the market still lists junk: `godot --path . --resolution 1280x720 --script tools/shoptest.gd -- tools/_shots/shoptest 2>&1 | tail -15` — no errors.

- [ ] **Step 7: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add scripts/strings_el.gd scripts/shop_data.gd scripts/quest_data.gd tools/fish_data_test.gd tools/fish_data_test.gd.uid
git commit -m "Add 13 fish, 7 meals and the tavern kitchen as data"
```

---

### Task 2: Food buff, journal and cooking logic in `Player`, plus the save

**Files:**
- Modify: `scripts/player.gd`, `scripts/save_game.gd`
- Create: `tools/kitchen_test.gd`

**Interfaces:**
- Consumes: Task 1 (`ShopData.MEALS`, `can_prepare`, `fish_to_use`, `meal_mods`, strings).
- Produces:
  - `Player.fish_seen: Array[String]`, `Player.food: Dictionary` ({"id", "time"} or empty).
  - `Player.add_fish(id: String) -> bool` (true when the species is new), `Player.eat(meal_id: String) -> void`, `Player.prepare_meal(meal_id: String) -> bool`, `Player.food_time() -> float`, `Player.food_name() -> String`, `buff_time("food")`.
  - Save key `player.fish_seen` (array of strings).

- [ ] **Step 1: Write the failing kitchen test**

Create `tools/kitchen_test.gd`:

```gdscript
extends SceneTree
## Food buffs, cooking and the fish journal:
##   godot --path . --headless --script tools/kitchen_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var save = load("res://scripts/save_game.gd")
	# keep the player's real save safe: this test writes savegame.json
	var real_backup := "user://savegame.before_kitchen_test"
	var real_bak_backup := "user://savegame.bak.before_kitchen_test"
	if FileAccess.file_exists(save.PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(save.BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.BACKUP), ProjectSettings.globalize_path(real_bak_backup))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	var base_hp := p.max_health
	var base_damage := p.sword_damage
	check("starting with no meal", p.food.is_empty() and p.buff_time("food") == 0.0 and p.food_name() == "")

	# --- a meal bought with gold
	p.gold = 100
	check("fasolada is bought", p.prepare_meal("fasolada"))
	check("it cost 25 gold", p.gold == 75)
	check("max health +30", is_equal_approx(p.max_health, base_hp + 30.0))
	check("the buff has about 600 s", p.food_time() > 595.0 and p.food_name() == "Φασολάδα")
	check("the HUD sees it as a buff", p.buff_time("food") > 595.0)

	# --- fried fish: cheapest common fish are used, a new meal replaces the old one
	p.junk = {"goby": 2, "perch": 3}
	check("fried fish is cooked", p.prepare_meal("fried"))
	check("2 gobies and 1 perch were used", int(p.junk.get("goby", 0)) == 0 and int(p.junk.get("perch", 0)) == 2)
	check("5 gold was paid (75 -> 70)", p.gold == 70)
	check("the new meal replaced the old: max health +50 (not +80)", is_equal_approx(p.max_health, base_hp + 50.0))
	check("fried fish gives +1 regen", is_equal_approx(p.stats.total("regen"), 1.0))

	# --- a meal you cannot make changes nothing
	p.junk = {"trout": 1}
	var gold_before := p.gold
	check("soup needs 2 uncommon fish: refused", not p.prepare_meal("soup"))
	check("nothing was spent", p.gold == gold_before and int(p.junk["trout"]) == 1 and p.food["id"] == "fried")
	p.gold = 2
	check("fried fish without gold: refused", not p.prepare_meal("fried"))

	# --- damage and speed buffs change the numbers where they are used
	p.gold = 100
	check("kreas bought", p.prepare_meal("kreas"))
	check("kreas gives +10% damage", is_equal_approx(p.sword_damage, base_damage * 1.10))
	p.gold = 100
	p.prepare_meal("tyropita")
	check("tyropita gives +8% speed", is_equal_approx(p.stats.total("speed_mult"), 0.08))
	check("...and the damage buff is gone", is_equal_approx(p.sword_damage, base_damage))

	# --- the buff ends
	p.food["time"] = 0.05
	await create_timer(0.4).timeout
	check("the meal wore off", p.food.is_empty() and p.buff_time("food") == 0.0)
	check("max health and speed are back", is_equal_approx(p.max_health, base_hp) and p.stats.total("speed_mult") == 0.0)

	# --- the feast
	p.junk = {"king": 1}
	p.gold = 50
	check("the feast is cooked from the legendary fish", p.prepare_meal("feast"))
	check("it lasts 15 minutes", p.food_time() > 895.0)
	check("max health +100", is_equal_approx(p.max_health, base_hp + 100.0))
	check("the king was used", int(p.junk.get("king", 0)) == 0)

	# --- the journal
	p.fish_seen = []
	p.junk = {}
	check("the first goby is a new species", p.add_fish("goby"))
	check("the second one is not", not p.add_fish("goby"))
	check("two gobies in the bag", int(p.junk["goby"]) == 2)
	p.add_fish("king")
	check("journal has 2 species", p.fish_seen.size() == 2)

	# --- the journal survives a save and a load
	save.delete()
	check("saved", save.save())
	var data: Dictionary = save.read()
	check("fish_seen is in the save", data["player"]["fish_seen"] == ["goby", "king"])
	p.fish_seen = []
	save.apply(data)
	await create_timer(0.5).timeout
	check("the journal is restored", p.fish_seen == ["goby", "king"])
	var old: Dictionary = data.duplicate(true)
	old["player"].erase("fish_seen")
	p.fish_seen = ["x"]
	save.apply(old)
	await create_timer(0.5).timeout
	check("an old save without the key gives an empty journal", p.fish_seen.is_empty())

	save.delete()
	if FileAccess.file_exists(real_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_backup), ProjectSettings.globalize_path(save.PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_backup))
	if FileAccess.file_exists(real_bak_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_bak_backup), ProjectSettings.globalize_path(save.BACKUP))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_bak_backup))
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `timeout 100 godot --path . --headless --script tools/kitchen_test.gd > /tmp/t.txt 2>&1; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt | head`
Expected: a script error on `p.food` (property missing), exit 124 or 1. (If the run aborted before the end, check `ls "$APPDATA/Godot/app_userdata/Οι Περιπέτειες του Γιώργου στον Άγιο Βλάση/"` for `savegame.before_kitchen_test` and put it back by hand.)

- [ ] **Step 3: Player fields and recalculation**

In `scripts/player.gd` Edit:

old_string:
```
var junk := {}
```
new_string:
```
var fish_seen: Array[String] = []   # fish species caught at least once (the journal)
var food := {}                   # the meal George ate: {"id": String, "time": seconds left}; empty = none
var junk := {}
```
(The rest of that original line, its trailing comment, stays after `var junk := {}`.)

old_string:
```
	stats.set_source("talents", TalentData.mods_for(talents))
```
new_string:
```
	stats.set_source("talents", TalentData.mods_for(talents))
	stats.set_source("food", ShopData.meal_mods(food))
```

old_string:
```
	_wall_time = maxf(_wall_time - delta, 0.0)
	_rebirth_cd
```
new_string:
```
	_wall_time = maxf(_wall_time - delta, 0.0)
	if not food.is_empty():
		food["time"] = float(food["time"]) - delta
		if float(food["time"]) <= 0.0:
			message.emit(Strings.MSG_MEAL_OVER % ShopData.MEALS[food["id"]]["name"])
			food = {}
			_recalc()
	_rebirth_cd
```

old_string:
```
		"wall":
			return _wall_time
	return 0.0
```
new_string:
```
		"wall":
			return _wall_time
		"food":
			return float(food.get("time", 0.0))
	return 0.0
```

- [ ] **Step 4: The new methods**

old_string:
```
## Slows George for `seconds` (-40% speed).
```
new_string:
```
## A caught fish goes into the bag (junk) and the journal. Returns true when the species is new.
func add_fish(id: String) -> bool:
	junk[id] = int(junk.get(id, 0)) + 1
	message.emit(Strings.MSG_FISH_CAUGHT % ShopData.JUNK[id]["name"])
	var fresh := not fish_seen.has(id)
	if fresh:
		fish_seen.append(id)
		message.emit(Strings.MSG_FISH_NEW % [fish_seen.size(), ShopData.fish_ids().size()])
	inventory_changed.emit(gold, potions)
	return fresh


## George eats a meal: its buff starts at once and replaces the one he had.
func eat(meal_id: String) -> void:
	food = {"id": meal_id, "time": float(ShopData.MEALS[meal_id]["duration"])}
	_recalc()
	Sfx.ui("eat")
	message.emit(Strings.MSG_MEAL_EATEN % ShopData.MEALS[meal_id]["name"])


## Pays gold and fish for a meal and eats it. Returns false (and spends nothing) when something is missing.
func prepare_meal(meal_id: String) -> bool:
	var cost: Dictionary = ShopData.MEALS[meal_id]["cost"]
	if gold >= int(cost["gold"]) and not ShopData.can_prepare(meal_id, gold, junk):
		message.emit(Strings.MSG_MEAL_NO_FISH)
		return false
	if not spend_gold(int(cost["gold"])):
		return false
	var used := ShopData.fish_to_use(meal_id, junk)
	for id in used:
		junk[id] = int(junk[id]) - int(used[id])
	inventory_changed.emit(gold, potions)
	eat(meal_id)
	return true


func food_time() -> float:
	return float(food.get("time", 0.0))


func food_name() -> String:
	return "" if food.is_empty() else String(ShopData.MEALS[food["id"]]["name"])


## Slows George for `seconds` (-40% speed).
```

- [ ] **Step 5: Save and load the journal**

In `scripts/save_game.gd` Edit:

old_string:
```
			"in_frontier": in_frontier,
```
new_string:
```
			"in_frontier": in_frontier,
			"fish_seen": player.fish_seen,
```
old_string:
```
	player.bar.assign(pd.get("bar", []))
```
new_string:
```
	player.bar.assign(pd.get("bar", []))
	player.fish_seen.assign(pd.get("fish_seen", []))
```
and the header comment, old_string:
```
## Saved: George (level, xp, gold, health, potions, gear, talents, action bar, position),
```
new_string:
```
## Saved: George (level, xp, gold, health, potions, gear, talents, action bar, fish journal, position),
```

- [ ] **Step 6: Run the tests**

Run: `timeout 100 godot --path . --headless --script tools/kitchen_test.gd > /tmp/t.txt 2>&1; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: every line `PASS`, no `FAIL`.

Regression: `timeout 100 godot --path . --headless --script tools/fish_data_test.gd 2>&1 | grep -c "^FAIL"` prints 0. Run the save round trip: `godot --path . --resolution 1280x720 --script tools/savetest.gd -- tools/_shots/savetest 2>&1 | tail -8` — loaded values match.

- [ ] **Step 7: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add scripts/player.gd scripts/save_game.gd tools/kitchen_test.gd tools/kitchen_test.gd.uid
git commit -m "Add food buffs, cooking and the fish journal to the player and the save"
```

---

### Task 3: Sounds for fishing and eating

**Files:**
- Modify: `tools/audio/sfx.py`
- Generated (commit): `assets/audio/sfx/fish_*.wav`, `assets/audio/sfx/eat_*.wav`, `scripts/sfx_ids.gd`

**Interfaces:**
- Produces: sound ids `fish_cast`, `fish_bite`, `fish_catch`, `fish_escape`, `eat` (variants 1, 1, 1, 1, 2).

- [ ] **Step 1: Add the recipes**

In `tools/audio/sfx.py` Edit (helper, before `loopable`):

old_string:
```
def loopable(sig, tail):
```
new_string:
```
def plop(rng, f0=900, f1=260, dur=0.16):
    """A drop in water: a falling sine and a puff of filtered noise."""
    n = int(dur * S.SR)
    f = S.pitch_curve(f0, f1, dur, 4.0)
    tone = np.sin(2 * np.pi * np.cumsum(f) / S.SR) * S.expdecay(n, dur * 0.3)
    splash = S.bandpass(nz(dur, rng), 3000, 1500) * S.expdecay(n, dur * 0.2) * 0.35
    return tone + splash


def loopable(sig, tail):
```
and the recipes, old_string:
```
@sfx("potion_buff", 1, 0.75)
```
new_string:
```
@sfx("fish_cast", 1, 0.7)
def _(rng, i):
    out = np.zeros(int(0.9 * S.SR))
    whoosh = sweep_band(nz(0.35, rng), 2500, 700, 0.5) * swell(int(0.35 * S.SR), 0.5)
    S.place(out, whoosh, 0.0, 0.6)
    S.place(out, plop(rng), 0.38, 0.9)
    return out


@sfx("fish_bite", 1, 0.7)
def _(rng, i):
    out = np.zeros(int(0.5 * S.SR))
    S.place(out, plop(rng, 700, 300, 0.12), 0.0, 0.8)
    S.place(out, plop(rng, 1100, 400, 0.10), 0.10, 0.6)
    return out


@sfx("fish_catch", 1, 0.75)
def _(rng, i):
    out = np.zeros(int(1.0 * S.SR))
    S.place(out, S.bandpass(nz(0.3, rng), 2500, 1800) * swell(int(0.3 * S.SR), 0.3), 0.0, 0.5)
    S.place(out, plop(rng, 800, 300, 0.2), 0.05, 0.7)
    S.place(out, shimmer(0.6, 1400, rng, 10), 0.25, 0.6)
    return out


@sfx("fish_escape", 1, 0.65)
def _(rng, i):
    out = np.zeros(int(0.6 * S.SR))
    S.place(out, thump(160, 0.3, 70), 0.0, 0.6)
    S.place(out, plop(rng, 600, 200, 0.2), 0.12, 0.7)
    return out


@sfx("eat", 2, 0.6)
def _(rng, i):
    out = np.zeros(int(0.8 * S.SR))
    for k, t0 in enumerate([0.0, 0.22, 0.46]):
        S.place(out, S.bandpass(nz(0.12, rng), 1400 + 200 * k + 100 * i, 700) * S.expdecay(int(0.12 * S.SR), 0.04), t0, 0.7)
    S.place(out, shimmer(0.4, 1200, rng, 6), 0.6, 0.35)
    return out


@sfx("potion_buff", 1, 0.75)
```

- [ ] **Step 2: Generate**

Run: `python tools/gen_audio.py sfx fish eat`
Expected: `sfx: 6 files written` (1 + 1 + 1 + 1 + 2).

Run: `git status --short assets scripts/sfx_ids.gd`
Expected: untracked `assets/audio/sfx/fish_cast.wav`, `fish_bite.wav`, `fish_catch.wav`, `fish_escape.wav`, `eat_1.wav`, `eat_2.wav`; modified `scripts/sfx_ids.gd` (the five new keys only: `"eat": 2`, `"fish_bite": 1`, `"fish_cast": 1`, `"fish_catch": 1`, `"fish_escape": 1`). If the recipe filter `eat` also regenerated other sounds (git shows modified `.wav` files), the content is deterministic and should be identical; if any existing `.wav` shows as modified, run `git checkout -- <file>` for it.

Run: `godot --path . --headless --import 2>&1 | grep -i error | head -3`
Expected: no output.

- [ ] **Step 3: Check the sounds are known to the game**

Run: `grep -c '"fish_\|"eat"' scripts/sfx_ids.gd`
Expected: 5.

- [ ] **Step 4: Commit**

```bash
git add tools/audio/sfx.py assets/audio scripts/sfx_ids.gd
git commit -m "Add fishing and eating sounds"
```

---

### Task 4: Icons, the kitchen window, the cook in the tavern, the food pill and the journal line

**Files:**
- Modify: `scripts/icons.gd`, `scripts/shop_window.gd`, `scripts/interiors.gd`, `scripts/hud.gd`, `scripts/hero_window.gd`
- Create: `tools/kitchen_window_test.gd`

**Interfaces:**
- Consumes: Tasks 1 and 2.
- Produces: `Icons.draw(..., "fish" | "food", ...)`; `ShopWindow` kitchen layout with `_eat(meal_id: String)`; the NPC `thanasis` standing in the tavern; HUD buff pill "food"; "Ψάρια: n/13" in the hero window gear tab.

- [ ] **Step 1: Write the failing window test**

Create `tools/kitchen_window_test.gd`:

```gdscript
extends SceneTree
## The kitchen window, the cook in the tavern, the HUD food pill, the journal line:
##   godot --path . --headless --script tools/kitchen_window_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func rows_of(shop: Node) -> int:
	return shop._list.get_child_count()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var hud = get_first_node_in_group("hud")
	var interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	p.gold = 200
	p.junk = {"goby": 3, "trout": 2}

	# --- the window
	hud.open_shop("kitchen", p)
	await create_timer(0.4).timeout
	var shop = hud.find_child("ShopWindow", true, false)
	check("the kitchen window opens and George stands still", shop.is_open() and p.busy)
	check("the meals tab lists 3 meals", rows_of(shop) == 3)
	shop._set_tab("cook")
	await create_timer(0.2).timeout
	check("the cook tab lists 4 meals", rows_of(shop) == 4)
	var hp_before := p.max_health
	shop._eat("fried")
	await create_timer(0.3).timeout
	check("cooking fried fish through the window works", p.food.get("id", "") == "fried" and int(p.junk.get("goby", 0)) == 0 and p.max_health == hp_before + 50.0)
	check("the window refreshed (still 4 rows)", rows_of(shop) == 4)
	shop._set_tab("buy")
	shop._eat("kreas")
	await create_timer(0.3).timeout
	check("buying a meal replaces the buff", p.food["id"] == "kreas")
	shop.close()
	await create_timer(0.5).timeout
	check("closing frees George", not p.busy)

	# --- the HUD pill
	await create_timer(0.3).timeout
	var pill: Label = hud._buff_labels["food"]
	check("the HUD shows a food pill with the meal name and minutes: '%s'" % pill.text, pill.visible and pill.text.begins_with("Κρέας με Πατάτες") and pill.text.contains(":"))

	# --- the cook stands in the tavern
	interiors.enter("tavern_test", "tavern", Vector3(-59, 0.05, 5), 0.0, p)
	for i in 60:
		await create_timer(0.1).timeout
		if interiors.is_inside() and not p.busy:
			break
	var cook = null
	for n in get_nodes_in_group("interactables"):
		if n.get("npc_id") == "thanasis":
			cook = n
	check("Thanasis stands in the tavern", cook != null)
	if cook != null:
		check("his prompt is a trade prompt", cook.interact_prompt() == Strings.PROMPT_TRADE % "Θανάσης ο Μάγειρας")

	# --- the journal line in the hero window
	p.fish_seen = ["goby", "king", "eel"]
	var hero = hud.find_child("HeroWindow", true, false)
	if hero == null:
		hero = hud._hero
	hero.toggle("gear")
	await create_timer(0.3).timeout
	var found := false
	for l in hero.find_children("*", "Label", true, false):
		if (l as Label).text == "Ψάρια: 3/13":
			found = true
	check("the hero window shows 'Ψάρια: 3/13'", found)
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `timeout 100 godot --path . --headless --script tools/kitchen_window_test.gd > /tmp/t.txt 2>&1; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt | head`
Expected: `FAIL` / script errors (no kitchen rows, `_eat` missing).

- [ ] **Step 3: Icons `fish` and `food`**

In `scripts/icons.gd` Edit:

old_string:
```
		"moon":
			_moon(ci, c, s, color)
```
new_string:
```
		"moon":
			_moon(ci, c, s, color)
		"fish":
			_fish(ci, c, s, color)
		"food":
			_food(ci, c, s, color)
```
and before the helper `_poly`, old_string:
```
static func _poly(ci: CanvasItem, c: Vector2, s: float, pts: Array, color: Color) -> void:
```
new_string:
```
static func _fish(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.52, 0.0), Vector2(-0.88, -0.34), Vector2(-0.88, 0.34)], color.darkened(0.2))                  # tail
	_poly(ci, c, s, [Vector2(-0.58, 0.0), Vector2(-0.30, -0.36), Vector2(0.18, -0.42), Vector2(0.62, -0.08),
			Vector2(0.62, 0.08), Vector2(0.18, 0.42), Vector2(-0.30, 0.36)], color)                                            # body
	_poly(ci, c, s, [Vector2(-0.10, -0.38), Vector2(0.12, -0.62), Vector2(0.24, -0.38)], color.darkened(0.2))                 # fin
	ci.draw_circle(c + Vector2(0.38, -0.06) * s, 0.09 * s, Color(1, 1, 1))
	ci.draw_circle(c + Vector2(0.40, -0.06) * s, 0.04 * s, Color(0.08, 0.08, 0.1))


static func _food(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_poly(ci, c, s, [Vector2(-0.62, 0.0), Vector2(0.62, 0.0), Vector2(0.48, 0.34), Vector2(0.20, 0.56),
			Vector2(-0.20, 0.56), Vector2(-0.48, 0.34)], color)                                                                 # the bowl
	_rect(ci, c, s, -0.66, -0.06, 1.32, 0.10, color.lightened(0.25))                                                          # its rim
	for x in [-0.28, 0.0, 0.28]:                                                                                              # steam
		ci.draw_line(c + Vector2(x, -0.12) * s, c + Vector2(x + 0.07, -0.55) * s, Color(1, 1, 1, 0.65), maxf(1.5, 0.06 * s))


static func _poly(ci: CanvasItem, c: Vector2, s: float, pts: Array, color: Color) -> void:
```

- [ ] **Step 4: The kitchen layout in `ShopWindow`**

In `scripts/shop_window.gd` Edit `_refresh`. old_string:

```
	_tabs.add_child(UiKit.tab_button(Strings.SHOP_BUY, _tab == "buy", _set_tab.bind("buy")))
	_tabs.add_child(UiKit.tab_button(Strings.SHOP_SELL, _tab == "sell", _set_tab.bind("sell")))
	for c in _list.get_children():
		c.queue_free()
	if _tab == "buy":
		for entry in shop["stock"]:
			_list.add_child(_buy_row(entry))
	else:
		_build_sell_rows(shop)
```
new_string:

```
	var kitchen: bool = shop.get("kind", "") == "kitchen"
	_tabs.add_child(UiKit.tab_button(Strings.KITCHEN_TAB_MEALS if kitchen else Strings.SHOP_BUY, _tab == "buy", _set_tab.bind("buy")))
	_tabs.add_child(UiKit.tab_button(Strings.KITCHEN_TAB_COOK if kitchen else Strings.SHOP_SELL, _tab != "buy", _set_tab.bind("cook" if kitchen else "sell")))
	for c in _list.get_children():
		c.queue_free()
	if kitchen:
		_build_kitchen_rows()
	elif _tab == "buy":
		for entry in shop["stock"]:
			_list.add_child(_buy_row(entry))
	else:
		_build_sell_rows(shop)
```
(Freed rows leave the tree on the next frame; tests that count rows must `await` a short timer after `_set_tab`, as the test does.)

Add the rows and the action before the trading section. old_string:
```
# ------------------------------------------------------------------- trading ----
```
new_string:
```
# ------------------------------------------------------------------- kitchen ----

func _build_kitchen_rows() -> void:
	for meal_id in ShopData.MEALS:
		if ShopData.MEALS[meal_id]["tab"] == _tab:
			_list.add_child(_meal_row(meal_id))


func _meal_row(meal_id: String) -> Control:
	var meal: Dictionary = ShopData.MEALS[meal_id]
	var cost: Dictionary = meal["cost"]
	var ok := ShopData.can_prepare(meal_id, _player.gold, _player.junk)
	var b := UiKit.button(Strings.KITCHEN_EAT, _eat.bind(meal_id), 120)
	b.disabled = not ok
	var lines: Array[String] = [
		"[color=#8cf27f]%s[/color]" % Stats.describe(meal["mods"]),
		"[color=#c9b98a]%s[/color]" % (Strings.MEAL_DURATION % roundi(float(meal["duration"]) / 60.0)),
	]
	if cost.has("fish"):
		var have_all := true
		for rarity in cost["fish"]:
			if ShopData.fish_have(_player.junk, rarity) < int(cost["fish"][rarity]):
				have_all = false
		lines.append("[color=%s]%s[/color]" % ["#c9b98a" if have_all else "#ff7366", Strings.KITCHEN_NEEDS % ShopData.fish_need_text(meal_id, _player.junk)])
	var gold: int = cost["gold"]
	return _row("food", Color(1.0, 0.78, 0.40), meal["name"], meal["desc"], "\n".join(lines),
		Strings.SHOP_PRICE % gold, _player.gold >= gold, [b])


func _eat(meal_id: String) -> void:
	if _player.prepare_meal(meal_id):
		_refresh()


# ------------------------------------------------------------------- trading ----
```

- [ ] **Step 5: The cook stands behind the counter**

In `scripts/interiors.gd` Edit the tavern definition. old_string:
```
		"chests": [[9.4, -6.6, 270, false, 10, 25, 1]],
```
new_string:
```
		"chests": [[9.4, -6.6, 270, false, 10, 25, 1]],
		# The cook behind the bar (the shopkeeper pattern of the market): [npc id, x, z, yaw in degrees]
		"shopkeeper": ["thanasis", 0.4, -5.3, 0],
```

- [ ] **Step 6: The HUD food pill**

In `scripts/hud.gd` Edit:

old_string:
```
	for id in ["power", "speed", "guard", "frenzy", "shout", "wall"]:
```
new_string:
```
	for id in ["power", "speed", "guard", "frenzy", "shout", "wall", "food"]:
```
old_string:
```
			l.text = "%s %d δ" % [names[id], ceili(t)]
```
new_string:
```
			if id == "food":
				l.text = "%s %d:%02d" % [_player.food_name(), floori(t / 60.0), int(t) % 60]
			else:
				l.text = "%s %d δ" % [names[id], ceili(t)]
```
and give the dictionary a harmless entry so `names[id]` never breaks. old_string:
```
		"frenzy": Strings.BUFF_FRENZY, "shout": Strings.BUFF_SHOUT, "wall": Strings.BUFF_WALL}
```
new_string:
```
		"frenzy": Strings.BUFF_FRENZY, "shout": Strings.BUFF_SHOUT, "wall": Strings.BUFF_WALL, "food": ""}
```

- [ ] **Step 7: The journal line in the hero window**

In `scripts/hero_window.gd` Edit:

old_string:
```
	right.add_child(UiKit.label("%s: %d" % [Strings.GOLD, player.gold], 18, UiKit.GOLD_TEXT))
```
new_string:
```
	right.add_child(UiKit.label("%s: %d" % [Strings.GOLD, player.gold], 18, UiKit.GOLD_TEXT))
	right.add_child(UiKit.label(Strings.FISH_JOURNAL % [player.fish_seen.size(), ShopData.fish_ids().size()], 16, UiKit.MUTED))
```

- [ ] **Step 8: Run the tests**

Run: `timeout 100 godot --path . --headless --script tools/kitchen_window_test.gd > /tmp/t.txt 2>&1; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: all `PASS`. If `hero.toggle("gear")` is not the tab id, open `scripts/hero_window.gd` (`func toggle(tab: String)`, tabs `skills`/`talents`/`gear`: check the names at the `match _tab:` in `_refresh`) and use the real id.

Regression: `timeout 100 godot --path . --headless --script tools/kitchen_test.gd 2>&1 | grep -c "^FAIL"` prints 0. Windowed: `godot --path . --resolution 1280x720 --script tools/shoptest.gd -- tools/_shots/shoptest 2>&1 | tail -8` and `godot --path . --resolution 1280x720 --script tools/keepertest.gd -- tools/_shots/keepertest 2>&1 | tail -8` show no errors (market, blacksmith, shopkeepers still work).

- [ ] **Step 9: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add scripts/icons.gd scripts/shop_window.gd scripts/interiors.gd scripts/hud.gd scripts/hero_window.gd tools/kitchen_window_test.gd tools/kitchen_window_test.gd.uid
git commit -m "Add the kitchen window, the cook in the tavern, the food pill and the fish journal line"
```

---

### Task 5: The fishing mini-game, the dock and the fishing spot

**Files:**
- Create: `scripts/fishing.gd`, `tools/fishing_test.gd`
- Modify: `scripts/hud.gd`, `scripts/village.gd`

**Interfaces:**
- Consumes: Tasks 1-3 (`ShopData.JUNK`, `Player.add_fish`, sounds `fish_*`, strings), `DayNight.darkness()`.
- Produces:
  - `Fishing` (class_name, `extends Control`, group `"fishing"`, node name `"Fishing"`): `enum State { IDLE, CASTING, WAITING, BITE }`, `signal finished(caught: String)`, `static func pick_fish(rng: RandomNumberGenerator, night: bool) -> String`, `static func hit(marker: float, center: float, zone: float) -> bool`, `func begin(player: Player, stand: Vector3, target: Vector3) -> void`, `func press() -> void`, fields `state`, `species`, `_wait`, `_bite_left`, `_marker`, `_zone`, `_zone_center` (read/written by tests).
  - `HUD.start_fishing(player: Player, stand: Vector3, target: Vector3) -> void`.
  - `Village.DOCK_ANGLE`, `Village._build_dock(pond: Vector2, radius: float)`; an `InteractSpot` with label `Strings.PROMPT_FISH`.

- [ ] **Step 1: Write the failing fishing test**

Create `tools/fishing_test.gd`:

```gdscript
extends SceneTree
## Fishing: the species draw, the bar decision and a whole cast driven through the overlay:
##   godot --path . --headless --script tools/fishing_test.gd
var failed := false
var p: Player
var fishing
var fz   # fishing.gd, loaded


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func fish_spot() -> InteractSpot:
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_FISH:
			return n
	return null


## Starts a cast at the real dock and waits for the bite.
func cast_and_bite() -> void:
	var spot := fish_spot()
	spot.interact(p)
	await create_timer(1.3).timeout                 # the cast takes 1 s
	fishing._wait = 0.05
	await create_timer(0.4).timeout


func _run() -> void:
	await process_frame
	fz = load("res://scripts/fishing.gd")
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	fishing = get_first_node_in_group("fishing")
	check("the fishing overlay exists in the HUD", fishing != null)
	check("there is a fishing spot at the pond", fish_spot() != null)
	if fishing == null or fish_spot() == null:
		quit(1)
		return

	# --- the draw
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var day := {}
	var night := {}
	for i in 4000:
		var d: String = fz.pick_fish(rng, false)
		day[d] = int(day.get(d, 0)) + 1
		var n: String = fz.pick_fish(rng, true)
		night[n] = int(night.get(n, 0)) + 1
	check("by day: no moonfish, sunfish possible (found %d)" % int(day.get("sunfish", 0)), not day.has("moonfish") and day.has("sunfish"))
	check("at night: no sunfish, moonfish possible (found %d)" % int(night.get("moonfish", 0)), not night.has("sunfish") and night.has("moonfish"))
	check("12 species by day", day.size() == 12 and night.size() == 12)
	check("common fish are much more frequent than rare ones", int(day["perch"]) > 5 * int(day["goldfish"]))
	check("the legendary fish does bite, rarely", day.has("king") and int(day["king"]) < int(day["perch"]) / 5)

	# --- the bar decision
	check("a marker inside the zone hits", fz.hit(0.5, 0.5, 0.2) and fz.hit(0.59, 0.5, 0.2))
	check("a marker outside the zone misses", not fz.hit(0.61, 0.5, 0.2) and not fz.hit(0.0, 0.5, 0.2))

	# --- a successful catch
	p.junk = {}
	p.fish_seen = []
	var stand_before := p.global_position
	await cast_and_bite()
	check("a bite after the wait", fishing.state == fz.State.BITE and fishing.species != "")
	check("George is busy while fishing", p.busy)
	var species: String = fishing.species
	fishing._marker = fishing._zone_center
	fishing.press()
	await create_timer(0.6).timeout
	check("the fish %s is in the bag" % species, int(p.junk.get(species, 0)) == 1)
	check("the journal has it", p.fish_seen == [species])
	check("the overlay is idle and George is free again", fishing.state == fz.State.IDLE and not p.busy and not fishing.visible)

	# --- a miss
	await cast_and_bite()
	var zone: float = fishing._zone
	fishing._marker = fishing._zone_center + zone / 2.0 + 0.1 if fishing._zone_center < 0.5 else fishing._zone_center - zone / 2.0 - 0.1
	fishing.press()
	await create_timer(0.6).timeout
	check("a miss catches nothing (still 1 fish)", p.junk.values().reduce(func(a, b): return a + b, 0) == 1 and not p.busy)

	# --- too early
	fish_spot().interact(p)
	await create_timer(1.3).timeout
	check("waiting for a bite", fishing.state == fz.State.WAITING)
	fishing.press()
	await create_timer(0.6).timeout
	check("pulling too early ends the cast without a fish", fishing.state == fz.State.IDLE and p.junk.values().reduce(func(a, b): return a + b, 0) == 1 and not p.busy)

	# --- the fish gets away when you are too slow
	await cast_and_bite()
	fishing._bite_left = 0.05
	await create_timer(0.7).timeout
	check("a slow reaction lets the fish escape", fishing.state == fz.State.IDLE and p.junk.values().reduce(func(a, b): return a + b, 0) == 1 and not p.busy)

	# --- Esc cancels
	fish_spot().interact(p)
	await create_timer(0.8).timeout
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.6).timeout
	check("Esc cancels the cast", fishing.state == fz.State.IDLE and not p.busy)

	# --- a button press during the first 0.3 s is ignored (the press that started the cast)
	check("the player stands near the dock after fishing", p.global_position.distance_to(stand_before) < 200.0)
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `timeout 100 godot --path . --headless --script tools/fishing_test.gd > /tmp/t.txt 2>&1; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt | head`
Expected: `FAIL  the fishing overlay exists in the HUD`, exit code 1.

- [ ] **Step 3: Create the overlay**

Create `scripts/fishing.gd`:

```gdscript
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
```

- [ ] **Step 4: Put the overlay in the HUD**

In `scripts/hud.gd` Edit:

old_string:
```
var _shop: ShopWindow
```
new_string:
```
var _shop: ShopWindow
var _fishing: Fishing
```
old_string:
```
	_shop = ShopWindow.new()
	add_child(_shop)
```
new_string:
```
	_shop = ShopWindow.new()
	add_child(_shop)
	_fishing = Fishing.new()
	add_child(_fishing)
```
old_string:
```
func is_shop_open() -> bool:
```
new_string:
```
## Starts fishing: George stands at `stand` and casts toward the water spot `target` (the dock calls this).
func start_fishing(player: Player, stand: Vector3, target: Vector3) -> void:
	_fishing.begin(player, stand, target)


func is_shop_open() -> bool:
```

- [ ] **Step 5: The dock and the fishing spot**

In `scripts/village.gd` Edit the constants. old_string:
```
const CRYPT := Vector2(0.0, -178.0)
```
new_string:
```
const CRYPT := Vector2(0.0, -178.0)
const DOCK_ANGLE := -60.0             # where on the pond shore the fishing dock stands (degrees, 0 = east, -90 = north)
```

Change the pond rocks loop so no rock stands where the dock is, without changing the random numbers. old_string:
```
		_add_box_collider(node, 0.8)


func _finish_terrain() -> void:
```
new_string:
```
		if absf(angle_difference(a, deg_to_rad(DOCK_ANGLE))) < 0.45:     # the dock stands here
			node.queue_free()
			continue
		_add_box_collider(node, 0.8)
	_build_dock(pond, 11.0)


## A small wooden dock on the shore of the pond with a bucket, and the fishing spot ([R] Ψάρεμα).
## George stands at the water end and casts toward the open water (see fishing.gd).
func _build_dock(pond: Vector2, radius: float) -> void:
	var a := deg_to_rad(DOCK_ANGLE)
	var shore := Vector3(pond.x + cos(a) * radius, 0.0, pond.y + sin(a) * radius * 0.72)
	var inland := Vector3(cos(a), 0.0, sin(a) * 0.72).normalized()     # from the water toward the land
	var dock := Node3D.new()
	dock.name = "Dock"
	dock.position = shore
	dock.rotation.y = atan2(inland.x, inland.z)                        # local +Z points inland
	add_child(dock)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.30, 0.17)
	wood.roughness = 0.9
	for i in 8:
		var plank := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.4, 0.1, 0.9)
		plank.mesh = box
		plank.material_override = wood
		plank.position = Vector3(0.0, 0.12, -3.5 + float(i))
		plank.scale = Vector3.ONE * (0.97 + 0.03 * float(i % 3))
		dock.add_child(plank)
	for z in [-3.5, 0.0, 3.5]:
		for x in [-1.15, 1.15]:
			var pile := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.11
			cyl.bottom_radius = 0.11
			cyl.height = 0.9
			pile.mesh = cyl
			pile.material_override = wood
			pile.position = Vector3(x, 0.30, z)
			dock.add_child(pile)
	_place("decoration/props/bucket_water.gltf", Vector3(1.9, 0.0, 2.6), 30.0, PS, dock)
	var stand := shore - inland * 3.2 + Vector3(0.0, 0.1, 0.0)        # the water end of the planks
	var target := shore - inland * 8.5 + Vector3(0.0, 0.09, 0.0)      # the float lands out on the open water
	var start := func(player: Player):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.start_fishing(player, stand, target)
	var spot := InteractSpot.make(Strings.PROMPT_FISH, start, 5.0)
	spot.position = shore - inland * 1.5
	add_child(spot)
	_occupy(shore.x, shore.z, 6.0)


func _finish_terrain() -> void:
```

- [ ] **Step 6: Run the tests**

Run: `godot --path . --headless --import 2>&1 | grep -i "error\|parse" | head -3` (creates `scripts/fishing.gd.uid`, expect no output), then
`timeout 100 godot --path . --headless --script tools/fishing_test.gd > /tmp/t.txt 2>&1; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: all `PASS`, no `FAIL`.

If `p.global_position.distance_to(stand_before) < 200.0` fails, the dock is not where expected; print `fish_spot().global_position` and compare with `(-70, 108)`. If a miss test is flaky because `_zone_center` lies near 0.5, the test line picks the side with room; with zone 0.07 to 0.30 and centre in `[0.06 + zone/2, 0.94 - zone/2]` there is always a side with margin 0.1 + zone/2 inside 0..1, otherwise adjust the 0.1 down to 0.05.

Regression: `timeout 100 godot --path . --headless --script tools/frontier_enter_test.gd 2>&1 | grep -c "^FAIL"` prints 0 (the village still builds). The village random generation must be unchanged: `godot --path . --resolution 1920x1080 --script tools/perftest.gd 2>&1 | grep PERF` shows about 60 fps.

- [ ] **Step 7: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add scripts/fishing.gd scripts/fishing.gd.uid scripts/hud.gd scripts/village.gd tools/fishing_test.gd tools/fishing_test.gd.uid
git commit -m "Add the fishing mini-game, the pond dock and the fishing spot"
```

---

### Task 6: Screenshots, look and frame rate

**Files:**
- Create: `tools/fishshot.gd`
- Modify (only if the look needs tuning): `scripts/village.gd`, `scripts/interiors.gd`, `scripts/fishing.gd`

- [ ] **Step 1: The screenshot driver**

Create `tools/fishshot.gd`:

```gdscript
extends SceneTree
## Screenshots of the dock, the fishing bar, the cook in the tavern and his window, plus an fps check:
##   godot --path . --resolution 1920x1080 --script tools/fishshot.gd -- tools/_shots/fishshot
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func sample(label: String, secs: float) -> void:
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		frames += 1
	print("PERF ", label, ": ", snappedf(frames / secs, 0.1), " fps")


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var hud = get_first_node_in_group("hud")
	var interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	var spot: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_FISH:
			spot = n
	# the dock from the land side
	p.teleport(spot.global_position + Vector3(8.0, 0.05, 4.0), -PI / 2.0 - 0.6)
	await create_timer(1.5).timeout
	await shot("fs_01_dock")
	await sample("dock", 3.0)
	# casting, waiting, the bite
	spot.interact(p)
	await create_timer(0.5).timeout
	await shot("fs_02_cast")
	await create_timer(1.0).timeout
	var fishing = get_first_node_in_group("fishing")
	await shot("fs_03_wait")
	fishing._wait = 0.05
	await create_timer(0.8).timeout
	await shot("fs_04_bite_bar")
	fishing._marker = fishing._zone_center
	fishing.press()
	await create_timer(0.6).timeout
	await shot("fs_05_caught")
	# the cook in the tavern
	p.gold = 200
	p.junk = {"goby": 3, "perch": 2, "trout": 2, "sunfish": 1}
	interiors.enter("tavern_shot", "tavern", Vector3(-59, 0.05, 5), 0.0, p)
	await create_timer(2.0).timeout
	await shot("fs_06_tavern_cook")
	hud.open_shop("kitchen", p)
	await create_timer(0.6).timeout
	await shot("fs_07_kitchen_meals")
	var shop = hud.find_child("ShopWindow", true, false)
	shop._set_tab("cook")
	await create_timer(0.5).timeout
	await shot("fs_08_kitchen_cook")
	shop._eat("fried")
	await create_timer(0.5).timeout
	shop.close()
	await create_timer(0.6).timeout
	await shot("fs_09_food_pill")
	quit()
```

- [ ] **Step 2: Run it and look at every picture**

Run: `mkdir -p tools/_shots/fishshot && timeout 250 godot --path . --resolution 1920x1080 --script tools/fishshot.gd -- tools/_shots/fishshot > /tmp/fs.txt 2>&1; grep "PERF\|SCRIPT ERROR" /tmp/fs.txt`
Expected: nine PNGs in `tools/_shots/fishshot/` and `PERF dock: ... fps` of about 60.

Look at each PNG (Read tool). Check: the dock sits on the shore and reaches into the pond without floating or sinking, no rock inside it, the bucket stands on the planks, the float is visible on the water, the bar panel is readable and centred above the action bar (no overlap with it), the cook stands behind the counter and is not inside a cabinet or a regular, the kitchen window rows are readable (price, `Φάε` button, red text when fish are missing), the food pill shows `Τηγανητά Ψαράκια 9:5x`.

**Visual bar check (spec risk):** if the dock, bar or cook placement is clearly wrong, fix it in this task: dock angle `DOCK_ANGLE`, plank and pile sizes in `Village._build_dock`, the cook position in the tavern `shopkeeper` entry, `PANEL` and `origin.y` in `Fishing._draw`. Re-run the driver until the pictures are right. If something cannot be fixed within this task, stop and tell Theodore what you saw with the screenshot paths.

- [ ] **Step 3: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add tools/fishshot.gd tools/fishshot.gd.uid scripts/village.gd scripts/interiors.gd scripts/fishing.gd
git commit -m "Add the fishing and kitchen screenshot driver and tune the look"
```
(Only the files that changed are staged; `git add` of an unchanged file is harmless.)

---

### Task 7: Regression run and documentation

**Files:**
- Modify: `CLAUDE.md`, `HANDOVER.md`, `CHANGELOG.md`
- No `project.godot` version bump, no tag, no push.

- [ ] **Step 1: Regression tests**

Run and confirm no `FAIL` and no `SCRIPT ERROR` in each (windowed ones need the GPU):

```bash
godot --path . --headless --import
for t in fish_data_test kitchen_test kitchen_window_test fishing_test part3_data_test part3_mobs_test frontier_enter_test frontier_build_test part3_hooks_test; do timeout 120 godot --path . --headless --script tools/$t.gd > /tmp/v_$t.txt 2>&1; echo "$t pass=$(grep -c '^PASS' /tmp/v_$t.txt) fail=$(grep -c '^FAIL' /tmp/v_$t.txt) err=$(grep -c 'SCRIPT ERROR' /tmp/v_$t.txt)"; done
for t in shoptest keepertest savetest questtest part3test; do mkdir -p tools/_shots/$t; timeout 280 godot --path . --resolution 1280x720 --script tools/$t.gd -- tools/_shots/$t > /tmp/v_$t.txt 2>&1; echo "$t exit=$? err=$(grep -c 'SCRIPT ERROR' /tmp/v_$t.txt) fail=$(grep -c '^FAIL' /tmp/v_$t.txt)"; done
godot --path . --resolution 1920x1080 --script tools/perftest.gd 2>&1 | grep PERF
```
Expected: all green; the village stays at about 60 fps. If `shoptest`/`keepertest` print numbers that differ from before because market junk now lists fish only when the bag has fish, that is expected (they use bones, rust and charms). Check that `ls "$APPDATA/Godot/app_userdata/Οι Περιπέτειες του Γιώργου στον Άγιο Βλάση/"` shows no leftover `*before*` files.

- [ ] **Step 2: CHANGELOG**

In `CHANGELOG.md`, insert above `## 0.13-beta (2026-10-13) — story part 3: the Frontier beyond the mountains`:

```markdown
## 0.14-beta (unreleased) — fishing and food
**New in this version**
- **Fishing at the pond:** a wooden dock with a bucket on the pond shore (`Village._build_dock`, **R** at the dock). A one-button timing mini-game (`scripts/fishing.gd`): cast, wait 2 to 6 s, the float dips, then press **R / Enter / Space / left click** while the marker is in the green zone of the bar (works over AnyDesk). Escape cancels; pulling too early or too late loses the fish.
- **13 fish** (`ShopData.JUNK`): five common (Γοβιός, Πέρκα, Σαζάνι, Κυπρίνος, Γριβάδι), four uncommon (Πέστροφα, Χέλι, Γλάνος, Λούτσος), three rare (Ηλιόψαρο only by day, Φεγγαρόψαρο only by night, Χρυσόψαρο του Αγίου) and the legendary **Ο Βασιλιάς της Λίμνης**. Rarer fish have a narrower zone and a faster marker. They are kept in the bag like the skeleton junk and the market buys them (6 to 150 gold).
- **Fish journal:** "Νέο είδος! (n/13)" on the first catch of a species, "Ψάρια: n/13" in the equipment tab of the hero window, saved in the save game (`fish_seen`).
- **The tavern cook Θανάσης** behind the bar (shopkeeper pattern, `ShopData.SHOPS["kitchen"]`): the kitchen window has two tabs, **Φαγητά** (Φασολάδα, Τυρόπιτα, Κρέας με Πατάτες for gold) and **Μαγείρεμα** (Τηγανητά Ψαράκια, Ψαρόσουπα, Ψητό του Αγίου, Γιορτινό του Βασιλιά from fish of a rarity plus a little gold; the cheapest fish is used first).
- **Food buffs:** a meal gives a timed buff (10 minutes, the feast 15) through a new `Stats` source `"food"` (health, regeneration, damage, defense, crit, speed, lifesteal). One meal at a time, a new one replaces the old; a pill with the meal name and the minutes left shows above the action bar. Not saved (like potion buffs).
- New sounds (synthesized): `fish_cast`, `fish_bite`, `fish_catch`, `fish_escape`, `eat`. New icons `fish` and `food`.
- New test drivers: `fish_data_test`, `kitchen_test`, `kitchen_window_test`, `fishing_test` (headless), `fishshot` (screenshots + fps).

**Not done yet:** audio tuning by ear (the new sounds are unheard), fishing in other places, carrying meals on the action bar.

```

- [ ] **Step 3: CLAUDE.md**

In `CLAUDE.md`, add before the paragraph that starts `**Village square**`:

```markdown
**Fishing and the tavern kitchen** (`fishing.gd`, `shop_data.gd` JUNK/MEALS/SHOPS["kitchen"], `shop_window.gd`, `player.gd` `add_fish`/`eat`/`prepare_meal`, `village.gd` `_build_dock`): a wooden dock on the pond shore (`Village.DOCK_ANGLE`, `_build_dock`; the pond rocks near it are skipped without changing the random sequence) with an `InteractSpot` "[R] Ψάρεμα" that calls `HUD.start_fishing(player, stand, target)`. `Fishing` is a HUD overlay (group `fishing`, state machine IDLE/CASTING/WAITING/BITE; one input: `interact`, `jump`, `ui_accept` or left click, Esc cancels; `busy` is held for 0.25 s after the end so the press that ends it cannot start the next cast). `Fishing.pick_fish(rng, night)` draws by weight, skipping `"only": "day"/"night"` species; `Fishing.hit(marker, center, zone)` decides the bar. The 13 fish are `ShopData.JUNK` entries with `"fish": true`, `rarity`, `zone`, `speed`, `weight` (so they live in `Player.junk` and the market sells them with no extra code); the journal is `Player.fish_seen` (saved as `player.fish_seen`). Meals are `ShopData.MEALS` (`"tab": "buy"|"cook"`, `"cost": {"gold", "fish": {rarity: n}}`, `"mods"` = `Stats` keys, `"duration"` seconds); `Player.prepare_meal(id)` pays gold and the cheapest fish of each rarity (`ShopData.fish_to_use`), `Player.eat(id)` sets `Player.food` ({id, time}); `_recalc()` adds `stats.set_source("food", ShopData.meal_mods(food))`, `_tick_timers` ends it and `buff_time("food")` feeds the HUD pill (`hud.gd`, shows `name m:ss`). The cook `thanasis` (`QuestData.NPCS`, `"shop": "kitchen"`) stands in the tavern (`interiors.gd` DEFS `shopkeeper`); `ShopWindow` has a kitchen layout (`shop["kind"] == "kitchen"`: tabs Φαγητά / Μαγείρεμα, rows from `_meal_row`, `_eat`). Sounds `fish_cast`, `fish_bite`, `fish_catch`, `fish_escape`, `eat`; icons `fish`, `food`. Tests: `fish_data_test`, `kitchen_test`, `kitchen_window_test`, `fishing_test` (headless), `fishshot` (screenshots, fps).
```

- [ ] **Step 4: HANDOVER.md**

Edit `HANDOVER.md` (use the Edit tool; the file is UTF-8 with Greek): in section 3 add a paragraph before `Release history:`: `**Fishing and food (unreleased, branch feature/fishing-cooking):** ...` with two sentences from the CHANGELOG entry and the pointer to CLAUDE.md and `docs/superpowers/specs|plans/2026-10-13-fishing-cooking*.md`; in section 2 add `fish_data_test`, `kitchen_test`, `kitchen_window_test`, `fishing_test`, `fishshot` to the test-driver list; in section 4 delete the whole backlog item **B** (the line starting `**B. Fishing at the pond`) and keep the other letters; in the file map add `fishing.gd` to the **UI** list and mention `shop_data.gd` now also holds fish and meals.

- [ ] **Step 5: Final state and commit**

Run: `git status --short`
Expected: only the three docs modified.

```bash
git add CLAUDE.md HANDOVER.md CHANGELOG.md
git commit -m "Document fishing and the tavern kitchen"
```

- [ ] **Step 6: Report to Theodore**

Tell him, in Greek or Greeklish and short: what exists, the test results (list any `FAIL` honestly), the fps numbers, the screenshot paths, that nothing was pushed, tagged or released, and that releasing as `0.14-beta` waits for his word. Mention the one thing only he can judge: the new sounds by ear (AnyDesk audio on).
