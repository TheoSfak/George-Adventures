# Story Part 3: The Frontier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add story part 3: an instanced outdoor region beyond the northern mountains (the **Frontier**: mountain pass, refugee camp, Fortress of Shadow) with 6 quests, 2 NPCs, 4 new enemy kinds, a mini-boss, a final boss (Μαλάκαρ) and a new "Συνεχίζεται…".

**Architecture:** A new class `Frontier` (`scripts/frontier.gd`) is built once, on first visit, at a fixed far-away origin (like `catacombs.gd`) but OUTDOORS: `Interiors` gets a second kind of transition (`enter_region` / `exit_region`) that teleports George with a fade but does not touch light or the `_inside` flag, so `DayNight`, the sky and the sun keep running. All content is data at the top of `frontier.gd`. A few existing systems (HUD minimap, sound, invasion, save) learn about `Interiors.in_region()`.

**Tech Stack:** Godot 4.7.2 / GDScript (tabs), KayKit CC0 assets already in the repo, Python 3 + numpy for the generated audio (`tools/gen_audio.py`). Spec: `docs/superpowers/specs/2026-10-13-part3-frontier-design.md`.

## Global Constraints

- **ALL IN-GAME TEXT IS GREEK** (UI, quests, dialogue, names, prompts). Code, comments and file names are English. Edit Greek files only with the Edit/Write tools (UTF-8), never with shell heredocs or Python on Windows.
- GDScript files use **tabs**. Use `var x: bool = ...` / `var s: String = dict["k"]` when a type would otherwise be inferred from a `Variant`.
- Region origin is `Vector3(-6000, 0, 6000)`. `Interiors.is_inside()` keeps meaning "inside a roofed room"; the Frontier is signalled only by the new `Interiors.in_region()`.
- Light budget about 50 lights for 60 fps (target about 20 in the Frontier). Only every third wall torch gets a light.
- In `--script` test drivers: start with `await process_frame`, set `root.get_node("/root/Quests").intro_seen = true`, never type-reference `Npc`, `Invasion`, `Minimap`, `Chest`, `SaveGame`, `GameMenu`, `Totem`, `Catacombs`, `Frontier` (use `load("res://scripts/...gd")` and untyped access). `Player`, `DayNight`, `Enemy`, `Interiors`, `QuestData`, `Strings` are safe.
- After adding a `class_name` script run `godot --headless --import` (refreshes the class cache; prints parse errors).
- Tests that call `SaveGame.save()` must back up and restore Theodore's real `user://savegame.json` (pattern from `tools/savetest.gd`).
- Git: Theodore is the sole author. **No `Co-Authored-By`, no "Generated with Claude Code", no attribution trailer** in any commit message. Commit locally per task on branch `feature/part3-frontier`. Do NOT push, tag, bump `config/version` or create a release: Theodore asks for that separately.
- The GPU (GTX 1050 Ti) cannot hold a second Godot instance while Theodore's game or editor runs. Logic tests use `--headless`. Screenshot tests need a window; if one fails with "Couldn't create Vulkan image", ask him to stop his game.
- Do not kill Theodore's Godot processes (`--editor`, or the `--remote-debug ... --editor-pid` one is his game).

## File Structure

| File | Responsibility |
|---|---|
| `scripts/frontier.gd` (new) | The region: data consts, ground, boundary, pass/camp/fortress dressing, fortress gate, pickups, NPCs, creatures, boss return. |
| `scripts/interiors.gd` | `enter_region`, `exit_region`, `in_region`, region respawn handling. |
| `scripts/village.gd` | The sealed pass gate in the northern mountains. |
| `scripts/enemies.gd`, `scripts/enemy.gd`, `scripts/projectile.gd`, `scripts/player.gd` | 4 new kinds, enrage phase, slowing shots, `Player.slow`. |
| `scripts/quest_data.gd`, `scripts/strings_el.gd`, `scripts/quest_item.gd` | Quests, NPCs, strings, the "symbol" item. |
| `scripts/hud.gd`, `scripts/minimap.gd`, `scripts/sound_manager.gd`, `scripts/invasion.gd`, `scripts/save_game.gd` | Region awareness. |
| `tools/audio/music.py`, `tools/audio/sfx.py` | `mountain` music loop, `amb_mountain` ambience, `footstep_snow`. |
| `tools/part3_data_test.gd`, `part3_mobs_test.gd`, `frontier_enter_test.gd`, `frontier_build_test.gd`, `part3_hooks_test.gd`, `part3test.gd`, `frontiershot.gd`, `passgateprobe.gd` (new) | Tests and helpers. |

Test commands used below (Git Bash, from the project folder `C:/Users/user/Desktop/George Adventures`):
- logic test: `godot --path . --headless --script tools/<name>.gd`
- screenshot test: `godot --path . --resolution 1920x1080 --script tools/<name>.gd -- tools/_shots/<name>`

---

### Task 1: Story data (strings, NPCs, quests, the "symbol" item)

**Files:**
- Modify: `scripts/strings_el.gd`, `scripts/quest_data.gd`, `scripts/quest_item.gd`, `tools/part2test.gd`
- Create: `tools/part3_data_test.gd`

**Interfaces:**
- Produces: quest ids `f_gate`, `f_guards`, `f_symbols`, `f_wall`, `f_malakar`, `f_return`; NPC ids `ilarion`, `elpida`; item id `symbol`; `Strings.BUILDING_NAMES["frontier"]`, `FRONTIER_SEALED`, `MSG_FRONTIER_SEALED`, `PROMPT_FRONTIER_BACK`, `PROMPT_FORTRESS_GATE`, `MSG_FORTRESS_SEALED`, `MSG_FORTRESS_OPEN`, `INVASION_SKIPPED`, `MSG_SLOWED`, `MALAKAR_ENRAGE`, `MSG_NO_MAP`. Objective `reach` places: `"frontier"` (arrival) and `"village"` (back in Agios Vlasis). Kill targets (defined in Task 2): `shadow_knight`, `soul_collector`, `giant_skeleton`, `malakar`.

- [ ] **Step 0: Create the working branch**

```bash
cd "C:/Users/user/Desktop/George Adventures" && git switch -c feature/part3-frontier && git status --short
```
Expected: `Switched to a new branch 'feature/part3-frontier'`; `M HANDOVER.md` may still be listed (leave it alone).

- [ ] **Step 1: Write the failing data test**

Create `tools/part3_data_test.gd`:

```gdscript
extends SceneTree
## Story part 3 data checks (no world needed):
##   godot --path . --headless --script tools/part3_data_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var q = root.get_node("/root/Quests")
	var chain := ["f_gate", "f_guards", "f_symbols", "f_wall", "f_malakar", "f_return"]
	for id in chain:
		check("quest %s exists" % id, QuestData.QUESTS.has(id))
	check("NPC ilarion exists", QuestData.NPCS.has("ilarion"))
	check("NPC elpida exists", QuestData.NPCS.has("elpida"))
	check("item symbol is named", QuestData.ITEMS.has("symbol"))
	if failed:
		quit(1)
		return

	var known_types := ["kill", "collect", "defend", "reach"]
	for id in chain:
		var qd: Dictionary = QuestData.QUESTS[id]
		check("%s: giver and hand-in are NPCs" % id, QuestData.NPCS.has(qd["giver"]) and QuestData.NPCS.has(qd["turn_in"]))
		check("%s: has offer, progress and complete text" % id, qd["offer"].size() > 0 and qd["progress"].size() > 0 and qd["complete"].size() > 0)
		for req in qd["requires"]:
			check("%s: requirement %s exists" % [id, req], QuestData.QUESTS.has(req))
		for o in qd["objectives"]:
			check("%s: objective type %s is known" % [id, o["type"]], o["type"] in known_types)
	check("necro no longer ends the game", not QuestData.QUESTS["necro"].has("ends_game"))
	var enders := []
	for id in QuestData.QUESTS:
		if QuestData.QUESTS[id].get("ends_game", false):
			enders.append(id)
	check("only f_return ends the game (found %s)" % str(enders), enders == ["f_return"])
	check("Strings has the frontier name", Strings.BUILDING_NAMES.has("frontier"))

	# --- availability chain
	q.reset()
	check("f_gate is locked at the start", q.state["f_gate"] == q.S.LOCKED)
	for id in QuestData.QUESTS:
		if not id.begins_with("f_"):
			q.state[id] = q.S.DONE
	q._refresh_availability()
	check("f_gate is available once necro is done", q.state["f_gate"] == q.S.AVAILABLE)
	check("Stavros shows a '!'", q.marker_for("stavros") == "!")
	check("f_guards and f_symbols are still locked", q.state["f_guards"] == q.S.LOCKED and q.state["f_symbols"] == q.S.LOCKED)

	q.state["f_gate"] = q.S.ACTIVE
	q.report_reach("frontier")
	check("arriving in the frontier readies f_gate", q.state["f_gate"] == q.S.READY)
	check("Ilarion shows a '?'", q.marker_for("ilarion") == "?")
	q.state["f_gate"] = q.S.DONE
	q._refresh_availability()
	check("f_guards and f_symbols open after f_gate", q.state["f_guards"] == q.S.AVAILABLE and q.state["f_symbols"] == q.S.AVAILABLE)
	check("f_wall waits for both", q.state["f_wall"] == q.S.LOCKED)
	q.state["f_guards"] = q.S.DONE
	q._refresh_availability()
	check("f_wall still waits for the symbols", q.state["f_wall"] == q.S.LOCKED)
	q.state["f_symbols"] = q.S.DONE
	q._refresh_availability()
	check("f_wall opens", q.state["f_wall"] == q.S.AVAILABLE)
	q.state["f_wall"] = q.S.DONE
	q._refresh_availability()
	check("f_malakar opens", q.state["f_malakar"] == q.S.AVAILABLE)
	q.state["f_malakar"] = q.S.DONE
	q._refresh_availability()
	check("f_return opens", q.state["f_return"] == q.S.AVAILABLE)
	q.state["f_return"] = q.S.ACTIVE
	q.report_reach("village")
	check("returning to the village readies f_return", q.state["f_return"] == q.S.READY)
	q.reset()
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `godot --path . --headless --script tools/part3_data_test.gd`
Expected: `FAIL  quest f_gate exists` (and the others of the chain), then exit code 1.

- [ ] **Step 3: Add the strings**

In `scripts/strings_el.gd`, Edit the `BUILDING_NAMES` entry (the dictionary entries are indented with ONE tab):

old_string:
```
"catacombs": "Κατακόμβη",
```
new_string:
```
"catacombs": "Κατακόμβη",
	"frontier": "Βουνίσιο Πέρασμα",
```

Then append at the END of `scripts/strings_el.gd` (after `GUARDS_ARRIVE`):

```gdscript

# --- story part 3: the Frontier beyond the mountains
const FRONTIER_SEALED := "Σφραγισμένη Πύλη του Περάσματος"
const MSG_FRONTIER_SEALED := "Η Πύλη του Περάσματος είναι σφραγισμένη. Μίλησε πρώτα με τον Παπά-Σταύρο."
const PROMPT_FRONTIER_BACK := "[R] Επιστροφή στον Άγιο Βλάση"
const PROMPT_FORTRESS_GATE := "Η Πύλη του Φρουρίου"
const MSG_FORTRESS_SEALED := "Η πύλη του Φρουρίου είναι σφραγισμένη. Βρες τα τρία Σύμβολα της Σκιάς."
const MSG_FORTRESS_OPEN := "Τα Σύμβολα έσπασαν τη σφραγίδα. Η πύλη του Φρουρίου άνοιξε!"
const INVASION_SKIPPED := "Ο Παπά-Σταύρος κράτησε το χωριό χωρίς εσένα."
const MSG_SLOWED := "Η ψυχή σε βαραίνει!"
const MALAKAR_ENRAGE := "Ο Μαλάκαρ καλεί τη Σκιά!"
const MSG_NO_MAP := "Ο χάρτης του χωριού δεν δείχνει αυτά τα βουνά."
```

- [ ] **Step 4: Add the item name, the model and the NPCs**

In `scripts/quest_data.gd` Edit the doc comment and the `ITEMS` table:

old_string:
```
##   {"type": "reach",   "place": "catacombs", "count": 1, "text": "..."}   (Quests.report_reach)
```
new_string:
```
##   {"type": "reach",   "place": "catacombs" | "frontier" | "village", "count": 1, "text": "..."}   (Quests.report_reach)
```

old_string:
```
	"page": "Βρήκες μια σελίδα της Ευχής του Αγίου",
}
```
new_string:
```
	"page": "Βρήκες μια σελίδα της Ευχής του Αγίου",
	"symbol": "Βρήκες ένα Σύμβολο της Σκιάς",
}
```

Add the two NPCs. Edit:

old_string (one tab of indentation, a single line):
```
# Shopkeepers: they stand inside the market and the blacksmith (see interiors.gd).
```
new_string (the NPC entries are at ONE tab, their keys at TWO, list items at THREE):
```
# Part 3: the refugee camp in the Frontier (see frontier.gd).
	"ilarion": {
		"name": "Μοναχός Ιλαρίων",
		"model": "res://assets/characters/Rogue_Hooded.glb",
		"show": [],
		"idle": [
			"Ο Άγιος να σε φυλάει, ξένε. Εδώ πάνω ο αέρας κόβει και το σκοτάδι ακούει.",
			"Δεν κοιμάμαι από τη νύχτα που έπεσε το μοναστήρι. Κάθε φορά που κλείνω τα μάτια, ακούω τον Ευστάθιο να ψιθυρίζει.",
		],
	},
	"elpida": {
		"name": "Ελπίδα η Κυνηγός",
		"model": "res://assets/characters/Rogue.glb",
		"show": ["1H_Crossbow"],
		"idle": [
			"Ξέρω κάθε μονοπάτι σε αυτά τα βουνά. Και κάθε σκιά που δεν πρέπει να πλησιάσεις.",
			"Οι πρόσφυγες κοιμούνται ήσυχα όσο καίει η φωτιά. Κράτα τη φωτιά αναμμένη.",
		],
	},
	# Shopkeepers: they stand inside the market and the blacksmith (see interiors.gd).
```
(Because `old_string` has no leading tab, the first inserted line keeps the file's existing tab; every following line carries its own tabs as shown.)

In `scripts/quest_item.gd` Edit `MODELS`:

old_string:
```
	"page": {"path": "res://assets/furniture/book_single.gltf", "scale": 3.0, "lift": 0.9},
}
```
new_string:
```
	"page": {"path": "res://assets/furniture/book_single.gltf", "scale": 3.0, "lift": 0.9},
	"symbol": {"path": "res://assets/graveyard/plaque_candles.gltf", "scale": 3.0, "lift": 0.9},
}
```

- [ ] **Step 5: Add the six quests and stop Part 2 from ending the game**

In `scripts/quest_data.gd` Edit the end of the `necro` quest. old_string:

```
		"reward": {"xp": 1500, "gold": 400, "potions": 4, "damage": 6},
		"ends_game": true,
	},
}
```
new_string:

```
		"reward": {"xp": 1500, "gold": 400, "potions": 4, "damage": 6},
	},

	# ------------------------------------------------ Part 3: the Frontier ----
	"f_gate": {
		"title": "Η Πύλη του Περάσματος",
		"giver": "stavros",
		"turn_in": "ilarion",
		"requires": ["necro"],
		"objectives": [
			{"type": "reach", "place": "frontier", "count": 1, "text": "Πέρασε την Πύλη του Περάσματος"},
		],
		"offer": [
			"Γιώργο, ο Ευστάθιος δεν ψιθύρισε μόνο ένα όνομα. Ψιθύρισε και έναν τόπο: το Φρούριο της Σκιάς, ψηλά πάνω από το Πέρασμα, πέρα από τα βόρεια βουνά.",
			"Εκεί ζει ο Μαλάκαρ, ο Σκοτεινός Άρχοντας, ο παλιός δάσκαλος του Ευσταθίου. Αυτός του έδειξε πώς σπάνε οι σφραγίδες· και δεν θα σταματήσει στις δικές μας.",
			"Η Πύλη του Περάσματος είναι στα βόρεια βουνά, ανατολικά της Παλιάς Κρύπτης. Την ξεσφράγισα για σένα. Ψάξε για τον Μοναχό Ιλαρίωνα· επέζησε από το μοναστήρι του Ευσταθίου και θα σε οδηγήσει.",
		],
		"progress": [
			"Η Πύλη του Περάσματος είναι στα βόρεια βουνά, ανατολικά της Παλιάς Κρύπτης. Πέρασέ την και ψάξε για τον Μοναχό Ιλαρίωνα.",
		],
		"complete": [
			"Ο Άγιος να είναι δοξασμένος! Λοιπόν είναι αλήθεια: ο Παπά-Σταύρος έστειλε τον ήρωα. Εγώ είμαι ο Ιλαρίων, μοναχός του Ευσταθίου. Ή μάλλον, ήμουν.",
			"Όταν ο ηγούμενος έπεσε στη Σκιά, οι περισσότεροι αδελφοί τον ακολούθησαν. Εμείς που φύγαμε βρήκαμε καταφύγιο εδώ, στο Πέρασμα. Η Ελπίδα η Κυνηγός μας φυλάει.",
			"Πιο πάνω στέκεται το Φρούριο της Σκιάς. Ο Μαλάκαρ το έχτισε με τα κόκαλα των νεκρών. Θα σου πω τι πρέπει να κάνουμε, αλλά πρώτα ξεκουράσου δίπλα στη φωτιά.",
		],
		"reward": {"xp": 500, "gold": 150, "potions": 2},
	},
	"f_guards": {
		"title": "Οι Φρουροί του Περάσματος",
		"giver": "ilarion",
		"turn_in": "ilarion",
		"requires": ["f_gate"],
		"objectives": [
			{"type": "kill", "target": "shadow_knight", "count": 5, "text": "Νίκησε Ιππότες της Σκιάς"},
			{"type": "kill", "target": "soul_collector", "count": 3, "text": "Νίκησε Ψυχοσυλλέκτες"},
		],
		"offer": [
			"Το Πέρασμα είναι γεμάτο φρουρούς του Μαλάκαρ. Οι Ιππότες της Σκιάς φορούν μωβ πανοπλία και τα χτυπήματά τους γκρεμίζουν πέτρες.",
			"Οι Ψυχοσυλλέκτες κρατούν γαλάζια φλόγα. Όποιον πετύχουν, η ψυχή του βαραίνει και τρέχει σαν μέσα στη λάσπη. Σκότωσε πέντε Ιππότες και τρεις Ψυχοσυλλέκτες για να μπορούμε να κινηθούμε.",
		],
		"progress": [
			"Πέντε Ιππότες της Σκιάς και τρεις Ψυχοσυλλέκτες, Γιώργο. Κράτα την απόσταση από τις γαλάζιες φλόγες· σε επιβραδύνουν.",
		],
		"complete": [
			"Ησύχασε το Πέρασμα. Για πρώτη φορά ακούω τον άνεμο και όχι τα κόκαλα. Πάρε αυτά, είναι από τις προμήθειες των προσφύγων.",
			"Μένουν τα Σύμβολα της Σκιάς· η Ελπίδα ξέρει περισσότερα.",
		],
		"reward": {"xp": 900, "gold": 200, "potions": 2, "speed": 1},
	},
	"f_symbols": {
		"title": "Τα Σύμβολα της Σκιάς",
		"giver": "elpida",
		"turn_in": "elpida",
		"requires": ["f_gate"],
		"objectives": [
			{"type": "collect", "item": "symbol", "count": 3, "text": "Βρες τα Σύμβολα της Σκιάς"},
		],
		"offer": [
			"Εσύ είσαι ο Γιώργος; Η Ελπίδα. Ο Ιλαρίων λέει πως σε περίμενε. Εγώ λέω να δούμε πρώτα αν ξέρεις να πολεμάς.",
			"Η πύλη του Φρουρίου δεν ανοίγει με σπαθί. Τη σφράγισε ο Μαλάκαρ με τρία Σύμβολα της Σκιάς, κρυμμένα γύρω από το Πέρασμα. Αν τα φέρεις εδώ, ο Ιλαρίων ξέρει πώς να σπάσει τη σφραγίδα.",
			"Θα δεις χρυσό φως ανάμεσα στα βράχια. Πρόσεχε τις ενέδρες· οι φρουροί τα φυλάνε.",
		],
		"progress": [
			"Τρία Σύμβολα, Γιώργο. Ψάξε για χρυσό φως γύρω από το Πέρασμα, στα βράχια και στις άκρες του μονοπατιού.",
		],
		"complete": [
			"Και τα τρία! Νιώθω τη σφραγίδα του Φρουρίου να τρέμει. Δεν πίστευα ότι θα τα έβρισκες τόσο γρήγορα.",
			"Η πύλη θα ανοίξει τώρα. Πρόσεχε εκεί μέσα, Γιώργο· τον περιμένει ο Γίγαντας του Τείχους.",
		],
		"reward": {"xp": 900, "gold": 200, "power": 1, "damage": 4},
	},
	"f_wall": {
		"title": "Το Τείχος",
		"giver": "ilarion",
		"turn_in": "ilarion",
		"requires": ["f_guards", "f_symbols"],
		"objectives": [
			{"type": "kill", "target": "giant_skeleton", "count": 1, "text": "Νίκησε τον Γιγάντιο Σκελετό"},
		],
		"offer": [
			"Η πύλη ανοίγει στην αυλή του Φρουρίου. Εκεί φυλάει ο Γιγάντιος Σκελετός, ο πρώτος νεκρός που σηκώθηκε από τον Μαλάκαρ. Είναι τριπλάσιος από έναν άνθρωπο και το τσεκούρι του σπάει πέτρες.",
			"Χτύπα και απομακρύνσου, μην του δώσεις ευκαιρία να σε πιάσει. Και πάρε φίλτρα μαζί σου.",
		],
		"progress": [
			"Ο Γιγάντιος Σκελετός περιμένει στην αυλή του Φρουρίου, πέρα από την πύλη. Χτύπα, απομακρύνσου, χτύπα ξανά.",
		],
		"complete": [
			"Έπεσε το Τείχος! Το νιώθω· το Φρούριο δεν έχει πια φρουρά στην αυλή.",
			"Μένει ο Μαλάκαρ. Θα σε περιμένει στο βάθος της αυλής, μπροστά στον πύργο. Να είσαι έτοιμος.",
		],
		"reward": {"xp": 1500, "gold": 300, "potions": 3},
	},
	"f_malakar": {
		"title": "Ο Άρχοντας του Βουνού",
		"giver": "elpida",
		"turn_in": "ilarion",
		"requires": ["f_wall"],
		"objectives": [
			{"type": "kill", "target": "malakar", "count": 1, "text": "Νίκησε τον Μαλάκαρ"},
		],
		"offer": [
			"Ο πύργος του Μαλάκαρ είναι στο βάθος της αυλής. Οι κατάσκοποί μου λένε πως δεν είναι πια ο άνθρωπος που ήταν. Τρέφεται από τις ψυχές που μαζεύει.",
			"Θα σε χτυπά από μακριά με σκοτεινές σφαίρες. Όταν τραυματιστεί βαριά, θα καλέσει τους Ιππότες της Σκιάς. Μη σταματάς να κινείσαι.",
		],
		"progress": [
			"Ο Μαλάκαρ είναι μπροστά στον πύργο, στο βάθος της αυλής. Όταν τον πληγώσεις βαριά, θα καλέσει βοήθεια.",
		],
		"complete": [
			"Η Σκιά έφυγε από τον ουρανό! Τα βουνά ανάσαναν, Γιώργο. Ο Μαλάκαρ δεν θα σπάσει άλλη σφραγίδα.",
			"Πάρε τούτο το δώρο των προσφύγων. Και γύρνα στον Παπά-Σταύρο· περιμένει νέα.",
		],
		"reward": {"xp": 3000, "gold": 600, "potions": 4, "damage": 8},
	},
	"f_return": {
		"title": "Η Επιστροφή",
		"giver": "ilarion",
		"turn_in": "stavros",
		"requires": ["f_malakar"],
		"objectives": [
			{"type": "reach", "place": "village", "count": 1, "text": "Γύρνα στον Άγιο Βλάση"},
		],
		"offer": [
			"Ο δρόμος είναι ελεύθερος. Γύρνα στον Άγιο Βλάση, Γιώργο, και πες στον Παπά-Σταύρο ότι ο Μαλάκαρ έπεσε.",
		],
		"progress": [
			"Ο δρόμος για τον Άγιο Βλάση είναι ανοιχτός. Πέρασε την Πύλη του Περάσματος και βρες τον Παπά-Σταύρο.",
		],
		"complete": [
			"Γιώργο! Ο Άγιος να είναι δοξασμένος… Οι σφραγίδες του βουνού ησύχασαν. Το ένιωσα στα κόκαλά μου.",
			"Έσωσες το χωριό, την Κρύπτη και τώρα και τα βουνά. Όμως ο Μαλάκαρ δεν ήταν μόνος· κάποιος του έδωσε τη γνώση, όπως εκείνος την έδωσε στον Ευστάθιο. Αυτή η ιστορία δεν τελείωσε ακόμα.",
		],
		"reward": {"xp": 1000, "gold": 300, "potions": 2},
		"ends_game": true,
	},
}
```

- [ ] **Step 6: Keep `part2test` valid (Part 2 no longer ends the game)**

In `tools/part2test.gd` Edit the quest-skipping loop:

old_string:
```
		if id in ["descent", "cguards", "pages", "wardens", "necro"]:
			continue
```
new_string:
```
		if id in ["descent", "cguards", "pages", "wardens", "necro"] or id.begins_with("f_"):
			continue
```

and the ending:

old_string:
```
	await talk("stavros", "p2_06_stavros_end")
	await create_timer(4.5).timeout
	await shot("p2_07_the_end")
	check("part 2 finished: " + states(), q.state["necro"] == q.S.DONE and finished[0])
```
new_string:
```
	await talk("stavros", "p2_06_stavros_end")
	await create_timer(2.0).timeout
	await shot("p2_07_part3_offer")
	check("part 2 finished and hands over to part 3 (no ending yet): " + states(), q.state["necro"] == q.S.DONE and not finished[0] and q.state["f_gate"] == q.S.AVAILABLE)
```

- [ ] **Step 7: Run the data test and the part 2 regression**

Run: `godot --path . --headless --script tools/part3_data_test.gd`
Expected: every line `PASS`, no `FAIL`, exit code 0.

Run: `godot --path . --headless --import` then `godot --path . --resolution 1280x720 --script tools/part2test.gd -- tools/_shots/part2`
Expected: all `PASS` (windowed; needs the GPU). If the window cannot open, run it later together with the other windowed tests in Task 9.

- [ ] **Step 8: Commit**

```bash
git add scripts/strings_el.gd scripts/quest_data.gd scripts/quest_item.gd tools/part2test.gd tools/part3_data_test.gd tools/part3_data_test.gd.uid
git commit -m "Add story part 3 data: Frontier quests, NPCs, strings and the Symbol of Shadow item"
```
(If `tools/part3_data_test.gd.uid` does not exist yet, run `godot --headless --import` first, or omit it from `git add`.)

---

### Task 2: New enemies, enrage phase and slowing shots

**Files:**
- Modify: `scripts/enemies.gd`, `scripts/enemy.gd`, `scripts/projectile.gd`, `scripts/player.gd`, `scripts/sound_manager.gd`
- Create: `tools/part3_mobs_test.gd`

**Interfaces:**
- Consumes: Task 1 quest ids (`f_wall`, `f_malakar`) and `Strings.MSG_SLOWED`, `Strings.MALAKAR_ENRAGE`.
- Produces: `Enemies.KINDS` keys `shadow_knight`, `soul_collector`, `giant_skeleton`, `malakar` (bosses carry `"quest"`); `Enemy` exports `enrage_below`, `enrage_summon`, `projectile_slows` and field `_enraged`; `Projectile.slows`; `Player.slow(seconds: float)`, `Player.is_slowed() -> bool`; projectile kind `"soul"`.

- [ ] **Step 1: Write the failing test**

Create `tools/part3_mobs_test.gd`:

```gdscript
extends SceneTree
## The new Frontier creatures, the enrage phase and the slowing shot:
##   godot --path . --headless --script tools/part3_mobs_test.gd
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
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var spawner = get_first_node_in_group("enemy_spawner")
	for kind in ["shadow_knight", "soul_collector", "giant_skeleton", "malakar"]:
		check("KINDS has %s" % kind, spawner.KINDS.has(kind))
	if failed:
		quit(1)
		return
	check("giant skeleton belongs to f_wall", spawner.KINDS["giant_skeleton"]["quest"] == "f_wall")
	check("malakar belongs to f_malakar", spawner.KINDS["malakar"]["quest"] == "f_malakar")
	check("both are listed as bosses", "giant_skeleton" in spawner.BOSSES and "malakar" in spawner.BOSSES)

	var at := Vector3(0.0, 0.05, 40.0)
	var knight = spawner.spawn_extra("shadow_knight", at)
	check("shadow knight spawns with 190 health", knight != null and knight.max_health == 190.0)
	var caster = spawner.spawn_extra("soul_collector", at + Vector3(12, 0, 0))
	check("soul collector shoots slowing souls", caster != null and caster.ranged and caster.projectile_slows and caster.projectile_kind == "soul")
	var giant = spawner.spawn_extra("giant_skeleton", at + Vector3(0, 0, 12))
	check("giant skeleton is big and slow", giant != null and giant.model_scale > 2.0 and giant.chase_speed < 4.0)

	var boss = spawner.spawn_extra("malakar", at + Vector3(-12, 0, 0))
	check("malakar starts without helpers", boss != null and boss.summon_kind == "" and not boss._enraged)
	boss.take_damage(boss.max_health * 0.40, boss.global_position + Vector3(0, 0, 3))
	check("not enraged at 60% health", not boss._enraged)
	boss.take_damage(boss.max_health * 0.15, boss.global_position + Vector3(0, 0, 3))
	check("enraged below 50% health and calls shadow knights", boss._enraged and boss.summon_kind == "shadow_knight")

	p.slow(0.5)
	check("George is slowed", p.is_slowed())
	await create_timer(0.8).timeout
	check("the slow wears off", not p.is_slowed())
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `godot --path . --headless --script tools/part3_mobs_test.gd`
Expected: `FAIL  KINDS has shadow_knight` (…) and exit code 1.

- [ ] **Step 3: Add the four kinds**

In `scripts/enemies.gd` Edit:

old_string:
```
		"xp_reward": 900, "gold_min": 200, "gold_max": 260, "potion_chance": 1.0,
	},
}
```
new_string:
```
		"xp_reward": 900, "gold_min": 200, "gold_max": 260, "potion_chance": 1.0,
	},
	# --- the Frontier beyond the mountains (placed by frontier.gd)
	"shadow_knight": {
		"kind_id": "shadow_knight", "tint_color": Color(0.30, 0.20, 0.55, 0.34), "model_scale": 1.3,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 190.0, "attack_damage": 24.0, "chase_speed": 3.4, "attack_range": 2.6,
		"attack_hit_time": 0.65, "attack_cooldown": 2.0, "aggro_range": 15.0, "leash_range": 32.0,
		"xp_reward": 110, "gold_min": 12, "gold_max": 26, "potion_chance": 0.5,
	},
	# Soul collector: a caster whose blue souls slow George down
	"soul_collector": {
		"kind_id": "soul_collector", "tint_color": Color(0.25, 0.55, 0.95, 0.32),
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "soul", "projectile_slows": true, "shoot_anim": "Spellcast_Shoot", "projectile_speed": 11.0,
		"ranged_min": 8.0, "ranged_max": 16.0, "aggro_range": 20.0, "leash_range": 34.0,
		"max_health": 85.0, "attack_damage": 16.0, "chase_speed": 3.9, "attack_cooldown": 2.5,
		"xp_reward": 100, "gold_min": 12, "gold_max": 26, "potion_chance": 0.45,
	},
	# Mini-boss of the fortress courtyard
	"giant_skeleton": {
		"kind_id": "giant_skeleton", "respawn": false, "quest": "f_wall", "tint_color": Color(0.55, 0.50, 0.65, 0.28),
		"display_name": "Γιγάντιος Σκελετός", "model_scale": 2.6,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Axe.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 1600.0, "attack_damage": 34.0, "chase_speed": 3.6, "attack_range": 4.4,
		"attack_hit_time": 0.8, "attack_cooldown": 2.4, "attack_anim": "1H_Melee_Attack_Chop",
		"aggro_range": 24.0, "leash_range": 44.0, "patrol_radius": 3.0, "need_los": true,
		"xp_reward": 700, "gold_min": 120, "gold_max": 170, "potion_chance": 1.0,
	},
	# The last boss: orbs from afar, and when he is hurt badly he calls shadow knights and speeds up
	"malakar": {
		"kind_id": "malakar", "respawn": false, "quest": "f_malakar", "tint_color": Color(0.45, 0.10, 0.70, 0.36),
		"display_name": "Μαλάκαρ ο Σκοτεινός Άρχοντας", "model_scale": 2.5,
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 13.0,
		"ranged_min": 7.0, "ranged_max": 16.0, "aggro_range": 28.0, "leash_range": 50.0, "patrol_radius": 2.0, "need_los": true,
		"max_health": 3200.0, "attack_damage": 36.0, "chase_speed": 4.4, "attack_cooldown": 2.0,
		"enrage_below": 0.5, "enrage_summon": "shadow_knight", "summon_interval": 12.0, "summon_max": 3,
		"xp_reward": 1800, "gold_min": 300, "gold_max": 380, "potion_chance": 1.0,
	},
}
```

and the boss list:

old_string:
```
const BOSSES: Array[String] = ["captain", "king", "warden_bone", "warden_flame", "warden_shadow", "necromancer"]
```
new_string:
```
const BOSSES: Array[String] = ["captain", "king", "warden_bone", "warden_flame", "warden_shadow", "necromancer", "giant_skeleton", "malakar"]
```

- [ ] **Step 4: Teach `Enemy` the enrage phase and the slowing shot**

In `scripts/enemy.gd`:

old_string:
```
@export var summon_max := 4
```
new_string:
```
@export var summon_max := 4
@export var enrage_below := 0.0       # health share (0..1) below which a boss enrages
@export var enrage_summon := ""       # helper kind an enraged boss starts calling
@export var projectile_slows := false # its shots slow George down
```

old_string:
```
var _summons: Array[Enemy] = []
```
new_string:
```
var _summons: Array[Enemy] = []
var _enraged := false
```

Replace the tint block in `_load_model`. old_string:
```
	if tint_color.a > 0.0:
		var wash := StandardMaterial3D.new()
		wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wash.albedo_color = tint_color
		wash.cull_mode = BaseMaterial3D.CULL_BACK
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = wash
```
new_string:
```
	if tint_color.a > 0.0:
		_apply_tint(model, tint_color)
```

Add the helper after `_attach` (insert before `func _build_health_bar`). old_string:
```
func _build_health_bar() -> void:
```
new_string:
```
## A colour wash over every mesh of the model (the colour of the creature's kind).
func _apply_tint(model: Node3D, color: Color) -> void:
	var wash := StandardMaterial3D.new()
	wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wash.albedo_color = color
	wash.cull_mode = BaseMaterial3D.CULL_BACK
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = wash


func _build_health_bar() -> void:
```

Shots that slow (the line sits at ONE tab inside `_fire`; match it without leading whitespace). old_string:
```
get_parent().add_child(Projectile.make(projectile_kind, muzzle, aim, projectile_speed, attack_damage))
```
new_string:
```
var shot := Projectile.make(projectile_kind, muzzle, aim, projectile_speed, attack_damage)
	shot.slows = projectile_slows
	get_parent().add_child(shot)
```

Enrage trigger in `take_damage`. old_string:
```
		_die(away)
		return
	Sfx.play("skel_hurt", global_position)
```
new_string:
```
		_die(away)
		return
	if enrage_below > 0.0 and not _enraged and health / max_health <= enrage_below:
		_enrage()
	Sfx.play("skel_hurt", global_position)
```

Roar for the new bosses. old_string:
```
		"captain", "king":
			Sfx.play("boss_roar", global_position)
```
new_string:
```
		"captain", "king", "giant_skeleton", "malakar":
			Sfx.play("boss_roar", global_position)
```

Add `_enrage` before `_summon`. old_string:
```
## Calls two helpers from the parent spawner (the necromancer's minions).
```
new_string:
```
## The second phase of a boss: faster, hits more often, glows redder and starts calling helpers.
func _enrage() -> void:
	_enraged = true
	chase_speed *= 1.25
	attack_cooldown *= 0.7
	if enrage_summon != "":
		summon_kind = enrage_summon
		_summon_timer = 0.5
	_apply_tint(_model_root, Color(0.85, 0.12, 0.20, 0.42))
	Sfx.play("boss_roar", global_position)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.message.emit(Strings.MALAKAR_ENRAGE)


## Calls two helpers from the parent spawner (the necromancer's minions).
```

- [ ] **Step 5: Projectile "soul" and the slow on hit**

In `scripts/projectile.gd`:

old_string:
```
var damage := 10.0
```
new_string:
```
var damage := 10.0
var slows := false              # a hit also slows George down (soul collectors)
```
old_string:
```
		mat.albedo_color = Color(0.65, 1.0, 0.45)
```
new_string:
```
		mat.albedo_color = Color(0.45, 0.72, 1.0) if kind == "soul" else Color(0.65, 1.0, 0.45)
```
old_string:
```
		glow.light_color = Color(0.55, 1.0, 0.4)
```
new_string:
```
		glow.light_color = Color(0.40, 0.65, 1.0) if kind == "soul" else Color(0.55, 1.0, 0.4)
```
old_string:
```
			_player.take_damage(damage, _player.global_position - velocity.normalized() * 3.0)
```
new_string:
```
			_player.take_damage(damage, _player.global_position - velocity.normalized() * 3.0)
			if slows:
				_player.slow(2.5)
```

- [ ] **Step 6: `Player.slow`**

In `scripts/player.gd`:

old_string:
```
var _stun := 0.0
var _attack_serial := 0
```
new_string:
```
var _stun := 0.0
var _slow_time := 0.0           # a soul collector's shot: George moves slower for a while
var _attack_serial := 0
```
old_string:
```
	_stun = maxf(_stun - delta, 0.0)
```
new_string:
```
	_stun = maxf(_stun - delta, 0.0)
	_slow_time = maxf(_slow_time - delta, 0.0)
```
old_string:
```
	if _speed_time > 0.0:
		speed *= 1.4
```
new_string:
```
	if _speed_time > 0.0:
		speed *= 1.4
	if _slow_time > 0.0:
		speed *= 0.6
```
old_string:
```
## Quest rewards: {"xp": N, "gold": N, "potions": N, "damage": N}
```
new_string:
```
## Slows George for `seconds` (-40% speed).
func slow(seconds: float) -> void:
	_slow_time = maxf(_slow_time, seconds)
	message.emit(Strings.MSG_SLOWED)


func is_slowed() -> bool:
	return _slow_time > 0.0


## Quest rewards: {"xp": N, "gold": N, "potions": N, "damage": N}
```

- [ ] **Step 7: Boss fight music for the new bosses**

In `scripts/sound_manager.gd`:

old_string:
```
["captain", "king", "warlord", "warden_bone", "warden_flame", "warden_shadow", "necromancer"]
```
new_string:
```
["captain", "king", "warlord", "warden_bone", "warden_flame", "warden_shadow", "necromancer", "giant_skeleton", "malakar"]
```

- [ ] **Step 8: Run the test and the compile check**

Run: `godot --path . --headless --quit-after 200`
Expected: no `SCRIPT ERROR` / `Parse Error` lines.

Run: `godot --path . --headless --script tools/part3_mobs_test.gd`
Expected: all `PASS`, exit code 0.

- [ ] **Step 9: Commit**

```bash
git add scripts/enemies.gd scripts/enemy.gd scripts/projectile.gd scripts/player.gd scripts/sound_manager.gd tools/part3_mobs_test.gd tools/part3_mobs_test.gd.uid
git commit -m "Add the Frontier creatures: shadow knight, soul collector, giant skeleton and Malakar with an enrage phase"
```

---

### Task 3: Audio: mountain music, mountain wind, snow footsteps

**Files:**
- Modify: `tools/audio/music.py`, `tools/audio/sfx.py`
- Generated (commit them): `assets/audio/music/mountain.wav`, `assets/audio/sfx/amb_mountain.wav`, `assets/audio/sfx/footstep_snow_1..4.wav`, `scripts/music_ids.gd`, `scripts/sfx_ids.gd`

**Interfaces:**
- Produces: music id `mountain`; ambience loop id `amb_mountain`; sound `footstep_snow` (4 variants).

- [ ] **Step 1: Add the music recipe**

In `tools/audio/music.py` Edit:

old_string:
```
def make(name):
```
new_string:
```
# --- the Frontier beyond the mountains: cold, wide, a lonely horn -----------------
SPECS["mountain"] = dict(
    key=45, mode="minor", bpm=58, bars=16, seed=21, reverb=(3.0, 0.45),
    chords=[(0, "min"), (8, "maj"), (3, "maj"), (10, "maj")],
    parts=[
        dict(type="drone", gain=0.22, oct=-24, fifth=0.3),
        dict(type="pad", inst="strings", gain=0.38, every=2, oct=-12),
        dict(type="pad", inst="choir", vowel="o", gain=0.25, every=4, oct=0, voices=3),
        dict(type="bells", every=4, oct=-12, gain=0.35, dur=5.0, fifth=True),
        dict(type="melody", inst="brass", range=(55, 70), scale="minor", seed=88, gain=0.35, phrase_bars=4, rest_every=2, legato=1.4,
             rhythms=[[(0, 3), (3, 1)], [(0, 2), (2, 2)]]),
    ])


def make(name):
```

- [ ] **Step 2: Add the snow footsteps and the mountain wind**

In `tools/audio/sfx.py` Edit:

old_string:
```
sfx("footstep_heavy", 2, 0.5)(_step("h", 200, 1000, 0.3, 1.6, 0.09))
```
new_string:
```
sfx("footstep_heavy", 2, 0.5)(_step("h", 200, 1000, 0.3, 1.6, 0.09))
sfx("footstep_snow", 4, 0.3)(_step("n", 300, 2200, 0.2, 0.15, 0.07))
```
old_string:
```
@sfx("fire_loop", 1, 0.5, True)
```
new_string:
```
@sfx("amb_mountain", 1, 0.5, True)
def _(rng, i):
    d = 22.0
    out = wind(d + 2, rng, 1.5)
    out += S.bandpass(nz(d + 2, rng), 1400, 500) * 0.05 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * S.t_axis(d + 2)))
    return loopable(out, 2.0)


@sfx("fire_loop", 1, 0.5, True)
```

- [ ] **Step 3: Generate**

Run: `python tools/gen_audio.py sfx snow mountain`
Expected: `sfx: 5 files written to ...` (4 snow steps + amb_mountain).

Run: `python tools/gen_audio.py music mountain`
Expected: a line `music mountain   ... s`.

- [ ] **Step 4: Verify the index and the other files did not change**

Run: `git status --short assets scripts/sfx_ids.gd scripts/music_ids.gd`
Expected: new untracked `.wav` files for `mountain`, `amb_mountain`, `footstep_snow_1..4`; modified `scripts/sfx_ids.gd` (new keys `amb_mountain` in VARIANTS and LOOPS, `footstep_snow`: 4) and `scripts/music_ids.gd` (`"mountain"` appended). No other `.wav` shows as modified (the recipes are deterministic).

Run: `godot --path . --headless --import`
Expected: imports the new wavs, no errors.

- [ ] **Step 5: Commit**

```bash
git add tools/audio/music.py tools/audio/sfx.py assets/audio scripts/sfx_ids.gd scripts/music_ids.gd
git commit -m "Add mountain music, mountain wind and snow footsteps"
```

---

### Task 4: The Frontier core, the region transition and the sealed pass gate

**Files:**
- Create: `scripts/frontier.gd`, `tools/passgateprobe.gd`, `tools/frontier_enter_test.gd`
- Modify: `scripts/interiors.gd`, `scripts/village.gd`

**Interfaces:**
- Consumes: Task 1 strings, quest `f_gate`.
- Produces:
  - `Frontier` (class_name, `extends Node3D`): consts `ORIGIN`, `BOUNDS`, `ENTRY`, `EXIT`, `CAMP`, `CAMP_RADIUS`, `COURT`, `FORT`, `GATE_Z`, `GATE_WIDTH`, `WALL_HEIGHT`, `WALL_THICK`, `SYMBOLS`, `VILLAGE_GATE`; `static func wp(x: float, z: float, h: float = 0.0) -> Vector3`; `func spawn_point() -> Vector3`; `func build() -> void` (await it); `var exit_action: Callable`; helpers `_box(pos, size, mat, solid) -> MeshInstance3D`, `_prop(path, x, z, yaw_deg, scale_, lift = 0.0, solid = false) -> Node3D`, group `"frontier"`.
  - `Interiors.in_region() -> bool`, `Interiors.enter_region(region_id: String, outside_pos: Vector3, outside_heading: float, player: Player, spawn_override: Vector3 = Vector3.INF, spawn_heading: float = PI) -> void` (coroutine), `Interiors.exit_region(player: Player) -> void` (coroutine), `current_kind == "frontier"` while in the region.
  - `Frontier.VILLAGE_GATE` (Vector3): where the pass gate stands in the village (single source of truth, used by `village.gd`, `interiors.gd` and `save_game.gd`).

- [ ] **Step 1: Find open ground for the pass gate**

Create `tools/passgateprobe.gd`:

```gdscript
extends SceneTree
## Prints which spots near the northern mountains are open ground (for the Frontier gate):
##   godot --path . --headless --script tools/passgateprobe.gd
func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(18.0, 6.0, 12.0)         # the gate, its two lamps and room to walk through
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	for z in range(-226, -190, 6):
		var line := "z=%d free x:" % z
		for x in range(-120, 121, 10):
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, 4.0, z))
			if space.intersect_shape(query, 1).is_empty():
				line += " %d" % x
		print(line)
	quit()
```

Run: `godot --path . --headless --script tools/passgateprobe.gd`
Expected: six lines like `z=-208 free x: ... 70 ...`. Pick a free `(x, z)` close to `(70, -206)` (east of the crypt, inside the mountain ring, in front of the northern mountains). If `70` is free on the `z=-208` row, keep `(70, -206)`; otherwise use the nearest free x on the closest row and write that into `VILLAGE_GATE` in Step 3. Note the chosen value.

- [ ] **Step 2: Write the failing enter/exit test**

Create `tools/frontier_enter_test.gd`:

```gdscript
extends SceneTree
## The pass gate, entering and leaving the Frontier region:
##   godot --path . --headless --script tools/frontier_enter_test.gd
var failed := false
var p: Player
var q: Node
var interiors


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func gate_spot() -> InteractSpot:
	var fr = load("res://scripts/frontier.gd")
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.global_position.distance_to(fr.VILLAGE_GATE + Vector3(0, 0, 3)) < 2.0:
			return n
	return null


func _run() -> void:
	await process_frame
	var fr = load("res://scripts/frontier.gd")
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0

	var spot := gate_spot()
	check("the pass gate exists in the village", spot != null)
	if spot == null:
		quit(1)
		return
	check("sealed prompt before the quest", spot.interact_prompt().contains(Strings.FRONTIER_SEALED))
	spot.interact(p)
	await create_timer(0.6).timeout
	check("a sealed gate does not let George through", not interiors.in_region())

	q.state["f_gate"] = q.S.ACTIVE
	check("open prompt after the quest", spot.interact_prompt().contains(Strings.BUILDING_NAMES["frontier"]))
	var outside_pos: Vector3 = p.global_position
	spot.interact(p)
	for i in 100:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	check("George is in the region", interiors.in_region() and not interiors.is_inside())
	check("the region kind is frontier", interiors.current_kind == "frontier")
	var spawn: Vector3 = fr.wp(fr.ENTRY.x, fr.ENTRY.y, 0.05)
	check("he stands at the entry (%s)" % str(p.global_position), p.global_position.distance_to(spawn) < 1.5)
	check("the sun is still on (outdoor)", (root.find_child("Sun", true, false) as Light3D).visible)
	check("the quest 'arrive' objective counted", q.state["f_gate"] == q.S.READY)
	check("the level node exists", get_first_node_in_group("frontier") != null)

	# back out through the arch
	var exit_spot: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_FRONTIER_BACK:
			exit_spot = n
	check("there is a way back", exit_spot != null)
	p.teleport(exit_spot.global_position, PI)
	exit_spot.interact(p)
	for i in 100:
		await create_timer(0.1).timeout
		if not interiors.in_region() and not p.busy:
			break
	check("George is back in the village", not interiors.in_region() and p.global_position.distance_to(fr.VILLAGE_GATE) < 12.0)

	# a second visit reuses the level
	spot.interact(p)
	for i in 100:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	check("second visit works", interiors.in_region())
	check("only one Frontier node exists", get_nodes_in_group("frontier").size() == 1)
	quit(1 if failed else 0)
```

Run: `godot --path . --headless --script tools/frontier_enter_test.gd`
Expected: script error (`Frontier`/`VILLAGE_GATE` not found), exit code 1 / `FAIL  the pass gate exists`.

- [ ] **Step 3: Create the Frontier core**

Create `scripts/frontier.gd` (set `VILLAGE_GATE` to the position from Step 1, default below):

```gdscript
class_name Frontier
extends Node3D
## The Frontier beyond the northern mountains (story part 3): a mountain pass, the refugee camp
## and the Fortress of Shadow. It is built once, on the first visit, at a far-away origin like the
## catacombs (see catacombs.gd) but it is OUTDOORS: the sky, the sun and the clock keep running.
## Everything is data at the top of the file. Positions are metres relative to ORIGIN: x grows to
## the east, z to the south, so the fortress lies to the north at negative z.

const ORIGIN := Vector3(-6000.0, 0.0, 6000.0)
const VILLAGE_GATE := Vector3(70.0, 0.0, -206.0)      # where the sealed pass gate stands in Agios Vlasis
const BOUNDS := Rect2(-96.0, -214.0, 192.0, 372.0)    # x, z, width, depth of the walkable area
const ENTRY := Vector2(0.0, 118.0)                    # George appears here, facing north
const EXIT := Vector2(0.0, 128.0)                     # the arch that leads back to the village
const CAMP := Vector2(0.0, 0.0)
const CAMP_RADIUS := 30.0
const COURT := Vector2(0.0, -150.0)                   # centre of the fortress courtyard
const FORT := Rect2(-46.0, -186.0, 92.0, 72.0)        # outer walls of the fortress
const GATE_Z := -114.0                                # the fortress gate in the south wall
const GATE_WIDTH := 12.0
const WALL_HEIGHT := 9.0
const WALL_THICK := 3.0

# Where the three Symbols of Shadow (quest "Τα Σύμβολα της Σκιάς") lie
const SYMBOLS := [Vector2(-48.0, 96.0), Vector2(52.0, 58.0), Vector2(-40.0, 24.0)]

const G := "res://assets/graveyard/"
const I := "res://assets/items/"
const W := "res://assets/world/"
const C := "res://assets/characters/"

var exit_action := Callable()               # set by Interiors: leaves the Frontier

var _root: Node3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("frontier")


## World position of a local coordinate (x east, z south, h up).
static func wp(x: float, z: float, h: float = 0.0) -> Vector3:
	return ORIGIN + Vector3(x, h, z)


## Where George appears.
func spawn_point() -> Vector3:
	return wp(ENTRY.x, ENTRY.y, 0.05)


# --------------------------------------------------------------------- building ----

## Builds the whole region. Await it: the creatures need the physics server to know the colliders.
func build() -> void:
	_rng.seed = 7731
	_root = Node3D.new()
	_root.name = "Level"
	add_child(_root)
	_build_ground()
	_build_boundary()
	_build_exit()
	await get_tree().physics_frame
	await get_tree().physics_frame


## Snow instead of meadow: the village ground shader with cold colours, a trampled camp,
## a dirt track up the pass and a cobbled road to the fortress.
func _build_ground() -> void:
	var terrain := Terrain.new()
	terrain.name = "Terrain"
	terrain.position = ORIGIN                  # its geometry is local, the shaders use world noise
	_root.add_child(terrain)
	terrain.setup(7731)
	var mat: ShaderMaterial = terrain._ground_mat
	mat.set_shader_parameter("grass_light", Color(0.93, 0.95, 1.0))
	mat.set_shader_parameter("grass_mid", Color(0.80, 0.84, 0.92))
	mat.set_shader_parameter("grass_dark", Color(0.60, 0.66, 0.76))
	mat.set_shader_parameter("dry_grass", Color(0.55, 0.52, 0.50))
	terrain.build_ground(Vector2(150.0, 260.0))   # after the colours: the far plane copies them
	terrain.add_patch(CAMP, CAMP_RADIUS + 6.0, Color(0.52, 0.48, 0.44), false, Color(0.34, 0.31, 0.29))
	terrain.add_patch(COURT, 52.0, Color(0.34, 0.33, 0.37), true, Color(0.20, 0.19, 0.23))
	terrain.add_path([Vector2(0, 126), Vector2(10, 100), Vector2(-9, 72), Vector2(4, 44), Vector2(0, 28)], 6.0)
	terrain.add_path([Vector2(0, -28), Vector2(-6, -60), Vector2(5, -90), Vector2(0, -112)], 7.0, true)
	# one big invisible floor so George never falls
	var body := StaticBody3D.new()
	body.name = "GroundCollider"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BOUNDS.size.x + 80.0, 2.0, BOUNDS.size.y + 80.0)
	shape.shape = box
	body.add_child(shape)
	body.position = wp(BOUNDS.get_center().x, BOUNDS.get_center().y, -1.0)
	_root.add_child(body)


## Invisible rock walls keep George inside; a ring of real mountains stands behind them.
func _build_boundary() -> void:
	var rim := BOUNDS.grow(2.0)
	var c := rim.get_center()
	for s in [
		[Vector2(c.x, rim.position.y), Vector2(rim.size.x + 8.0, 4.0)],
		[Vector2(c.x, rim.end.y), Vector2(rim.size.x + 8.0, 4.0)],
		[Vector2(rim.position.x, c.y), Vector2(4.0, rim.size.y + 8.0)],
		[Vector2(rim.end.x, c.y), Vector2(4.0, rim.size.y + 8.0)],
	]:
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(s[1].x, 40.0, s[1].y)
		shape.shape = box
		wall.add_child(shape)
		wall.position = wp(s[0].x, s[0].y, 20.0)
		_root.add_child(wall)
	var models := ["mountain_A", "mountain_B", "mountain_C"]
	var step := 34.0
	var x := rim.position.x - 10.0
	while x <= rim.end.x + 10.0:
		_mountain(models, Vector2(x, rim.position.y - 14.0))
		_mountain(models, Vector2(x, rim.end.y + 14.0))
		x += step
	var z := rim.position.y
	while z <= rim.end.y:
		_mountain(models, Vector2(rim.position.x - 14.0, z))
		_mountain(models, Vector2(rim.end.x + 14.0, z))
		z += step


func _mountain(models: Array, at: Vector2) -> void:
	var model := (load(W + "decoration/nature/%s.gltf" % models[_rng.randi() % models.size()]) as PackedScene).instantiate() as Node3D
	model.position = wp(at.x + _rng.randf_range(-6.0, 6.0), at.y + _rng.randf_range(-6.0, 6.0))
	model.rotation_degrees.y = _rng.randi_range(0, 5) * 60.0
	model.scale = Vector3.ONE * _rng.randf_range(18.0, 24.0)
	_root.add_child(model)


## A stone arch at the south end of the pass: the way back to Agios Vlasis.
func _build_exit() -> void:
	var arch := (load(G + "arch_gate.gltf") as PackedScene).instantiate() as Node3D
	arch.position = wp(EXIT.x, EXIT.y + 3.0)
	arch.scale = Vector3.ONE * 3.0
	_root.add_child(arch)
	var spot := InteractSpot.make(Strings.PROMPT_FRONTIER_BACK, func(p: Player): exit_action.call(p), 3.6)
	spot.position = wp(EXIT.x, EXIT.y)
	_root.add_child(spot)


# ---------------------------------------------------------------------- helpers ----

func _box(pos: Vector3, size: Vector3, mat: Material, solid: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	_root.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var collider := BoxShape3D.new()
		collider.size = size
		shape.shape = collider
		body.add_child(shape)
		mi.add_child(body)
	return mi


func _prop(path: String, x: float, z: float, yaw_deg: float, scale_: float, lift: float = 0.0, solid: bool = false) -> Node3D:
	var model := (load(path) as PackedScene).instantiate() as Node3D
	model.position = wp(x, z, lift)
	model.rotation_degrees.y = yaw_deg
	model.scale = Vector3.ONE * scale_
	_root.add_child(model)
	if solid:
		Interiors.collider_for(model)
	return model
```

If the probe in Step 1 chose another gate position, change the `VILLAGE_GATE` line accordingly.

- [ ] **Step 4: Region transition in `Interiors`**

In `scripts/interiors.gd`:

old_string:
```
var _saved_zoom := 7.0
```
new_string:
```
var _saved_zoom := 7.0
var _in_region := false            # George is in the Frontier (outdoors, far away from the village)
var _region_outside := {}          # {"pos": Vector3, "heading": float} where the way back leads
var _frontier: Frontier
```

old_string:
```
func _on_player_respawned(player: Player) -> void:
	if not _inside:
		return
```
new_string:
```
func _on_player_respawned(player: Player) -> void:
	if _in_region:                    # died in the Frontier: he wakes in the village, nothing else to restore
		_in_region = false
		current_kind = ""
		return
	if not _inside:
		return
```

old_string:
```
func is_inside() -> bool:
	return _inside
```
new_string:
```
func is_inside() -> bool:
	return _inside


## True while George is in the Frontier. It is outdoors (sun, sky and clock keep running),
## so is_inside() stays false there; ask in_region() for the few things that differ.
func in_region() -> bool:
	return _in_region
```

Insert the transition functions before `_exit_room`. old_string:
```
func _exit_room(door_id: String, player: Player) -> void:
```
new_string:
```
## Teleports George to a far-away outdoor region (only "frontier" for now) with a fade. Unlike
## enter() it leaves the light alone. outside_pos / outside_heading is where he stands again when
## he comes back; spawn_override / spawn_heading place him somewhere else than the entry (loading a save).
func enter_region(region_id: String, outside_pos: Vector3, outside_heading: float, player: Player, spawn_override: Vector3 = Vector3.INF, spawn_heading: float = PI) -> void:
	if player.busy or region_id != "frontier":
		return
	player.busy = true
	var hud := get_tree().get_first_node_in_group("hud")
	Sfx.ui("door_open")
	await hud.fade_out(0.3)
	if _frontier == null:
		_frontier = Frontier.new()
		_frontier.name = "Frontier"
		_frontier.exit_action = func(p): exit_region(p)
		add_child(_frontier)
		await _frontier.build()
	_region_outside = {"pos": outside_pos, "heading": outside_heading}
	player.teleport(_frontier.spawn_point() if spawn_override == Vector3.INF else spawn_override, spawn_heading)
	_in_region = true
	current_kind = "frontier"
	await hud.fade_in(0.3)
	player.busy = false
	Quests.report_reach("frontier")


func exit_region(player: Player) -> void:
	if player.busy or not _in_region:
		return
	player.busy = true
	var hud := get_tree().get_first_node_in_group("hud")
	Sfx.ui("door_close")
	await hud.fade_out(0.3)
	player.teleport(_region_outside["pos"] + Vector3(0, 0.05, 0), _region_outside["heading"])
	_in_region = false
	current_kind = ""
	await hud.fade_in(0.3)
	player.busy = false
	Quests.report_reach("village")


func _exit_room(door_id: String, player: Player) -> void:
```

- [ ] **Step 5: The sealed pass gate in the village**

In `scripts/village.gd` Edit:

old_string:
```
	_build_catacomb_door()
## The door of the old crypt leads down to the catacombs (story part 2). It stays sealed
```
new_string:
```
	_build_catacomb_door()
	_build_pass_gate()
## The door of the old crypt leads down to the catacombs (story part 2). It stays sealed
```

old_string:
```
func _catacombs_open() -> bool:
	return Quests.state["descent"] >= Quests.S.ACTIVE
```
new_string:
```
func _catacombs_open() -> bool:
	return Quests.state["descent"] >= Quests.S.ACTIVE


## The stone arch in the northern mountains that leads to the Frontier (story part 3). It stays
## sealed until Παπά-Σταύρος has told George about the Fortress of Shadow ("Η Πύλη του Περάσματος").
func _build_pass_gate() -> void:
	var gate_pos: Vector3 = Frontier.VILLAGE_GATE
	var holder := Node3D.new()
	holder.name = "PassGate"
	add_child(holder)
	_place_abs(GRAVE + "arch_gate.gltf", gate_pos, 0.0, 3.4, holder)
	for dx in [-7.0, 7.0]:
		var lamp := _place_abs(GRAVE + "lantern_standing.gltf", gate_pos + Vector3(dx, 0, 3.0), 0.0, 2.4, holder)
		_add_cylinder_collider(lamp, 0.5, 2.0, Vector3.ZERO)
		var light := OmniLight3D.new()
		light.position = gate_pos + Vector3(dx, 2.4, 3.0)
		light.light_color = Color(0.6, 0.7, 1.0)
		light.light_energy = 1.2
		light.omni_range = 11.0
		light.add_to_group("night_lights")
		holder.add_child(light)
	_occupy(gate_pos.x, gate_pos.z, 14.0)
	var front := gate_pos + Vector3(0, 0, 3.0)
	var enter := func(player: Player):
		if not _frontier_open():
			player.message.emit(Strings.MSG_FRONTIER_SEALED)
			return
		var interiors := get_tree().get_first_node_in_group("interiors") as Interiors
		if interiors:
			interiors.enter_region("frontier", front + Vector3(0, 0, 2.0), 0.0, player)
	var spot := InteractSpot.make(Strings.PROMPT_ENTER % Strings.BUILDING_NAMES["frontier"], enter, 4.6)
	spot.prompt_func = func():
		return Strings.PROMPT_ENTER % Strings.BUILDING_NAMES["frontier"] if _frontier_open() else "[R] " + Strings.FRONTIER_SEALED
	spot.position = front
	add_child(spot)


func _frontier_open() -> bool:
	return Quests.state["f_gate"] >= Quests.S.ACTIVE
```

- [ ] **Step 6: Refresh the class cache and run the test**

Run: `godot --path . --headless --import`
Expected: no parse errors (it creates `scripts/frontier.gd.uid`).

Run: `godot --path . --headless --script tools/frontier_enter_test.gd`
Expected: every line `PASS`, exit code 0. (The first entry builds the whole level: it may take a couple of seconds.)

If `the sun is still on` fails the `Sun` node name differs: use `get_tree().root.find_child("Sun", true, false)` as `Interiors._set_indoor_light` does (it is `Sun`).

- [ ] **Step 7: Commit**

```bash
git add scripts/frontier.gd scripts/frontier.gd.uid scripts/interiors.gd scripts/village.gd tools/passgateprobe.gd tools/passgateprobe.gd.uid tools/frontier_enter_test.gd tools/frontier_enter_test.gd.uid
git commit -m "Add the Frontier region core, the region transition and the sealed pass gate"
```

---

### Task 5: Frontier zones: the pass, the refugee camp, the fortress and its gate

**Files:**
- Modify: `scripts/frontier.gd`
- Create: `tools/frontier_build_test.gd`

**Interfaces:**
- Consumes: Task 4 helpers (`_box`, `_prop`, `wp`, `_root`, `_rng`) and `Quests.state["f_symbols"]`.
- Produces: `Frontier._build_pass()`, `_build_camp()`, `_build_fortress()`, `_build_gate()`, `_open_gate()`, `_on_quests_changed()`; field `_gate_open: bool` (read by tests); node group `"frontier_gate"` on the barrier node.

- [ ] **Step 1: Write the failing build test**

Create `tools/frontier_build_test.gd`:

```gdscript
extends SceneTree
## The zones of the Frontier: dressing, the light budget, the fortress gate:
##   godot --path . --headless --script tools/frontier_build_test.gd
var failed := false
var p: Player
var q: Node
var interiors


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func enter() -> void:
	q.state["f_gate"] = q.S.ACTIVE
	interiors.enter_region("frontier", Vector3(0, 0.05, 20), 0.0, p)
	for i in 120:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break


func _run() -> void:
	await process_frame
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	var lights_before := root.find_children("*", "OmniLight3D", true, false).size()
	await enter()
	var level = get_first_node_in_group("frontier")
	check("the level exists", level != null)
	var lights_after := root.find_children("*", "OmniLight3D", true, false).size()
	var region_lights := lights_after - lights_before
	print("   region lights: ", region_lights)
	check("the region stays inside the light budget (%d lights)" % region_lights, region_lights > 6 and region_lights <= 34)
	check("the fortress gate starts sealed", not level._gate_open)
	var barrier := root.find_children("*", "MeshInstance3D", true, false).filter(func(n): return n.is_in_group("frontier_gate"))
	check("a gate barrier is standing", barrier.size() == 1)
	q.state["f_symbols"] = q.S.READY
	q.changed.emit()
	await create_timer(1.5).timeout
	check("the gate opens when the symbols are ready", level._gate_open)
	check("the barrier is gone", root.find_children("*", "MeshInstance3D", true, false).filter(func(n): return n.is_in_group("frontier_gate") and is_instance_valid(n) and not n.is_queued_for_deletion()).is_empty())
	quit(1 if failed else 0)
```

Run: `godot --path . --headless --script tools/frontier_build_test.gd`
Expected: `FAIL` (`_gate_open` is missing: script error), exit code 1.

- [ ] **Step 2: Add the member variables and the build calls**

In `scripts/frontier.gd` Edit the field block:

old_string:
```
var _root: Node3D
var _rng := RandomNumberGenerator.new()
```
new_string:
```
var _root: Node3D
var _rng := RandomNumberGenerator.new()
var _stone: StandardMaterial3D
var _gate: Node3D
var _gate_open := false
```

and `build()`:

old_string:
```
	_build_ground()
	_build_boundary()
	_build_exit()
	await get_tree().physics_frame
	await get_tree().physics_frame
```
new_string:
```
	_build_ground()
	_build_boundary()
	_build_exit()
	_build_pass()
	_build_camp()
	_build_fortress()
	_build_gate()
	await get_tree().physics_frame
	await get_tree().physics_frame
	Quests.changed.connect(_on_quests_changed)
	_on_quests_changed()
```

- [ ] **Step 3: Append the zones to `scripts/frontier.gd`**

Append at the end of the file:

```gdscript


# ------------------------------------------------------------------- the pass ----

## True where nothing may stand: the tracks, the camp, the fortress with its road, the arch
## and the places the Symbols of Shadow lie.
func _blocked(p: Vector2) -> bool:
	if p.length() < CAMP_RADIUS + 8.0:
		return true
	if absf(p.x) < 14.0 and (p.y > 20.0 or (p.y < -20.0 and p.y > GATE_Z - 8.0)):
		return true
	if FORT.grow(12.0).has_point(p) or COURT.distance_to(p) < 60.0:
		return true
	if ENTRY.distance_to(p) < 14.0 or EXIT.distance_to(p) < 10.0:
		return true
	for s in SYMBOLS:
		if s.distance_to(p) < 7.0:
			return true
	return false


## Dead trees, boulders, three lantern posts and skull posts along the track.
func _build_pass() -> void:
	var rocks := ["A", "B", "C", "D", "E"]
	var trees := [G + "tree_dead_large.gltf", G + "tree_dead_medium.gltf", G + "tree_dead_small.gltf"]
	var placed := 0
	var tries := 0
	while placed < 150 and tries < 1500:
		tries += 1
		var p := Vector2(_rng.randf_range(BOUNDS.position.x + 6.0, BOUNDS.end.x - 6.0),
				_rng.randf_range(BOUNDS.position.y + 6.0, BOUNDS.end.y - 6.0))
		if _blocked(p):
			continue
		placed += 1
		if _rng.randf() < 0.7:
			_prop(trees[_rng.randi() % trees.size()], p.x, p.y, _rng.randf() * 360.0, _rng.randf_range(2.6, 3.4))
			_trunk(p, 0.9)
		else:
			var rock := _prop(W + "decoration/nature/rock_single_%s.gltf" % rocks[_rng.randi() % rocks.size()],
					p.x, p.y, _rng.randf() * 360.0, _rng.randf_range(7.0, 14.0))
			Interiors.collider_for(rock)
	for z in [100.0, 70.0, 42.0]:
		_lamp(8.0 if z != 70.0 else -8.0, z)
	for z in [110.0, 80.0, 52.0]:
		_prop(G + "post_skull.gltf", -12.0, z, 90.0, 1.6)
		_prop(G + "post_skull.gltf", 12.0, z + 6.0, 270.0, 1.6)


## A thin collider for the trunk of a tree.
func _trunk(p: Vector2, radius: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 6.0
	shape.shape = cyl
	body.add_child(shape)
	body.position = wp(p.x, p.y, 3.0)
	_root.add_child(body)


## A lantern post with a cold light that switches on after dusk (group night_lights).
func _lamp(x: float, z: float) -> void:
	_prop(G + "lantern_standing.gltf", x, z, 0.0, 2.4, 0.0, true)
	var light := OmniLight3D.new()
	light.position = wp(x, z, 2.4)
	light.light_color = Color(0.65, 0.75, 1.0)
	light.light_energy = 1.2
	light.omni_range = 11.0
	light.add_to_group("night_lights")
	_root.add_child(light)


## A fire that burns day and night: a torch model and a warm light.
func _fire(x: float, z: float, scale_: float, range_m: float, energy: float) -> void:
	_prop(I + "torch_lit.gltf.glb", x, z, 0.0, scale_)
	var light := OmniLight3D.new()
	light.position = wp(x, z, 2.6)
	light.light_color = Color(1.0, 0.62, 0.30)
	light.light_energy = energy
	light.omni_range = range_m
	_root.add_child(light)


# -------------------------------------------------------------------- the camp ----

func _build_camp() -> void:
	for i in 6:                                   # six tents in a ring, doors toward the fire
		var a := TAU * (float(i) + 0.5) / 6.0
		var p := CAMP + Vector2(cos(a), sin(a)) * 19.0
		var tent := _prop(W + "decoration/props/tent.gltf", p.x, p.y, rad_to_deg(atan2(-p.x, -p.y)), 14.0)
		Interiors.collider_for(tent)
	_fire(CAMP.x, CAMP.y, 3.2, 24.0, 3.0)         # the big fire in the middle
	for off in [Vector2(-10, -7), Vector2(10, -7), Vector2(-10, 10), Vector2(10, 10)]:
		_fire(off.x, off.y, 2.4, 9.0, 1.4)
	var P := W + "decoration/props/"
	_prop(P + "crate_A_big.gltf", 13.0, -3.0, 20.0, 7.0, 0.0, true)
	_prop(P + "barrel.gltf", 15.0, -1.0, 0.0, 7.0, 0.0, true)
	_prop(P + "sack.gltf", -13.0, -4.0, 40.0, 7.0)
	_prop(P + "weaponrack.gltf", -4.0, 13.0, 180.0, 7.0, 0.0, true)
	_prop(P + "wheelbarrow.gltf", 6.0, 13.0, 60.0, 7.0)


# ----------------------------------------------------------------- the fortress ----

func _stone_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Catacombs._brick_texture()
	m.albedo_color = Color(0.75, 0.72, 0.85)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * 0.25
	m.roughness = 0.95
	return m


## The scale that makes a model `width` metres wide (its longest horizontal side).
func _fit_scale(model: Node3D, width: float) -> float:
	var box := _aabb(model)
	return width / maxf(maxf(box.size.x, box.size.z), 0.01)


## Merged bounding box of all meshes of a model, in the model's own space.
func _aabb(model: Node3D) -> AABB:
	var have := false
	var box := AABB()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var t := Transform3D.IDENTITY
		var n: Node = mi
		while n != model and n != null:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		var a: AABB = t * mi.get_aabb()
		box = a if not have else box.merge(a)
		have = true
	return box


## A colour wash over every mesh of a model (the castle gets a dark violet tone).
func _tint(model: Node3D, color: Color) -> void:
	var wash := StandardMaterial3D.new()
	wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wash.albedo_color = color
	for node in model.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_overlay = wash


## One straight stone wall with battlements between two points (axis-aligned).
func _wall(a: Vector2, b: Vector2) -> void:
	var horizontal := absf(b.x - a.x) > absf(b.y - a.y)
	var length := absf(b.x - a.x) if horizontal else absf(b.y - a.y)
	var mid := (a + b) / 2.0
	var size := Vector3(length, WALL_HEIGHT, WALL_THICK) if horizontal else Vector3(WALL_THICK, WALL_HEIGHT, length)
	_box(wp(mid.x, mid.y, WALL_HEIGHT / 2.0), size, _stone, true)
	var count := maxi(int(length / 4.0), 1)
	for i in count:
		var p := a.lerp(b, (float(i) + 0.5) / float(count))
		var merlon := Vector3(1.8, 1.2, WALL_THICK + 0.2) if horizontal else Vector3(WALL_THICK + 0.2, 1.2, 1.8)
		_box(wp(p.x, p.y, WALL_HEIGHT + 0.6), merlon, _stone, false)


## A round tower with a dark cone roof.
func _tower(at: Vector2) -> void:
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 5.0
	cyl.bottom_radius = 5.4
	cyl.height = WALL_HEIGHT + 6.0
	body.mesh = cyl
	body.material_override = _stone
	body.position = wp(at.x, at.y, cyl.height / 2.0)
	_root.add_child(body)
	var collider := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var shape_cyl := CylinderShape3D.new()
	shape_cyl.radius = 5.4
	shape_cyl.height = cyl.height
	shape.shape = shape_cyl
	collider.add_child(shape)
	body.add_child(collider)
	var roof := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 6.6
	cone.height = 6.0
	roof.mesh = cone
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.16, 0.10, 0.24)
	roof_mat.roughness = 0.9
	roof.material_override = roof_mat
	roof.position = wp(at.x, at.y, cyl.height + 3.0)
	_root.add_child(roof)


func _build_fortress() -> void:
	_stone = _stone_material()
	var f := FORT
	var half_gap := GATE_WIDTH / 2.0
	_wall(Vector2(f.position.x, f.end.y), Vector2(-half_gap, f.end.y))      # south wall, left of the gate
	_wall(Vector2(half_gap, f.end.y), Vector2(f.end.x, f.end.y))            # south wall, right of the gate
	_wall(Vector2(f.position.x, f.position.y), Vector2(f.end.x, f.position.y))   # north wall
	_wall(Vector2(f.position.x, f.position.y), Vector2(f.position.x, f.end.y))   # west wall
	_wall(Vector2(f.end.x, f.position.y), Vector2(f.end.x, f.end.y))             # east wall
	for corner in [f.position, Vector2(f.end.x, f.position.y), Vector2(f.position.x, f.end.y), f.end]:
		_tower(corner)
	_tower(Vector2(-half_gap - 5.8, f.end.y))                               # the two gate towers
	_tower(Vector2(half_gap + 5.8, f.end.y))
	# the keep at the back of the courtyard: the red castle, darkened
	var keep := (load(W + "buildings/red/building_castle_red.gltf") as PackedScene).instantiate() as Node3D
	keep.scale = Vector3.ONE * _fit_scale(keep, 26.0)
	keep.position = wp(0.0, -172.0)
	_tint(keep, Color(0.10, 0.06, 0.18, 0.55))
	_root.add_child(keep)
	Interiors.collider_for(keep)
	# purple braziers along the courtyard
	for z in [-126.0, -146.0, -166.0]:
		for x in [-30.0, 30.0]:
			_brazier(x, z)
	# bones and skulls on the stones
	var bones := [G + "bone_A.gltf", G + "bone_B.gltf", G + "bone_C.gltf", G + "skull.gltf", G + "ribcage.gltf"]
	var yard := f.grow(-7.0)
	for i in 26:
		var p := Vector2(_rng.randf_range(yard.position.x, yard.end.x), _rng.randf_range(yard.position.y, yard.end.y))
		if absf(p.x) < 9.0 and p.y > -160.0:
			continue                                                  # keep the middle lane clear for the fights
		_prop(bones[_rng.randi() % bones.size()], p.x, p.y, _rng.randf() * 360.0, _rng.randf_range(1.2, 1.8))


func _brazier(x: float, z: float) -> void:
	_prop(I + "torch_lit.gltf.glb", x, z, 0.0, 3.2)
	var light := OmniLight3D.new()
	light.position = wp(x, z, 3.0)
	light.light_color = Color(0.75, 0.55, 1.0)
	light.light_energy = 1.6
	light.omni_range = 15.0
	_root.add_child(light)


## The sealed fortress gate: it dissolves when the quest "Τα Σύμβολα της Σκιάς" is ready.
func _build_gate() -> void:
	_gate = Node3D.new()
	_root.add_child(_gate)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(GATE_WIDTH, WALL_HEIGHT, 0.8)
	shape.shape = box
	body.add_child(shape)
	body.position = wp(0.0, GATE_Z, WALL_HEIGHT / 2.0)
	_gate.add_child(body)
	var barrier := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(GATE_WIDTH, WALL_HEIGHT, 0.4)
	barrier.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.3, 1.0, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.3, 1.0)
	mat.emission_energy_multiplier = 1.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	barrier.material_override = mat
	barrier.position = body.position
	barrier.add_to_group("frontier_gate")
	_gate.add_child(barrier)
	var light := OmniLight3D.new()
	light.light_color = Color(0.65, 0.35, 1.0)
	light.light_energy = 2.0
	light.omni_range = 14.0
	light.position = wp(0.0, GATE_Z + 2.0, 4.0)
	_gate.add_child(light)
	var label := Label3D.new()
	label.text = Strings.PROMPT_FORTRESS_GATE
	label.font_size = 52
	label.pixel_size = 0.0085
	label.outline_size = 16
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.85, 0.7, 1.0)
	label.no_depth_test = true
	label.position = wp(0.0, GATE_Z + 1.2, WALL_HEIGHT * 0.8)
	_gate.add_child(label)
	var spot := InteractSpot.make(Strings.PROMPT_FORTRESS_GATE, func(p: Player): p.message.emit(Strings.MSG_FORTRESS_SEALED), 5.0)
	spot.position = wp(0.0, GATE_Z + 3.0)
	_gate.add_child(spot)


func _on_quests_changed() -> void:
	if not _gate_open and Quests.state["f_symbols"] >= Quests.S.READY:
		_open_gate()


func _open_gate() -> void:
	_gate_open = true
	if is_instance_valid(_gate):
		var player := get_tree().get_first_node_in_group("player") as Player
		if player:
			player.message.emit(Strings.MSG_FORTRESS_OPEN)
		Sfx.ui("quest_ready")
		var g := _gate
		_gate = null
		for child in g.get_children():
			if child is StaticBody3D or child is InteractSpot:
				child.queue_free()
			if child.is_in_group("frontier_gate"):
				child.remove_from_group("frontier_gate")
		var tween := create_tween()
		tween.tween_interval(0.6)
		tween.tween_callback(g.queue_free)
```

Note on the test's "barrier is gone" check: the barrier leaves the group `frontier_gate` immediately when the gate opens (the node itself is freed 0.6 s later), so the group-based check passes after 1.5 s either way.

- [ ] **Step 4: Run the build test**

Run: `godot --path . --headless --import` then `godot --path . --headless --script tools/frontier_build_test.gd`
Expected: all `PASS` (lights printed: about 15 = 5 camp fires, 3 lantern posts, 6 braziers, 1 gate), exit code 0.

If a `Catacombs._brick_texture` parse error appears, check that `scripts/catacombs.gd` still declares `static func _brick_texture() -> ImageTexture` (it does at the time of writing).

- [ ] **Step 5: Commit**

```bash
git add scripts/frontier.gd tools/frontier_build_test.gd tools/frontier_build_test.gd.uid
git commit -m "Build the Frontier zones: the pass, the refugee camp, the fortress and its sealed gate"
```

---

### Task 6: Frontier content: symbols, chests, NPCs, creatures and returning bosses

**Files:**
- Modify: `scripts/frontier.gd`, `tools/frontier_build_test.gd`

**Interfaces:**
- Consumes: Task 2 enemy kinds, Task 1 NPC/item ids, `Enemies.spawn_extra(kind, pos) -> Enemy` (group `enemy_spawner`), `Chest`, `QuestItem`, `Npc`, `SaveGame.opened_chests`, `SaveGame.collected_items`.
- Produces: consts `CHESTS`, `SPAWNS`; `Frontier._build_pickups()`, `_spawn_creatures()`, `_check_bosses()`, `_boss_kinds()`; `_bosses` dictionary.

- [ ] **Step 1: Extend the build test (failing)**

In `tools/frontier_build_test.gd` Edit the end:

old_string:
```
	quit(1 if failed else 0)
```
new_string:
```
	# --- content
	var counts := {}
	for e in get_nodes_in_group("enemies"):
		var k: String = e.kind_id
		counts[k] = int(counts.get(k, 0)) + 1
	print("   enemies by kind: ", counts)
	check("at least 8 shadow knights stand around", int(counts.get("shadow_knight", 0)) >= 8)
	check("at least 5 soul collectors", int(counts.get("soul_collector", 0)) >= 5)
	check("one giant skeleton and one Malakar", int(counts.get("giant_skeleton", 0)) == 1 and int(counts.get("malakar", 0)) == 1)
	var fr = load("res://scripts/frontier.gd")
	for e in get_nodes_in_group("enemies"):
		var local: Vector3 = e.global_position - fr.ORIGIN
		if absf(local.x) > 2000.0:
			continue                                # village skeletons stand thousands of metres away
		check("no enemy in the camp (%s at %s)" % [e.kind_id, str(local)], Vector2(local.x, local.z).length() > fr.CAMP_RADIUS)
	var npc_ids := []
	for n in get_nodes_in_group("npcs"):
		npc_ids.append(n.get("npc_id"))
	check("Ilarion and Elpida stand in the camp", "ilarion" in npc_ids and "elpida" in npc_ids)
	check("5 chests in the region", root.find_children("*", "Chest", true, false).filter(func(c): return c.global_position.x < -5000.0).size() == 5)
	# symbols only show while the quest is active
	var symbols := root.find_children("*", "QuestItem", true, false).filter(func(n): return n.item_id == "symbol")
	check("three Symbols of Shadow lie around", symbols.size() == 3)
	q.state["f_symbols"] = q.S.AVAILABLE
	q.changed.emit()
	check("...hidden before the quest", symbols.all(func(n): return not n.visible))
	q.state["f_symbols"] = q.S.ACTIVE
	q.changed.emit()
	check("...visible while the quest is active", symbols.all(func(n): return n.visible))
	# a boss killed early comes back when its quest starts
	var giant
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "giant_skeleton":
			giant = e
	giant.take_damage(999999.0, p.global_position)
	await create_timer(0.3).timeout
	check("the giant is dead", giant.is_dead())
	q.state["f_wall"] = q.S.ACTIVE
	q.changed.emit()
	await create_timer(0.3).timeout
	var back := 0
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "giant_skeleton" and not e.is_dead():
			back += 1
	check("the giant is back once f_wall is active", back == 1)
	quit(1 if failed else 0)
```

Run: `godot --path . --headless --script tools/frontier_build_test.gd`
Expected: the old checks pass, `FAIL  at least 8 shadow knights stand around`, exit code 1.

- [ ] **Step 2: Add the data tables**

In `scripts/frontier.gd` Edit (data belongs at the top, right after `SYMBOLS`):

old_string:
```
const G := "res://assets/graveyard/"
const I := "res://assets/items/"
```
new_string:
```
# [x, z, rotation in degrees, golden, gold_min, gold_max, potions]
const CHESTS := [
	[14.0, 9.0, 270, false, 40, 90, 1],         # the camp
	[-22.0, 66.0, 90, false, 40, 90, 1],        # the pass
	[24.0, -70.0, 270, true, 90, 160, 2],       # the road to the fortress
	[-36.0, -140.0, 90, true, 120, 200, 3],     # the courtyard
	[34.0, -176.0, 270, true, 180, 260, 3],     # behind the keep
]

# [kind, x, z]  (enemies.gd KINDS). Nothing stands inside the camp (CAMP_RADIUS).
const SPAWNS := [
	# the pass
	["shadow_knight", -14.0, 104.0], ["shadow_knight", 16.0, 94.0], ["soul_collector", -24.0, 88.0],
	["shadow_knight", 20.0, 74.0], ["soul_collector", 26.0, 66.0], ["shadow_knight", -22.0, 62.0],
	["shadow_knight", 12.0, 50.0], ["soul_collector", -16.0, 46.0],
	# the road between the camp and the fortress
	["shadow_knight", -18.0, -44.0], ["shadow_knight", 18.0, -58.0], ["soul_collector", -26.0, -72.0],
	["soul_collector", 24.0, -86.0], ["shadow_knight", 0.0, -100.0],
	# the courtyard
	["shadow_knight", -22.0, -126.0], ["shadow_knight", 22.0, -126.0], ["soul_collector", -28.0, -140.0],
	["soul_collector", 28.0, -140.0], ["shadow_knight", -20.0, -158.0], ["shadow_knight", 20.0, -158.0],
	["giant_skeleton", 0.0, -128.0],
	["malakar", 0.0, -156.0],
]

const G := "res://assets/graveyard/"
const I := "res://assets/items/"
```

and the field:

old_string:
```
var _gate: Node3D
var _gate_open := false
```
new_string:
```
var _gate: Node3D
var _gate_open := false
var _bosses := {}                           # boss kind -> Enemy
```

- [ ] **Step 3: Wire them into `build()` and the quest hook**

old_string:
```
	_build_fortress()
	_build_gate()
	await get_tree().physics_frame
	await get_tree().physics_frame
	Quests.changed.connect(_on_quests_changed)
	_on_quests_changed()
```
new_string:
```
	_build_fortress()
	_build_gate()
	_build_pickups()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_creatures()
	Quests.changed.connect(_on_quests_changed)
	_on_quests_changed()
```

old_string:
```
func _on_quests_changed() -> void:
	if not _gate_open and Quests.state["f_symbols"] >= Quests.S.READY:
		_open_gate()
```
new_string:
```
func _on_quests_changed() -> void:
	if not _gate_open and Quests.state["f_symbols"] >= Quests.S.READY:
		_open_gate()
	_check_bosses()
```

- [ ] **Step 4: Append pickups, NPCs, creatures and boss return**

Append at the end of `scripts/frontier.gd`:

```gdscript


# ------------------------------------------------------- pickups, people, enemies ----

func _build_pickups() -> void:
	for c in CHESTS:
		var chest := Chest.new()
		chest.golden = c[3]
		chest.gold_min = c[4]
		chest.gold_max = c[5]
		chest.potions = c[6]
		chest.position = wp(c[0], c[1])
		chest.rotation_degrees.y = c[2]
		_root.add_child(chest)
		if SaveGame.opened_chests.has(SaveGame.key_for(chest.position)):
			chest.mark_opened()
	for s in SYMBOLS:
		var pos := wp(s.x, s.y)
		if SaveGame.collected_items.has("symbol@" + SaveGame.key_for(pos)):
			continue
		var item := QuestItem.new()
		item.item_id = "symbol"
		item.position = pos
		_root.add_child(item)
	# the two people of the refugee camp
	var ilarion := Npc.new()
	ilarion.npc_id = "ilarion"
	ilarion.rest_yaw = 0.8
	ilarion.position = wp(-5.0, 3.0, 0.05)
	_root.add_child(ilarion)
	var elpida := Npc.new()
	elpida.npc_id = "elpida"
	elpida.rest_yaw = -0.8
	elpida.position = wp(6.0, 3.0, 0.05)
	_root.add_child(elpida)


func _spawn_creatures() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null:
		push_warning("frontier.gd: no enemy spawner")
		return
	for s in SPAWNS:
		var enemy: Enemy = spawner.spawn_extra(s[0], wp(s[1], s[2], 0.05))
		if enemy and s[0] in _boss_kinds():
			_bosses[s[0]] = enemy


func _boss_kinds() -> Array:
	return ["giant_skeleton", "malakar"]


## A boss that was killed before his quest began comes back when the quest is taken.
func _check_bosses() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null:
		return
	for s in SPAWNS:
		var kind: String = s[0]
		if not kind in _boss_kinds():
			continue
		var quest: String = spawner.KINDS[kind]["quest"]
		if Quests.state[quest] != Quests.S.ACTIVE:
			continue
		var alive: bool = _bosses.has(kind) and is_instance_valid(_bosses[kind]) and not _bosses[kind].is_dead()
		var wanted := false
		for i in QuestData.QUESTS[quest]["objectives"].size():
			var o: Dictionary = QuestData.QUESTS[quest]["objectives"][i]
			if o["type"] == "kill" and o["target"] == kind and Quests.progress[quest][i] < o["count"]:
				wanted = true
		if wanted and not alive:
			var enemy: Enemy = spawner.spawn_extra(kind, wp(s[1], s[2], 0.05))
			if enemy:
				_bosses[kind] = enemy
```

- [ ] **Step 5: Run the tests**

Run: `godot --path . --headless --script tools/frontier_build_test.gd`
Expected: all `PASS`, exit code 0. (`enemies by kind` prints 13 knights, 7 collectors, 1 giant, 1 Malakar plus village skeletons.)

Run again: `godot --path . --headless --script tools/frontier_enter_test.gd`
Expected: still all `PASS`.

- [ ] **Step 6: Commit**

```bash
git add scripts/frontier.gd tools/frontier_build_test.gd
git commit -m "Fill the Frontier: symbols, chests, the two refugee NPCs, creatures and bosses that return"
```

---

### Task 7: Region awareness: map, music, footsteps, invasion skip, save

**Files:**
- Modify: `scripts/hud.gd`, `scripts/minimap.gd`, `scripts/sound_manager.gd`, `scripts/player.gd`, `scripts/invasion.gd`, `scripts/save_game.gd`
- Create: `tools/part3_hooks_test.gd`

**Interfaces:**
- Consumes: `Interiors.in_region()`, `Interiors.enter_region(...)`, `Frontier.VILLAGE_GATE`, music `mountain`, ambience `amb_mountain`, sound `footstep_snow`, `Strings.MSG_NO_MAP`, `Strings.INVASION_SKIPPED`.
- Produces: save key `player.in_frontier` (bool); `SaveGame.apply` rebuilds the region and places George in it.

- [ ] **Step 1: Write the failing hooks test**

Create `tools/part3_hooks_test.gd`:

```gdscript
extends SceneTree
## Everything that must behave differently inside the Frontier:
##   godot --path . --headless --script tools/part3_hooks_test.gd
var failed := false
var p: Player
var q: Node
var interiors


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var save = load("res://scripts/save_game.gd")
	var fr = load("res://scripts/frontier.gd")
	# keep the player's real save safe: this test writes savegame.json
	var real_backup := "user://savegame.before_hooks_test"
	if FileAccess.file_exists(save.PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real_backup))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	interiors = get_first_node_in_group("interiors")
	var hud = get_first_node_in_group("hud")
	var sound = get_first_node_in_group("sound_manager")
	var invasion = get_first_node_in_group("invasion")
	p._invulnerable = 99999.0
	check("the corner minimap is visible in the village", hud._mini_frame.visible)
	check("village music is not 'mountain'", sound._pick_music() != "mountain")

	q.state["f_gate"] = q.S.ACTIVE
	interiors.enter_region("frontier", fr.VILLAGE_GATE + Vector3(0, 0.05, 5), 0.0, p)
	for i in 120:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	check("in the region", interiors.in_region())
	for e in get_nodes_in_group("enemies"):
		e.queue_free()                             # no fight music in this test
	await create_timer(0.5).timeout
	check("the corner minimap is hidden in the region", not hud._mini_frame.visible)
	check("the music is 'mountain'", sound._pick_music() == "mountain")
	hud.toggle_big_map()
	check("the big map does not open in the region", not hud._big_map.visible)

	# --- a night invasion is skipped while George is away
	invasion.start(1)
	check("the invasion is skipped while away", not invasion.active)

	# --- saving inside the region and loading it back
	save.delete()
	check("saved", save.save())
	var data: Dictionary = save.read()
	check("the save knows George is in the frontier", bool(data["player"].get("in_frontier", false)))
	var saved_pos: Vector3 = p.global_position
	var near := Vector3(float(data["player"]["position"][0]), float(data["player"]["position"][1]), float(data["player"]["position"][2]))
	check("...and stores the real position", near.distance_to(saved_pos) < 0.5)
	interiors.exit_region(p)
	for i in 100:
		await create_timer(0.1).timeout
		if not interiors.in_region() and not p.busy:
			break
	check("back in the village", not interiors.in_region())
	check("the village minimap returns", hud._mini_frame.visible)
	save.apply(data)
	for i in 120:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	check("loading the save puts George back in the Frontier", interiors.in_region() and p.global_position.distance_to(saved_pos) < 1.5)

	# --- a save made in the village says so
	interiors.exit_region(p)
	for i in 100:
		await create_timer(0.1).timeout
		if not interiors.in_region() and not p.busy:
			break
	save.save()
	data = save.read()
	check("a village save has in_frontier false", not bool(data["player"].get("in_frontier", true)))

	# --- dying in the Frontier wakes George in the village
	interiors.enter_region("frontier", fr.VILLAGE_GATE + Vector3(0, 0.05, 5), 0.0, p)
	for i in 120:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	p.respawn_time = 0.3
	p._die()
	await create_timer(1.0).timeout
	check("George respawned outside the region", not interiors.in_region() and p.global_position.length() < 60.0)

	# restore the real save
	save.delete()
	if FileAccess.file_exists(real_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_backup), ProjectSettings.globalize_path(save.PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_backup))
	quit(1 if failed else 0)
```

Run: `godot --path . --headless --script tools/part3_hooks_test.gd`
Expected: early `FAIL` lines (`corner minimap is hidden`, `music is 'mountain'`, …), exit code 1. (The test restores the real save at the end even when checks fail; if the run crashes, restore from `user://savegame.before_hooks_test` by hand.)

- [ ] **Step 2: HUD: hide the minimap, block the village map**

In `scripts/hud.gd`:

old_string:
```
		_mini_frame.visible = not _interiors.is_inside()
```
new_string:
```
		_mini_frame.visible = not (_interiors.is_inside() or _interiors.in_region())
```
old_string:
```
func toggle_big_map() -> void:
	if is_dialogue_open() or _shop.is_open():
		return
```
new_string:
```
func toggle_big_map() -> void:
	if is_dialogue_open() or _shop.is_open():
		return
	if _interiors != null and _interiors.in_region():
		Quests.message.emit(Strings.MSG_NO_MAP)
		return
```

- [ ] **Step 3: Minimap: quest items of other places never point into the village map**

In `scripts/minimap.gd`:

old_string:
```
						if it.visible and it.get("item_id") == o["item"]:
```
new_string:
```
						if it.visible and it.get("item_id") == o["item"] and _inside_world(it.global_position):
```

- [ ] **Step 4: Sound: mountain music and wind**

In `scripts/sound_manager.gd`:

old_string:
```
	for id in ["amb_day", "amb_night", "wind_loop", "amb_tavern", "amb_church", "amb_crypt"]:
```
new_string:
```
	for id in ["amb_day", "amb_night", "wind_loop", "amb_tavern", "amb_church", "amb_crypt", "amb_mountain"]:
```
old_string:
```
	var flat := Vector2(_player.global_position.x, _player.global_position.z)
	if flat.distance_to(CRYPT) < 62.0 or (_interiors != null and _interiors.is_inside()):
		return "crypt"
```
new_string:
```
	var flat := Vector2(_player.global_position.x, _player.global_position.z)
	if _interiors != null and _interiors.in_region():
		return "mountain"
	if flat.distance_to(CRYPT) < 62.0 or (_interiors != null and _interiors.is_inside()):
		return "crypt"
```
old_string:
```
	var near_crypt := not inside and flat.distance_to(CRYPT) < 55.0
```
new_string:
```
	var region: bool = _interiors != null and _interiors.in_region()
	var near_crypt := not inside and not region and flat.distance_to(CRYPT) < 55.0
```
old_string:
```
		"amb_day": -4.0 if out > 0.0 and not near_crypt else -60.0,
		"amb_night": -4.0 if out > 0.0 and dark > 0.5 and not near_crypt else -60.0,
```
new_string:
```
		"amb_day": -4.0 if out > 0.0 and not near_crypt and not region else -60.0,
		"amb_night": -4.0 if out > 0.0 and dark > 0.5 and not near_crypt and not region else -60.0,
```
old_string:
```
		"amb_crypt": -2.0 if (near_crypt or kind == "catacombs") and sfx_on else -60.0,
```
new_string:
```
		"amb_crypt": -2.0 if (near_crypt or kind == "catacombs") and sfx_on else -60.0,
		"amb_mountain": -3.0 if region and sfx_on else -60.0,
```
old_string:
```
	if out > 0.0 and not near_crypt:
```
new_string:
```
	if out > 0.0 and not near_crypt and not region:
```
Also update the doc comment at the top of the file: Edit
old_string:
```
## Music, by priority: inside a building (tavern / church / calm) > night invasion >
## boss fight > fighting skeletons > crypt area > the wilds > night > day.
```
new_string:
```
## Music, by priority: inside a building (tavern / church / calm) > night invasion >
## boss fight > fighting skeletons > the Frontier (mountain) > crypt area > the wilds > night > day.
```

- [ ] **Step 5: Snow footsteps**

In `scripts/player.gd`:

old_string:
```
		id = "footstep_stone" if interiors.current_kind == "catacombs" else "footstep_wood"
	elif Vector2(global_position.x, global_position.z).length() < 26.0:
```
new_string:
```
		id = "footstep_stone" if interiors.current_kind == "catacombs" else "footstep_wood"
	elif interiors != null and interiors.in_region():
		id = "footstep_snow"
	elif Vector2(global_position.x, global_position.z).length() < 26.0:
```

- [ ] **Step 6: The invasion is skipped while George is away**

In `scripts/invasion.gd`:

old_string:
```
func start(night_number: int) -> void:
	if active:
		return
```
new_string:
```
func start(night_number: int) -> void:
	if active:
		return
	var interiors := get_tree().get_first_node_in_group("interiors")
	if interiors != null and interiors.in_region():      # George is in the Frontier: the village holds without him
		_say(Strings.INVASION_SKIPPED, 5.0)
		return
```

- [ ] **Step 7: Save and load inside the Frontier**

In `scripts/save_game.gd`:

old_string:
```
	var position := player.global_position
	var interiors := tree.get_first_node_in_group("interiors")
	if interiors != null and interiors.is_inside():
		position = interiors.exit_position()        # inside a building: save the doorstep
```
new_string:
```
	var position := player.global_position
	var in_frontier := false
	var interiors := tree.get_first_node_in_group("interiors")
	if interiors != null and interiors.is_inside():
		position = interiors.exit_position()        # inside a building: save the doorstep
	elif interiors != null and interiors.in_region():
		in_frontier = true                          # in the Frontier: save the real position, load rebuilds the region
```
old_string:
```
			"position": [position.x, position.y, position.z], "heading": player._heading,
```
new_string:
```
			"position": [position.x, position.y, position.z], "heading": player._heading,
			"in_frontier": in_frontier,
```
old_string:
```
	var pos: Array = pd["position"]
	player.teleport(Vector3(float(pos[0]), float(pos[1]) + 0.05, float(pos[2])), float(pd.get("heading", PI)))
```
new_string:
```
	var pos: Array = pd["position"]
	var saved_pos := Vector3(float(pos[0]), float(pos[1]) + 0.05, float(pos[2]))
	var saved_heading := float(pd.get("heading", PI))
	var region_host := tree.get_first_node_in_group("interiors")
	if bool(pd.get("in_frontier", false)) and region_host != null:
		# the Frontier is built on demand: this fades, builds it and places George there a moment later
		region_host.enter_region("frontier", Frontier.VILLAGE_GATE + Vector3(0, 0.05, 5.0), 0.0, player, saved_pos, saved_heading)
	else:
		player.teleport(saved_pos, saved_heading)
```
Also update the header comment of the file: Edit
old_string:
```
## Not saved: where ordinary skeletons stand (they respawn), a night invasion in progress,
## chests inside buildings.
```
new_string:
```
## Not saved: where ordinary skeletons stand (they respawn), a night invasion in progress,
## chests inside buildings. In the Frontier the real position is saved ("in_frontier": true)
## and loading rebuilds the region.
```

- [ ] **Step 8: Run the tests**

Run: `godot --path . --headless --quit-after 200`
Expected: no parse errors.

Run: `godot --path . --headless --script tools/part3_hooks_test.gd`
Expected: all `PASS`, exit code 0.

Run: `godot --path . --headless --script tools/frontier_enter_test.gd` and `godot --path . --headless --script tools/frontier_build_test.gd`
Expected: still all `PASS`.

If `the big map does not open in the region` fails because `_big_map` is named differently, grep `_big_map` in `scripts/hud.gd` (the node used by `toggle_big_map`) and use that name.

- [ ] **Step 9: Commit**

```bash
git add scripts/hud.gd scripts/minimap.gd scripts/sound_manager.gd scripts/player.gd scripts/invasion.gd scripts/save_game.gd tools/part3_hooks_test.gd tools/part3_hooks_test.gd.uid
git commit -m "Make HUD, music, footsteps, invasion and saves aware of the Frontier region"
```

---

### Task 8: Full playthrough test, screenshots and frame rate

**Files:**
- Create: `tools/part3test.gd`, `tools/frontiershot.gd`

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: The whole-story test**

Create `tools/part3test.gd` (windowed, simulated input like `tools/part2test.gd`):

```gdscript
extends SceneTree
## Plays story part 3 (the Frontier) from the first talk with Stavros to the ending:
##   godot --path . --resolution 1280x720 --script tools/part3test.gd -- tools/_shots/part3
var out := "."
var failed := false
var p: Player
var q: Node
var hud: Node
var interiors
var fr   # frontier.gd, loaded (it mentions the Quests autoload, so no type reference)


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


func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.1).timeout
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)


func npc(id: String) -> Node3D:
	for n in get_nodes_in_group("interactables"):
		if n.get("npc_id") != null and n.get("npc_id") == id:
			return n
	return null


func talk(id: String, take_shot := "") -> void:
	var n = npc(id)
	p.teleport(n.global_position + Vector3(2.5, 0.05, 0), -PI / 2.0)
	await create_timer(0.5).timeout
	await press("interact")
	await create_timer(0.5).timeout
	if take_shot != "":
		await create_timer(1.0).timeout
		await shot(take_shot)
	var guard := 0
	while hud.is_dialogue_open() and guard < 40:
		guard += 1
		await create_timer(0.4).timeout
		await press("interact")
	await create_timer(0.6).timeout


func kill(kind: String, count: int) -> int:
	var killed := 0
	for e in get_nodes_in_group("enemies"):
		if killed >= count:
			break
		if e.kind_id == kind and not e.is_dead():
			e.take_damage(99999.0, p.global_position)
			killed += 1
	await create_timer(0.3).timeout
	return killed


func alive(kind: String) -> int:
	var n := 0
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == kind and not e.is_dead():
			n += 1
	return n


func states() -> String:
	var parts := []
	for id in ["necro", "f_gate", "f_guards", "f_symbols", "f_wall", "f_malakar", "f_return"]:
		parts.append("%s=%s" % [id, ["locked", "available", "active", "ready", "done"][q.state[id]]])
	return ", ".join(parts)


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func wait_region(on: bool) -> void:
	for i in 120:
		await create_timer(0.1).timeout
		if interiors.in_region() == on and not p.busy:
			return


func gate_spot() -> InteractSpot:
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.global_position.distance_to(fr.VILLAGE_GATE + Vector3(0, 0, 3)) < 2.0:
			return n
	return null


func _run() -> void:
	await process_frame
	fr = load("res://scripts/frontier.gd")
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	p = get_first_node_in_group("player") as Player
	hud = get_first_node_in_group("hud")
	interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	for id in QuestData.QUESTS:
		if id.begins_with("f_"):
			continue
		q.state[id] = q.S.DONE
	q._refresh_availability()
	check("f_gate is available after Part 2: " + states(), q.state["f_gate"] == q.S.AVAILABLE)
	check("Stavros shows a '!'", q.marker_for("stavros") == "!")

	# --- the gate is sealed until Stavros has spoken
	var spot := gate_spot()
	check("the pass gate exists", spot != null)
	p.teleport(fr.VILLAGE_GATE + Vector3(0, 0.05, 6), 0.0)
	await create_timer(0.5).timeout
	await press("interact")
	await create_timer(0.8).timeout
	check("sealed: George stays in the village", not interiors.in_region())
	await shot("p3_01_gate_sealed")
	await talk("stavros", "p3_02_stavros_offer")
	check("accepted f_gate: " + states(), q.state["f_gate"] == q.S.ACTIVE)

	# --- through the gate
	p.teleport(fr.VILLAGE_GATE + Vector3(0, 0.05, 6), 0.0)
	await create_timer(0.5).timeout
	await press("interact")
	await wait_region(true)
	check("in the Frontier, f_gate ready to hand in: " + states(), interiors.in_region() and q.state["f_gate"] == q.S.READY)
	await shot("p3_03_entry")
	check("the corner minimap is hidden", not hud._mini_frame.visible)
	var level := get_first_node_in_group("frontier")
	check("the fortress gate is sealed", not level._gate_open)
	check("Ilarion shows a '?'", q.marker_for("ilarion") == "?")
	await talk("ilarion", "p3_04_ilarion_complete")
	check("f_gate done, f_guards + f_symbols available: " + states(), q.state["f_gate"] == q.S.DONE and q.state["f_guards"] == q.S.AVAILABLE and q.state["f_symbols"] == q.S.AVAILABLE)

	# --- the pass: guards and symbols
	await talk("ilarion")
	await talk("elpida", "p3_05_elpida_offer")
	check("accepted guards + symbols: " + states(), q.state["f_guards"] == q.S.ACTIVE and q.state["f_symbols"] == q.S.ACTIVE)
	var knights := await kill("shadow_knight", 5)
	var collectors := await kill("soul_collector", 3)
	print("   killed ", knights, " knights and ", collectors, " collectors")
	check("guards quest ready: " + states(), q.state["f_guards"] == q.S.READY)
	check("the fortress gate is still sealed", not level._gate_open)
	var found := 0
	for item in root.find_children("*", "QuestItem", true, false):
		if item.item_id == "symbol" and item.visible:
			found += 1
			p.teleport(item.global_position + Vector3(0, 0.05, 0), 0.0)
			await create_timer(0.5).timeout
	print("   symbols found: ", found)
	check("symbols ready: " + states(), q.state["f_symbols"] == q.S.READY)
	await create_timer(1.2).timeout
	check("the fortress gate opened", level._gate_open)
	await talk("ilarion")
	await talk("elpida")
	check("both handed in, f_wall available: " + states(), q.state["f_guards"] == q.S.DONE and q.state["f_symbols"] == q.S.DONE and q.state["f_wall"] == q.S.AVAILABLE)

	# --- the giant: a giant killed too early comes back when the quest starts
	check("one giant skeleton stands in the courtyard", alive("giant_skeleton") == 1)
	await kill("giant_skeleton", 1)
	check("...and is dead now", alive("giant_skeleton") == 0)
	await talk("ilarion")
	check("accepted f_wall: " + states(), q.state["f_wall"] == q.S.ACTIVE)
	await create_timer(0.5).timeout
	check("the early-killed giant came back", alive("giant_skeleton") == 1)
	p.teleport(fr.wp(0.0, -100.0, 0.05), PI)
	await create_timer(0.8).timeout
	await shot("p3_06_fortress_gate_open")
	await kill("giant_skeleton", 1)
	check("giant dead, f_wall ready: " + states(), q.state["f_wall"] == q.S.READY)
	await talk("ilarion")
	check("f_wall done, f_malakar available: " + states(), q.state["f_wall"] == q.S.DONE and q.state["f_malakar"] == q.S.AVAILABLE)
	await talk("elpida")
	check("accepted f_malakar: " + states(), q.state["f_malakar"] == q.S.ACTIVE)

	# --- Malakar enrages and calls help
	var boss
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "malakar":
			boss = e
	p.teleport(fr.wp(0.0, -134.0, 0.05), PI)
	await create_timer(0.8).timeout
	await shot("p3_07_malakar")
	boss.take_damage(boss.max_health * 0.55, p.global_position)
	check("Malakar enraged below half health", boss._enraged)
	var before := get_nodes_in_group("enemies").size()
	var called := false
	for i in 80:
		await create_timer(0.25).timeout
		if get_nodes_in_group("enemies").size() > before:
			called = true
			break
	check("...and called shadow knights (enemies %d -> %d)" % [before, get_nodes_in_group("enemies").size()], called)
	await shot("p3_08_malakar_enraged")
	await kill("malakar", 1)
	check("Malakar dead, hand in at Ilarion: " + states(), q.state["f_malakar"] == q.S.READY)
	await talk("ilarion")
	check("f_malakar done, f_return available: " + states(), q.state["f_malakar"] == q.S.DONE and q.state["f_return"] == q.S.AVAILABLE)
	await talk("ilarion")
	check("accepted f_return: " + states(), q.state["f_return"] == q.S.ACTIVE)

	# --- away from home: no invasion, saves work
	var invasion = get_first_node_in_group("invasion")
	invasion.start(1)
	check("the invasion is skipped while George is away", not invasion.active)
	var save = load("res://scripts/save_game.gd")
	var real_backup := "user://savegame.before_part3test"
	if FileAccess.file_exists(save.PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save.PATH), ProjectSettings.globalize_path(real_backup))
	save.delete()
	save.save()
	check("the save knows he is in the Frontier", bool(save.read()["player"].get("in_frontier", false)))
	save.delete()
	if FileAccess.file_exists(real_backup):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(real_backup), ProjectSettings.globalize_path(save.PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real_backup))

	# --- home again
	var exit_spot: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == Strings.PROMPT_FRONTIER_BACK:
			exit_spot = n
	p.teleport(exit_spot.global_position, PI)
	await create_timer(0.5).timeout
	await press("interact")
	await wait_region(false)
	check("back in the village, f_return ready: " + states(), not interiors.in_region() and q.state["f_return"] == q.S.READY)
	var finished := [false]
	q.game_finished.connect(func(): finished[0] = true)
	await talk("stavros", "p3_09_stavros_end")
	await create_timer(4.5).timeout
	await shot("p3_10_the_end")
	check("part 3 finished: " + states(), q.state["f_return"] == q.S.DONE and finished[0])
	print("level ", p.level, " gold ", p.gold, " potions ", p.potions)
	quit(1 if failed else 0)
```

Run: `godot --path . --resolution 1280x720 --script tools/part3test.gd -- tools/_shots/part3`
Expected: every line `PASS`, ten PNGs in `tools/_shots/part3/`, exit code 0. Read the PNGs: `p3_03_entry` (snow, mountains, path north), `p3_06_fortress_gate_open` (walls, towers, keep, braziers), `p3_07_malakar`/`p3_08_malakar_enraged` (the boss, red wash after enrage). If the test fails because the GPU is busy, ask Theodore to stop his game.

If `talk()` cannot find an NPC (`npc("ilarion")` is null) the region has not finished building: raise the wait in `wait_region`. If a `PASS` fails, fix the cause in the relevant task's file, do not weaken the test.

- [ ] **Step 2: Screenshots of each zone and the frame rate**

Create `tools/frontiershot.gd`:

```gdscript
extends SceneTree
## Screenshots of each zone of the Frontier and a frame-rate check:
##   godot --path . --resolution 1920x1080 --script tools/frontiershot.gd -- tools/_shots/frontier [night]
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func sample(label: String, secs: float) -> void:
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		frames += 1
	print("PERF ", label, ": ", snappedf(frames / secs, 0.1), " fps, draw calls ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	await process_frame
	var fr = load("res://scripts/frontier.gd")
	var q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	if "night" in OS.get_cmdline_user_args():
		var dn := get_first_node_in_group("daynight")
		dn.running = false
		dn.set_time(23.0)
		await create_timer(2.0).timeout
	q.state["f_gate"] = q.S.ACTIVE
	interiors.enter_region("frontier", fr.VILLAGE_GATE + Vector3(0, 0.05, 5), 0.0, p)
	for i in 150:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	print("PERF lights in the tree: ", root.find_children("*", "OmniLight3D", true, false).size())
	var spots := [
		["entry", 0.0, 112.0, PI], ["pass", 4.0, 60.0, PI], ["camp", 0.0, 22.0, PI],
		["road", 0.0, -40.0, PI], ["fortress_outside", 0.0, -92.0, PI], ["courtyard", 0.0, -122.0, PI],
	]
	for s in spots:
		p.teleport(fr.wp(s[1], s[2], 0.05), s[3])
		await create_timer(1.2).timeout
		await shot("fr_" + s[0])
		await sample(s[0], 3.0)
	quit()
```

Run: `godot --path . --resolution 1920x1080 --script tools/frontiershot.gd -- tools/_shots/frontier`
Expected: six PNGs and six `PERF` lines. **Target 60 fps** in every zone (the GTX 1050 Ti ran the catacombs and the village at 60). Look at the PNGs.

Run: `godot --path . --resolution 1920x1080 --script tools/frontiershot.gd -- tools/_shots/frontier_night night`
Expected: the same at night; lamps and braziers visible; still about 60 fps.

**Visual bar check (spec risk):** if the ground, rocks or mountains look clearly bad (e.g. mountains floating, flat white blobs, models inside each other), STOP and tell Theodore what you saw with the screenshot path before continuing. Typical fixes within this task: adjust the mountain `scale` range or `step` in `_build_boundary`, the snow colours in `_build_ground`, tree counts in `_build_pass`, keep size in `_build_fortress`.

If fps is below 55 in a zone: first drop `_build_pass` tree count from 150 to 100, then the number of battlement boxes (`count` in `_wall`: use `length / 6.0`), then the mountain count (`step := 44.0`).

- [ ] **Step 3: Commit**

```bash
git add tools/part3test.gd tools/part3test.gd.uid tools/frontiershot.gd tools/frontiershot.gd.uid scripts/frontier.gd
git commit -m "Add the story part 3 playthrough test and the Frontier screenshot/fps driver"
```
(`scripts/frontier.gd` is only included if visual or performance tuning changed it.)

---

### Task 9: Regression run and documentation

**Files:**
- Modify: `CLAUDE.md`, `HANDOVER.md`, `CHANGELOG.md`
- No `project.godot` version bump, no tag, no push (Theodore asks for a release separately).

- [ ] **Step 1: Regression tests**

Run each (windowed ones need the GPU) and confirm no `FAIL` and no `SCRIPT ERROR`:

```bash
godot --path . --headless --import
godot --path . --headless --script tools/part3_data_test.gd
godot --path . --headless --script tools/part3_mobs_test.gd
godot --path . --headless --script tools/frontier_enter_test.gd
godot --path . --headless --script tools/frontier_build_test.gd
godot --path . --headless --script tools/part3_hooks_test.gd
godot --path . --resolution 1280x720 --script tools/questtest.gd -- tools/_shots/questtest
godot --path . --resolution 1280x720 --script tools/part2test.gd -- tools/_shots/part2
godot --path . --resolution 1280x720 --script tools/savetest.gd -- tools/_shots/savetest
godot --path . --resolution 1280x720 --script tools/eventtest.gd -- tools/_shots/eventtest
godot --path . --resolution 1280x720 --script tools/minimaptest.gd -- tools/_shots/minimaptest
godot --path . --resolution 1280x720 --script tools/audiotest.gd
godot --path . --resolution 1920x1080 --script tools/perftest.gd
```
Expected: all green; `perftest` still about 60 fps in the village (the Frontier is not built until George goes there, so the village is unaffected). If `questtest` or `sidequesttest` iterate over all quests and now trip over the `f_` quests, make them skip ids starting with `f_` the same way `part2test` does.

- [ ] **Step 2: CHANGELOG**

In `CHANGELOG.md`, insert above `## 0.12.1-beta (2026-10-13) — modern HUD, ...`:

```markdown
## 0.13-beta (unreleased) — story part 3: the Frontier beyond the mountains
**New in this version**
- **The Frontier** (`scripts/frontier.gd`): a new outdoor region reached through a stone arch in the northern mountains (east of the old crypt, sealed until Παπά-Σταύρος offers "Η Πύλη του Περάσματος"). Built once on the first visit at a far-away origin; the sky, sun and clock keep running. Three zones: the **Βουνίσιο Πέρασμα** (snow, dead trees, boulders, lantern posts, skull posts), the **Καταφύγιο των Προσφύγων** (tents around a big fire, safe zone) and the **Φρούριο της Σκιάς** (walls with battlements, seven towers, the dark keep, purple braziers, a sealed gate). The layout is data at the top of the file (`SPAWNS`, `CHESTS`, `SYMBOLS`, zone constants).
- **Story part 3 (6 quests, 2 new NPCs Μοναχός Ιλαρίων and Ελπίδα η Κυνηγός):** "Η Πύλη του Περάσματος" → "Οι Φρουροί του Περάσματος" + "Τα Σύμβολα της Σκιάς" (3 golden symbols open the fortress gate) → "Το Τείχος" → "Ο Άρχοντας του Βουνού" → "Η Επιστροφή" (hand-in at Παπά-Σταύρος, "Συνεχίζεται…"). Part 2 no longer ends with "Συνεχίζεται…"; it leads into part 3.
- **New creatures:** Ιππότης της Σκιάς, Ψυχοσυλλέκτης (blue souls that slow George down: new `Player.slow`), the mini-boss **Γιγάντιος Σκελετός** and the final boss **Μαλάκαρ ο Σκοτεινός Άρχοντας**, who enrages below half health (faster, redder, calls shadow knights). Bosses return while their quest is active.
- **Region support** (`Interiors.enter_region` / `exit_region` / `in_region()`): the minimap and the village map are hidden there, new music `mountain`, cold wind and snow footsteps (all synthesized), the night invasion is skipped while George is away, and saving inside the Frontier stores the real position (`in_frontier`) and rebuilds the region on load.
- New test drivers: `part3test` (plays all of part 3), `frontiershot` (screenshots + fps, `night` variant), `part3_data_test`, `part3_mobs_test`, `frontier_enter_test`, `frontier_build_test`, `part3_hooks_test`, `passgateprobe`.

**Not done yet:** audio tuning by ear (mountain music and wind are new), a Frontier map, the rest of the backlog (see `HANDOVER.md`).

```

- [ ] **Step 3: CLAUDE.md**

In `CLAUDE.md`, add after the paragraph that starts `**The Catacombs and story part 2**` (before `**Village square**`):

```markdown
**The Frontier and story part 3** (`frontier.gd`, `interiors.gd`, `enemies.gd` KINDS `shadow_knight`/`soul_collector`/`giant_skeleton`/`malakar`, quests `f_gate`/`f_guards`/`f_symbols`/`f_wall`/`f_malakar`/`f_return`): a stone arch in the northern mountains (`Village._build_pass_gate`, position `Frontier.VILLAGE_GATE`, R, sealed until `f_gate` is ACTIVE) leads to the Frontier, an OUTDOOR region built on first use at `Frontier.ORIGIN` (-6000, 0, 6000) by `Interiors.enter_region("frontier", ...)`. Unlike rooms and the catacombs it does not touch light or the `_inside` flag, so DayNight keeps running; `Interiors.in_region()` (and `current_kind == "frontier"`) tell the few systems that differ: the minimap and map (M) are hidden, `SoundManager` plays music `mountain` + ambience `amb_mountain`, footsteps are `footstep_snow`, `Invasion.start` is skipped with a banner while George is away, `SaveGame` stores `player.in_frontier` and the real position and `apply` rebuilds the region. The level is data at the top of `frontier.gd` (`BOUNDS`, `CAMP`, `FORT`, `SYMBOLS`, `CHESTS`, `SPAWNS`; local metres, x east, z south, `Frontier.wp(x, z)` converts to world); zones: the pass (snow ground via the village ground shader with cold colours, dead trees, boulders), the camp with Ιλαρίων and Ελπίδα (safe, no spawns within `CAMP_RADIUS`), the fortress (box walls with the catacombs brick texture, 7 towers, the darkened `building_castle_red` keep, a sealed gate that dissolves when `f_symbols` is READY). Bosses `giant_skeleton` (quest `f_wall`) and `malakar` (quest `f_malakar`) come back while their quest is ACTIVE (`Frontier._check_bosses`). `Malakar` enrages below 50% health (`Enemy.enrage_below`, `enrage_summon`): faster, red wash, calls shadow knights. `soul_collector` shots (`Projectile` kind `"soul"`, `Enemy.projectile_slows`) call `Player.slow(2.5)`. Objective `reach` places: `catacombs`, `frontier`, `village` (`Interiors.exit_region` reports `village`). `f_return` is the quest with `ends_game` (the "Συνεχίζεται…" now follows part 3). Do not type-reference `Frontier` in a `--script` test: `load("res://scripts/frontier.gd")`, then `fr.wp(x, z, h)`, `fr.VILLAGE_GATE`. Tests: `part3test` (plays part 3), `frontiershot` (screenshots, fps, `night`), `frontier_enter_test`, `frontier_build_test`, `part3_hooks_test`, `part3_mobs_test`, `part3_data_test`.
```
and replace in the same file the sentence in the Audio paragraph `crossfaded, calm switches no more often than every 4 s` is unchanged; add to the music priority list: change `boss > combat (6 s hold) > crypt zone > wilds` to `boss > combat (6 s hold) > the Frontier (mountain) > crypt zone > wilds` using Edit.

- [ ] **Step 4: HANDOVER.md**

Edit `HANDOVER.md`: set the header line to say the branch `feature/part3-frontier` contains story part 3 (unreleased `0.13-beta`); in section 3 add a sentence about the Frontier after the "story part 2 in the Catacombs" mention; in section 4 delete the whole backlog item "A. Story part 3" and renumber nothing (keep letters B–I, since other docs reference them); in the test-drivers list in section 2 add `part3test`, `frontiershot`, `frontier_enter_test`, `frontier_build_test`, `part3_hooks_test`, `part3_mobs_test`, `part3_data_test`, `passgateprobe`. Add under the backlog a new item: `**J. Part 3 follow-ups.** A map of the Frontier, more Frontier side quests, the Frontier at night (more lights), tuning the mountain music/wind by ear (see H).` The file map in section 5: add `scripts/frontier.gd` to the **world** list.

- [ ] **Step 5: Final state and commit**

Run: `git status --short`
Expected: only the three docs modified (plus the earlier `HANDOVER.md` change Theodore had before).

```bash
git add CLAUDE.md HANDOVER.md CHANGELOG.md
git commit -m "Document story part 3 and the Frontier region"
```

- [ ] **Step 6: Report to Theodore**

Tell him, in Greek or Greeklish, short: what exists, the test results (list any `FAIL` honestly), the fps numbers from `frontiershot`, the paths of the screenshots to look at, that nothing was pushed/tagged/released, and that releasing as `0.13-beta` (version bump in `project.godot`, tag, `gh release create`) waits for his word. Mention the one thing only he can judge: the new music and wind by ear (AnyDesk audio on).
