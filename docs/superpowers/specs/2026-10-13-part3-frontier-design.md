# Story Part 3: The Frontier (design)

Date: 2026-10-13. Target release: 0.13-beta. Status: approved by Theodore in chat (structure, story, technical plan, invasion rule).

## Goal
Add story part 3: a new instanced outdoor region beyond the mountains (the **Frontier**), with a medium-sized quest chain, new NPCs, new enemy types and a final boss. All in-game text is Greek; code, comments and file names are English.

## Decisions
- **Area type:** an instanced outdoor region built once, on first use, at a fixed far-away origin (like the catacombs), NOT an extension of the real map.
- **Story:** Part 2 ended with Ευστάθιος whispering a name beyond the mountains. That name is **Μαλάκαρ ο Σκοτεινός Άρχοντας**, Ευστάθιος' old teacher, who lives in a fortress and wants to break all the seals of the mountain.
- **Scope:** medium (about 6 quests, 4 new enemy kinds, 2 NPCs, 1 mini-boss, 1 final boss), ending in a new "Συνεχίζεται…".
- **Invasion rule:** while George is in the Frontier a night invasion is skipped (banner, no penalty, no reward).

## Region layout
`scripts/frontier.gd` (class `Frontier`, `extends Node3D`), data-driven like `catacombs.gd`:
- `ORIGIN` = `Vector3(-6000, 0, 6000)`; constants and rect lists at the top of the file (`ZONES`, `PATHS`, `SPAWNS`, `CHESTS`, `PIECES`, `NPCS`).
- Three zones joined by short paths:
  1. **Βουνίσιο Πέρασμα** (mountain pass): snow and rock, pines, skeleton guards; the transition from the village.
  2. **Καταφύγιο των Προσφύγων** (refugee camp): safe zone with fires and tents, two NPCs, a chest.
  3. **Φρούριο της Σκιάς** (fortress): courtyard, walls, tower; a sealed fortress gate opens when the quest `symbols` is READY/DONE; the final boss stands inside.
- Ground: the existing ground shader with a rock/snow variant; rocks and pines from the existing KayKit packs at the edges (no new assets). Boundaries are rock walls so George cannot leave the region.
- Light budget about 50 for 60 fps: camp fires plus fortress torches (only every third torch has a light).

## Entering and leaving
- **Entrance:** a sealed pass gate north of the graveyard (an `InteractSpot` built in `Village`, like `_build_catacomb_door`). It opens when Part 2 is finished (quest `necro` DONE) and Παπά-Σταύρος has given the first Part 3 quest. Sealed prompt in Greek until then.
- **Transition:** new `Interiors.enter_region(region_id, outside_pos, outside_heading, player)`: same fade, teleport and `busy` handling as `enter`, but it does NOT call `_set_indoor_light` and does NOT set `_inside`. It sets a separate flag with `in_region()` and `current_kind = "frontier"`.
- **Exit:** an `InteractSpot` at the start of the pass returns George to the village gate (`exit_region`). Death in the Frontier respawns at the village as usual and clears the region flag (extend `_on_player_respawned`).
- Quest hook: `Quests.report_reach("frontier")` on arrival.

## Systems that need to know about the region
Each currently asks `Interiors.is_inside()`; `is_inside()` keeps meaning "inside a roofed room" and the Frontier is handled explicitly:
- **DayNight:** unchanged (outdoor; keeps driving sky, sun, fog).
- **HUD / minimap / big map:** hidden while `in_region()`, because the captured terrain picture is of the village.
- **SoundManager:** new music loop `mountain` (picked when in the Frontier, after boss/combat), new ambience layer (cold wind) and `footstep_snow`; new recipes in `tools/audio/music.py` and `sfx.py`, regenerated with `python tools/gen_audio.py` then `godot --headless --import`.
- **Player footsteps:** use `footstep_snow` in the region.
- **Invasion:** `Invasion.start` checks `in_region()` and, if true, shows a Greek banner ("Ο Παπά-Σταύρος κράτησε το χωριό χωρίς εσένα.") and ends the night without a fight, penalty or reward. No auto-return.
- **Save:** `SaveGame.save()` stores the real position plus `in_frontier = true` when in the region (rooms still save the doorstep). `apply()` builds the region and teleports. Chests and pieces use stable positions (fixed origin), so they restore like the catacombs.

## Story and quests (Greek text in `quest_data.gd`)
A new chain, unlocked by a Part 3 intro from Παπά-Σταύρος after `necro`:
1. **Η Πύλη του Περάσματος** (`reach` "frontier").
2. **Οι Φρουροί του Περάσματος** (`kill` shadow knights and skeletons).
3. **Τα Σύμβολα της Σκιάς** (`collect` 3 `symbol` pieces; opens the fortress gate).
4. **Το Τείχος** (`kill` the mini-boss *Γιγάντιος Σκελετός*).
5. **Ο Άρχοντας του Βουνού** (`kill` *Μαλάκαρ*).
6. **Η Επιστροφή** (hand-in to Παπά-Σταύρος; `ends_game` shows the new "Συνεχίζεται…").
The Part 2 ending text and the `ends_game` flag of `necro` change so that Part 2 hands over to Part 3 and the final "Συνεχίζεται…" belongs to quest 6.

NPCs: **Μοναχός Ιλαρίων** (survivor of Ευστάθιος' monastery) and **Ελπίδα η Κυνηγός**, in the refugee camp. Rewards use the existing reward fields (XP, gold, potions, damage). Level target about 15-20.

## Enemies (`enemies.gd` KINDS)
- `shadow_knight`: heavy melee, slow, high health.
- `soul_collector`: ranged, applies a slow (reuse `projectile.gd`).
- `giant_skeleton`: mini-boss, summons nothing, high damage.
- `malakar`: final boss, two phases, uses `Enemy.summon_kind` for the second phase.
Spawned with `Enemies.spawn_extra`; bosses stay dead only while their quest is DONE and return while their quest is ACTIVE (same rule as `Catacombs._check_bosses`).

## Tests
- `tools/part3test.gd`: plays the whole chain with assertions (like `part2test.gd`): gate sealed and then open, enter, kill, collect, fortress gate, bosses, ending, region flag, invasion skipped while away.
- `tools/frontiershot.gd`: screenshots of each zone and an fps measurement (target 60 fps); also a night variant.
- Extend `savetest` for `in_frontier`.
- Rules from the handover: no type references to classes that mention `Quests`/`SaveGame`/`Sfx` in `--script` tests; use `load()` and untyped access.

## Out of scope (YAGNI)
Own map for the Frontier, real world expansion, more than one dungeon, mount, weather, new character models.

## Open risks
- Ground and cliff look in the Frontier must reach the visual bar (stylised KayKit). If it does not, say so before continuing.
- The GPU cannot run a second Godot instance while Theodore's game runs; ask him to stop it if screenshot tests fail.
