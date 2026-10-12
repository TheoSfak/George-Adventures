# HANDOVER — George Adventures at Agios Vlasis

Written 2026-10-12 so a **new chat window** can continue seamlessly. Read this first, then `CLAUDE.md` (project facts) and `README.md` (controls). Everything lives in this folder; there is no git repo.

---
## 1. Who and how to work with Theodore
- Theodore (Greek, writes Greek/English/**Greeklish**, Windows 11). Wants things **done**, not walkthroughs. Short, precise answers; give a recommendation instead of a survey.
- **ALL IN-GAME TEXT MUST BE GREEK** (UI, quests, lore, dialogue, item names, prompts). Code/comments/file names in English. Greek strings live in `scripts/strings_el.gd`, `quest_data.gd`, `villager_data.gd`, `skill_data.gd`, plus the Greek names in `enemies.gd`/`village.gd`.
- Global rule (his `~/.claude/CLAUDE.md`): **never add AI co-author / "Generated with Claude" lines** to git commits or PRs (there is no git repo here anyway).
- Only free tools. Art = KayKit (CC0). Engine = Godot 4.7.2.
- He is happy with the look ("αρχίζει και γίνεται ωραίο, μου αρέσει") and asked for: **more quests, more mobs, and a night event where the mobs enter the village when darkness falls** (or other suggestions).

## 2. How to run, test, and edit safely
- Godot is installed at `%LOCALAPPDATA%\Programs\Godot\Godot.exe` (also `godot` on PATH). Desktop shortcut "George Adventures (Godot)" opens the editor. Theodore just presses **F5**. If the editor is already open and things look stale, close and reopen it (autoload/class changes).
- After adding a `class_name` script, an autoload, or assets run: `godot --headless --import` (refreshes the class cache; also prints parse errors).
- Quick compile check: `godot --headless --quit-after 200` (no output = fine).
- Test drivers in `tools/` (windowed, simulated input, screenshots; GTX 1050 Ti runs 60 fps): 
  `godot --path . --resolution 1280x720 --script tools/<name>.gd -- <outdir>` then read the PNGs.
  `controltest` (WoW controls), `playtest` (combat), `loottest` (XP/loot), `skilltest` (skills/bar/potions), `questtest` (whole story), `interiortest` (doors/rooms), `villagertest`, `mobtest` (archer/mage/brute/invader march), `maptest` (map shots), `perftest` (fps).
- **Test-script rules**: start with `await process_frame` and `root.get_node("/root/Quests").intro_seen = true` (autoloads don't exist at compile time in `--script` mode, and the prologue dialogue blocks input). Don't type-reference classes whose script mentions `Quests` (e.g. `Npc`) in a test; use untyped access.
- **Editing pitfalls learned the hard way**
  - GDScript uses tabs. When patching files with Python, count tabs from `cat -A`, not from the Read tool's line numbers (they add a tab). A "tab-tolerant" patch helper that retries one tab shallower saved time.
  - Patch scripts must be idempotent (skip when the new text is already present) — an earlier script was applied several times and duplicated constants.
  - Write Greek with the Write/Edit tools (UTF-8). Bash heredocs with Greek are risky; `sed` with Greek worked for simple replacements.
  - Don't use `%%` in non-formatted Greek strings.
  - A long animation (spin) must be ended by a timer, not the animation end (`_end_skill_attack`).
  - `Variant` inference: write `var x: bool = ...` / `var s: String = dict["k"]` when GDScript can't infer.

## 3. What exists (all tested; see CLAUDE.md for detail)
Player with WoW-style controls, XP/levels, skills + 8-slot action bar + skill book (P) + 3 potion types; big map (~200 m radius) with a procedural meadow ground, cobbled/dirt paths, grass/flowers (MultiMesh), gardens, pond, village (buildings 2.4x), three story areas (west camp, SE quarry, north crypt), chests, quest items with light beams, signposts; enterable interiors with furniture and chests; 4 quest NPCs + 5-quest storyline with prologue/ending in Greek; ambient villagers (strollers, chatting pairs with speech bubbles, tavern regulars with beer); full Greek HUD.

### 3a. Finished in the LAST part of the session (new mobs) — tested with `tools/mobtest.gd`
- `scripts/enemy.gd` was **rewritten**: new `State.MARCH`, ranged attacks (`ranged`, `projectile_kind` "arrow"/"orb", `ranged_min/max`, `shoot_anim`, `projectile_speed`), anti-snag **detour** (`_check_blocked` / `_detour`: sidestep when pushing against obstacles), `tint_color` (colour wash via `material_overlay`), `attack_anim` override, `dissolve()` (crumble silently at dawn, no reward), `invader` + `march_target` exports, `is_dead()`.
- `scripts/projectile.gd`: arrow (Skeleton_Arrow model, oriented with a -90° X rotation) and glowing orb; stops at walls (ray on layer 1), hits George at chest height, uses `player.take_damage(dmg, pos_behind_shot)` so blocking/knockback work.
- `scripts/enemies.gd`: new KINDS **rogue** (archer, green tint, crossbow), **mage** (purple tint, staff, orbs), **brute** (scale 1.4, red tint, big shield + axe, 130 hp, 22 dmg). ~19 new spawns (archers in the west/outskirts, brutes at quarry/outskirts, mages around the crypt/camp). New `spawn_invader(kind, pos, target)` → marching enemy that dies for good (index -1 means no respawn). Assets copied: `assets/characters/Skeleton_Rogue.glb`, `Skeleton_Mage.glb`, weapons Crossbow/Staff/Arrow/Shield_Large_A in `assets/characters/skeleton_weapons/`.
- Verified: archer holds ~13 m and arrows hit; mage orbs hit; brute hits for 22; an invader marches toward the well.

### 3b. Shops, equipment, talent tree, new skills (added 2026-10-12, all tested)
- Plan: `docs/superpowers/plans/2026-10-12-shops-talents.md`. Details: CLAUDE.md "Shops & equipment" and "Talent tree".
- Tests: `tools/shoptest.gd`, `talenttest.gd`, `keepertest.gd` (plus the older drivers; `skilltest`, `questtest`, `playtest`, `loottest`, `perftest` re-run and pass, 60 fps).
- Edit prices/stats in `shop_data.gd`, talents in `talent_data.gd`, skills in `skill_data.gd` (+ a case in `Player.use_skill`, an icon in `icons.gd`).
- Fixed on the way: `pickup.gd` created 4 identical glow lights per potion (leftover of a repeated patch).
- Interior exit spots are now 2.4 m wide, at the door (they used to steal the prompt from shopkeepers at the counter).

## 4. NOT done yet — the next chat should build these (design is decided)
### 4a. Day/night cycle — new `scripts/daynight.gd` (Node "DayNight" in `scenes/main.tscn`)
- `time_of_day` in hours; `day_length_seconds` ≈ 600 (1 h = 25 s); start 9:00. Signals: `dusk_started` (~19:30), `night_started(night_number)` (~20:30), `dawn_started` (~5:30), `day_started`. Debug helper `set_time(h)`.
- Visuals: replace the ProceduralSkyMaterial with a **custom sky shader** (`shaders/sky.gdshader`, `shader_type sky`): gradient from uniforms (top/horizon/ground colours), sun disc + moon disc from uniform directions (pass directions explicitly, don't rely on LIGHT0), stars when dark, `Sky.process_mode = REALTIME`, `radiance_size = 32` (ambient light comes from the sky). Move the `Sun` DirectionalLight3D along an arc (energy→0 and `visible=false` when below horizon); add a dim blue "Moon" DirectionalLight3D (no shadows). Fade ambient energy (~0.3 night / 0.75 day), fog colour, clouds will darken naturally.
- **Interiors compatibility**: `Interiors._set_indoor_light()` overrides the environment while inside. DayNight must skip env updates while the player is inside (add `Interiors.is_inside()` returning `_inside`); it reapplies next frame after exit.
- Night lights: group `night_lights` (OmniLights, shadows off): lanterns around the plaza/spokes (Halloween `lantern_standing`/`post_lantern` models are in `assets/graveyard/`), a warm light at every door front (`_door_fronts` in village.gd), a small lantern light on George (Player). Fireflies (`CPUParticles3D` following the player) at night is a nice touch.
- HUD: a clock label top-centre, e.g. "Ημέρα 2 · 21:40" with a sun/moon icon (add "sun"/"moon" to `icons.gd`).
- Villagers: add outdoor ones (WANDER/CHAT modes) to group `villagers`; add `Villager.set_sheltered(bool)` (hide, drop out of `interactables`, scale tween) called at dusk, undone at dawn. Tavern regulars stay.
### 4b. Night invasion event — new `scripts/invasion.gd` (Node "Invasion")
- On `night_started`: banner "ΕΙΣΒΟΛΗ! Οι νεκροί πλησιάζουν το χωριό!" (church bell if audio exists). 3 waves; wave size ≈ `5 + night*2` (cap 14), types by player level (minions/warriors early, then rogues, mages, brutes; mini-boss on night ≥ 3). Spawn at 4 gates ~150 m from the well (N crypt road, W, E, S) with `Enemies.spawn_invader(kind, pos, Vector3.ZERO)`. Next wave when ≤30% of the previous is alive or after ~70 s.
- **Village safety** (0–100, HUD bar top-centre): every 0.5 s `safety -= 0.3 * (invaders within ~14 m of the well) * 0.5`. Success = all waves dead → rewards (XP `80+40n`, gold `40+25n`, 2+ potions, a golden `Chest` spawned in the plaza), `Quests.report_defense()`. Fail = safety ≤ 0 → invaders retreat/dissolve, lose ~15% gold, message. At `dawn_started` leftover invaders `dissolve()`.
- HUD: label "Κύμα 2/3 — Σκελετοί: 7" + safety bar; signal e.g. `updated(active, wave, waves, alive, safety)` and `banner(text)`.
- New objective type `"defend"` in `quests.gd` (count 1) completed by `report_defense()`.
### 4c. More quests / NPCs (all `requires: ["bell"]`, all Greek, add to `quest_data.gd`)
- New NPCs (data in `QuestData.NPCS`, placement via the BUILDINGS list `npc id` field in `village.gd`): **Βασίλης ο Λοχαγός της Φρουράς** (Knight model; extend `Npc.WEAPON_NODES` with "1H_Sword","Badge_Shield","Rectangle_Shield","Spike_Shield","2H_Sword"; show `["1H_Sword"]`), near the watchtower; **Στέλιος ο Μυλωνάς** (Barbarian or Rogue_Hooded model) at the windmill.
- Quests: **Η Νύχτα της Εισβολής** (Παπά-Σταύρος, `defend` 1); **Τα Σακιά του Μυλωνά** (Στέλιος, collect 5 `sack` items — add to `QuestItem.MODELS`: hex prop `decoration/props/sack.gltf`, scale ~14); **Ξύλα για τη Φωτιά** (Γέρο-Γιάννης, collect 6 `log` items: `resource_lumber.gltf` scale ~4); **Οι Τοξότες** (Βασίλης, kill 5 `rogue`); **Οι Μάγοι** (requires archers, kill 4 `mage`); **Οι Βάναυσοι** (requires mages, kill 3 `brute`, reward +5 damage); **Τα Οστέινα Τοτέμ** (Βασίλης, destroy 3 totems).
- Kill objectives already match `kind_id` ("rogue","mage","brute","captain","king"); `"skeleton"` matches all. Extend `Player.apply_reward` with `"power"`/`"speed"` potion rewards.
- **Totems** (`scripts/totem.gd`): StaticBody with ~80 hp in groups `breakables`; model `graveyard/post_skull.gltf` (about 0.8×4.6 m, origin 1.29 m above its base → lift by 1.29×scale); small health bar; `take_damage(amount, from, knock)` like Enemy; on destroy crumble tween + `Quests.report_kill("totem")` + a little gold. Make the player's `_swing_hits`/`_whirl_hits`/`_dash_hits` iterate `enemies` **and** `breakables` (use untyped nodes, not `as Enemy`). Place in the camp, quarry and crypt areas (inside their occupancy circles).
- New quest-item positions go in `village.gd` `QUEST_ITEMS`; kegs/key/sack/log all use the golden beam.
### 4d. After that, then test
Add tools tests (`daytest`: screenshots at 9:00/19:30/22:00/4:00; `eventtest`: force `night_started`, check waves, safety, success/fail, dawn dissolve; extend `questtest` for new quests), check fps (`perftest`) at night with all the lights, update `CLAUDE.md` + `README.md`, add a memory note if useful.

## 5. Suggestions Theodore asked for (offer these)
1. **Save/load + main menu** (progress, quests, bar, gold, day/night). 2. **Minimap/compass** with quest markers (big map!). 3. ~~Shop and equipment~~ (done, see 3b). Ideas: more gear tiers/set bonuses, a tavern shop with food buffs, repair or enchanting. 4. **Audio**: music + ambience + hit sounds (freesound.org CC0), church bell for the invasion. 5. **Weather** (rain/fog) and a **horse/mount** for the big map. 6. **Fishing** at the pond, **crafting**. 7. Allies: village guards that fight beside George during the invasion. 8. Skeleton "elite" random spawn events and a second dungeon (the crypt interior).

## 6. File map (where things are)
`scripts/`: `stats.gd`, `shop_data.gd`, `shop_window.gd`, `talent_data.gd`, `talent_node.gd`, `hero_window.gd`, `ui_kit.gd` (see 3b), `player.gd` (movement, camera, combat, skills, potions, interaction, teleport), `enemy.gd`, `enemies.gd` (KINDS/SPAWNS/spawn_invader/loot), `projectile.gd`, `village.gd` (world builder: BUILDINGS, BUILDING_PROPS, QUEST_ITEMS, CHESTS, SIGNPOSTS, zones, villagers), `terrain.gd` (ground, paths, plants, gardens, pond), `interiors.gd` (DEFS furniture/chests/tavern regulars), `quests.gd` (autoload; state machine, rewards, tracker), `quest_data.gd` (story/NPCs/quests), `npc.gd`, `villager.gd`, `villager_data.gd`, `chest.gd`, `pickup.gd`, `quest_item.gd`, `interact_spot.gd`, `skill_data.gd`, `icons.gd`, `action_slot.gd`, `hud.gd`, `strings_el.gd`, `inputs.gd`. `shaders/`: ground, path, patch, plant, water (+ sky to be added). `scenes/`: `main.tscn`, `player.tscn`, `enemy.tscn`. `tools/`: test drivers. `assets/`: KayKit models (characters, world, items, furniture, graveyard).
Collision layers: 1 world, 2 player (mask 1+16), 4 enemies (mask 1+2), 16 NPCs/villagers. Anything in group `interactables` implements `interact_prompt()`, `interact_range()`, `interact(player)`.

## 7. Known gaps
No save/load, minimap or audio. Interior camera can clip near walls. Camera can clip into an enemy standing behind George. `_to_delete/` still in the folder (safe to delete). Enemies now sidestep obstacles but still have no real pathfinding.
