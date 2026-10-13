# Changelog

## 1.0.1 (2026-10-13) — graphics setting
**New in this version**
- **A "Γραφικά" setting in the settings page** (title and pause menu) for computers where the normal graphics mode draws black or broken surfaces: Υψηλά (default), Μεσαία (Vulkan Mobile renderer, almost the same picture) and Συμβατά (OpenGL, for very old cards). "Εφαρμογή και επανεκκίνηση" saves the game (from the pause menu), writes an `override.cfg` next to the exe and starts the game again; the choice stays for every later start, no `.bat` needed. Choosing "Υψηλά" removes the file again (only a file the game wrote itself; a hand-made `override.cfg` is never touched). It works only in the exported game; in the editor it says so and writes nothing.
- The settings page got more compact (the key list is shorter) to make room.
- New tests: `graphics_mode_test` (headless) and the windowed `graphicsmenutest`.

## 1.0.0 (2026-10-13) — updates, credits, a splash screen and the first full release
**New in this version**
- **Update with one click.** When the title menu opens the game asks GitHub whether a newer release exists (only the latest published release, never a pre-release). If there is one, a card at the top right shows the version and what is new with an "Ενημέρωση" button: the game downloads the zip, checks its SHA-256, replaces its own exe (the old one is kept as `.old` until the next start) and restarts, keeping the graphics mode in use. An option in the settings turns the check off. Saves and settings are untouched. (`scripts/update_logic.gd`, `update_installer.gd`, `updater.gd`.)
- The title menu shows the version (bottom right), the creators line "Δημιουργοί: Theodore Sfakianakis & George Sfakianakis" (bottom left) and has a new "Συντελεστές" page. The title menu buttons now hang from just below the title.
- **A splash screen instead of the Godot logo:** while the game starts and builds the world a picture of the village at golden hour with the Greek title, "Φόρτωση…" and the creators line is shown (`assets/ui/splash.png`, rendered by `tools/splashshot.gd`).
- `Play-Mobile-Renderer.bat` and `Play-Compatibility-Renderer.bat` come with the download for computers where the normal graphics mode looks broken (black surfaces on weaker or older graphics cards).
- `tools/release.py` builds the Windows zip, the checksum and the GitHub release in one command; `export_presets.cfg` is now part of the repository.
- New tests: `update_logic_test`, `update_installer_test`, `settings_update_test`, `updater_flow_test` (a real `Updater` against a local HTTP server) and the windowed `updatemenutest`; `updater_live_test` reads the real GitHub API.

**Notes**
- Everything from 0.16-beta (the Great Tree and its lake, the weather) is included. 0.16-beta has no updater, so it must be replaced by hand once with this version; after that updates come with one click.
- The exe is not code-signed (Windows SmartScreen may warn on the first manual start), and the checksum protects against a damaged download, not against a hijacked GitHub account.

## 0.16-beta (2026-10-13) — the Great Tree and its lake, and the weather
**New in this version**
- **This release also carries the weather system** (the 0.15-beta entry below was never released on its own): fog, rain and thunderstorms, F6 to change them.
- **A new place in the east of the map** (`scripts/great_tree.gd`, `scripts/tree_meshes.gd`, `scripts/balloon.gd`, about 170 m east of the well; inspired by a picture Theodore showed): a turquoise lake with a central rock island that carries a **giant tree** and two houses, four smaller islands with umbrella trees, flowers and a golden chest, **rope bridges** with rails, a **stone causeway** that winds around the central island on pillars and lands on the plateau, lanterns, and **hot-air balloons** drifting overhead (one is moored on the entry island). Follow the new signpost "Το Μεγάλο Δέντρο →" east of the market; the place is named "Η Λίμνη του Αιωνόβιου" on the big map.
- Everything is built in code in the game's low-poly style (flat shading, vertex colours) and everything is walkable (trimesh colliders, bridge rails, slopes under 15 degrees); the lake is shallow wading water. No gameplay change; only three real lights at night (the lantern heads glow through an emissive material).
- The quest barrel moved to (124, -26) and its two skeletons to (112, -22) and (110, -38) to make room.
- Guards no longer wedge on the corner of a wall while walking around it (`Guard._steer` leans slightly away from the wall).
- New test drivers: `tree_meshes_test`, `great_tree_walk_test` (a capsule like George walks three routes, rails and cliffs), `great_tree_props_test`, `balloon_test`, `great_tree_integration_test` (headless), `greattreeshot` (screenshots + fps; run its `day` and `night` parts one after the other on a GPU shared with other programs).

**Not done yet:** a rideable balloon, NPCs or quests in this place, swimming, fish in this lake.

## 0.15-beta (2026-10-13, shipped inside 0.16-beta) — weather
**New in this version**
- **Weather in the village** (`scripts/weather.gd`, node `Weather`): clear, fog, rain and thunderstorm, picked at random every 2 to 5 minutes (a storm only after rain) and blended smoothly over about 25 s. Atmosphere only: nothing changes in combat, quests or the invasion.
- **Look:** a grey sky without sun, moon or stars, thick fog, a dimmer sun, dark clouds, a darker wet ground that dries slowly after the rain (global shader uniform `wetness`), rain streaks that follow George (`GPUParticles3D`, fainter at night), lightning flashes in a storm. `DayNight` stays the only writer of the Environment and reads the weather numbers.
- **Sound** (synthesized): a rain loop outdoors, a duller roof loop inside buildings, thunder after each lightning flash, quieter birds and crickets in the rain, more wind in a storm.
- **HUD:** a weather icon (cloud, rain, storm) replaces the sun or moon next to the clock, a Greek message when the weather changes, and **F6** changes the weather by hand (listed in the "i" help page).
- Indoors, in the catacombs and in the Frontier there is no weather. Not saved (the weather starts clear on every launch).
- New test drivers: `weather_logic_test`, `weather_look_test`, `weather_rain_test`, `weather_hud_test`, `weather_sound_test` (headless), `weathershot` (screenshots + fps; run its `day` and `night` parts one after the other on a GPU shared with another Godot).

**Not done yet:** the new sounds are unheard (audio tuning by ear), wind on the grass and trees, puddles and splashes, snow in the village.

## 0.14-beta (2026-10-13) — fishing and food
**New in this version**
- **Fishing at the pond:** a wooden dock with a bucket on the pond shore (`Village._build_dock`, **R** at the dock). A one-button timing mini-game (`scripts/fishing.gd`): cast, wait 2 to 6 s, the float dips, then press **R / Enter / Space / left click** while the marker is in the green zone of the bar (works over AnyDesk). Escape cancels; pulling too early or too late loses the fish.
- **13 fish** (`ShopData.JUNK`): five common (Γοβιός, Πέρκα, Σαζάνι, Κυπρίνος, Γριβάδι), four uncommon (Πέστροφα, Χέλι, Γλάνος, Λούτσος), three rare (Ηλιόψαρο only by day, Φεγγαρόψαρο only by night, Χρυσόψαρο του Αγίου) and the legendary **Ο Βασιλιάς της Λίμνης**. Rarer fish have a narrower zone and a faster marker. They are kept in the bag like the skeleton junk and the market buys them (6 to 150 gold).
- **Fish journal:** "Νέο είδος! (n/13)" on the first catch of a species, "Ψάρια: n/13" in the equipment tab of the hero window, saved in the save game (`fish_seen`).
- **The tavern cook Θανάσης** behind the bar (shopkeeper pattern, `ShopData.SHOPS["kitchen"]`): the kitchen window has two tabs, **Φαγητά** (Φασολάδα, Τυρόπιτα, Κρέας με Πατάτες for gold) and **Μαγείρεμα** (Τηγανητά Ψαράκια, Ψαρόσουπα, Ψητό του Αγίου, Γιορτινό του Βασιλιά from fish of a rarity plus a little gold; the cheapest fish is used first).
- **Food buffs:** a meal gives a timed buff (10 minutes, the feast 15) through a new `Stats` source `"food"` (health, regeneration, damage, defense, crit, speed, lifesteal). One meal at a time, a new one replaces the old; a pill with the meal name and the minutes left shows above the action bar. Not saved (like potion buffs).
- New sounds (synthesized): `fish_cast`, `fish_bite`, `fish_catch`, `fish_escape`, `eat`. New icons `fish` and `food`.
- **Villager names fit their model:** the Barbarian and the Knight get men's names, the braided Rogue gets women's names, the Mage and the hooded Rogue either (`VillagerData.name_for`). Names of story NPCs and stall owners are no longer used for ambient villagers.
- **Guards no longer get stuck on props:** a guard that pushes against an obstacle sidesteps left or right along it and keeps going until the straight way to its goal is free; a dead end makes it switch side (`Guard._check_blocked`).
- New test drivers: `fish_data_test`, `kitchen_test`, `kitchen_window_test`, `fishing_test`, `gender_test`, `guard_snag_test` (headless), `fishshot` (screenshots + fps).

**Not done yet:** audio tuning by ear (the new sounds are unheard), fishing in other places, carrying meals on the action bar.

## 0.13-beta (2026-10-13) — story part 3: the Frontier beyond the mountains
**New in this version**
- **The Frontier** (`scripts/frontier.gd`): a new outdoor region reached through a stone arch in the northern mountains (east of the old crypt, sealed until Παπά-Σταύρος offers "Η Πύλη του Περάσματος"). Built once on the first visit at a far-away origin; the sky, sun and clock keep running. Three zones: the **Βουνίσιο Πέρασμα** (snow, dead trees, boulders, lantern posts, skull posts), the **Καταφύγιο των Προσφύγων** (tents around a big fire, safe zone) and the **Φρούριο της Σκιάς** (walls with battlements, towers, the dark keep, purple braziers, a sealed gate). The layout is data at the top of the file (`SPAWNS`, `CHESTS`, `SYMBOLS`, zone constants). 60 fps by day and by night.
- **Story part 3 (6 quests, 2 new NPCs Μοναχός Ιλαρίων and Ελπίδα η Κυνηγός):** "Η Πύλη του Περάσματος" → "Οι Φρουροί του Περάσματος" + "Τα Σύμβολα της Σκιάς" (3 golden symbols open the fortress gate) → "Το Τείχος" → "Ο Άρχοντας του Βουνού" → "Η Επιστροφή" (hand-in at Παπά-Σταύρος, "Συνεχίζεται…"). Part 2 no longer ends with "Συνεχίζεται…"; it leads into part 3 (an existing save that finished part 2 simply gets the new quest from Παπά-Σταύρος).
- **New creatures:** Ιππότης της Σκιάς, Ψυχοσυλλέκτης (blue souls that slow George down: new `Player.slow`), the mini-boss **Γιγάντιος Σκελετός** and the final boss **Μαλάκαρ ο Σκοτεινός Άρχοντας**, who enrages below half health (faster, redder, calls shadow knights). Bosses return while their quest is active.
- **Region support** (`Interiors.enter_region` / `exit_region` / `in_region()`): the minimap and the village map are hidden there, new music `mountain`, cold wind and snow footsteps (all synthesized), and saving inside the Frontier stores the real position (`in_frontier`) and rebuilds the region on load. A night invasion is skipped while George is away, and he cannot leave the village through the gate while an invasion is running.
- **Ground shaders far from the origin:** the noise of the ground, path and patch shaders turned into hard squares at x = -6000 (float precision). They now take a `world_offset` uniform (`Terrain.set_world_offset`); in the village it is 0, so nothing changes there.
- New test drivers: `part3test` (plays all of part 3), `frontiershot` (screenshots + fps, `night` variant), `part3_data_test`, `part3_mobs_test`, `frontier_enter_test`, `frontier_build_test`, `part3_hooks_test`, `passgateprobe`. `part2test` now expects part 2 to hand over to part 3.

**Not done yet:** audio tuning by ear (the mountain music and wind are new), a map of the Frontier, the rest of the backlog (see `HANDOVER.md`).

## 0.12.1-beta (2026-10-13) — modern HUD, minimap zoom, more free screen
- **More free screen:** the key-hint frame at the bottom is gone. A small round **"i" button** (bottom-right, or **F1**) opens a controls help page (every key and mouse action with key caps), also reachable from the Esc menu (title and pause menu: "Χειριστήρια"). The **action bar moved to the very bottom and is compact** (46 px slots instead of 62, smaller dock); the P/T/I/M key line was dropped and only a small "★ Πόντοι ταλέντων" reminder appears above the bar while talent points are free. Test: `uishot4`.
- **Modern HUD:** every bar and panel was redesigned. New `FancyBar` (`scripts/fancy_bar.gd`): rounded capsule with a glossy gradient fill, soft shadow, segment ticks, a damage trail that lags behind, and text inside; used for health, XP, the invasion safety bar and slim quest-progress bars (the quest tracker now shows a bar per objective). The hero card has a round gold level badge, coin and potion icons and an `H` key cap. Glass panels with rounded corners, soft shadows and a bright top edge everywhere (tracker, dialogue with a gold name tag, shop and hero windows, menus, message pills, a clock capsule, an action-bar dock with glossy rounded slots and key badges), key caps in the `[R]` prompt, raised rounded buttons, rounded map frames, and the Segoe UI font (fallback: engine default). Health bars over enemies and totems are rounded and anti-aliased. Tests: `uishot`, `uishot2`, `uishot3` (screenshots).
- **Minimap zoom:** `+` and `−` buttons left of the minimap (and the keys + / − / numpad) zoom between 35 and 170 m; the zoom level is kept while the game runs. A **map button (M)** next to them opens the big map for players whose M key does not arrive (remote desktop), and the big map has a **✕ close button**. Test: `minimapzoomtest`.

## 0.12-beta (2026-10-12) — the catacombs and story part 2
**New in this version**
- **The Catacombs** below the old crypt: a large underground level (`scripts/catacombs.gd`, layout = `ROOMS`/`CORRIDORS`/`SPAWNS`/`CHESTS`/`PAGES` at the top of the file) with a safe hall of candles, a great hall, west and east wings, three seal chambers, a vault, two alcoves and the abbot's chamber behind a sealed gate. Entered through the crypt door (R), sealed until the quest "Η Κάθοδος" is accepted. Stone textures are generated in code; torches, coloured room lights, glowing seals, pillars, coffins, bones and chests; 60 fps.
- **New creatures:** Φύλακας της Κατακόμβης (armoured, blue), Ακόλουθος του Σκότους (red mage), three named Φύλακες των Σφραγίδων (Οστών / Φλόγας / Σκιάς) and the final boss **Αρχιερέας της Σκιάς**, who fires orbs and summons skeleton helpers. Dungeon creatures only notice George with a clear line of sight (no aggro through walls) and give up after a while.
- **Story part 2 (5 quests, new NPC Αδελφή Θεοδώρα):** "Η Κάθοδος" → "Οι Φύλακες του Σκότους" + "Οι Σελίδες της Ευχής" (3 golden pages) → "Οι Τρεις Σφραγίδες" (the three wardens; the gate opens) → "Ο Αρχιερέας της Σκιάς" (hand in at Παπά-Σταύρος, "Συνεχίζεται…"). New objective type `reach`.
- The end of part 1 no longer shows "Συνεχίζεται…"; it now leads into part 2 (an existing save that finished the Bone King simply gets the new quest from Παπά-Σταύρος).
- Dying in the catacombs wakes George in the village (outdoor light restored). Cold dark lighting, crypt music and ambience, stone footsteps inside.
- **A much richer village square** (`scripts/square.gd`, built around the well): inlaid paving rings and sun rays, a stone kerb around the flower bed, 8 benches and 8 lamp posts joined by bunting, **four market stalls** with striped awnings, goods and vendors (vegetables, bread, herbs/potions, wine; they call out Greek lines and go home at dusk), the **statue of Agios Vlasis** on a pedestal, a notice board, a small **festival stage** with two musicians, and a big tree with benches. Lamps light up at night. Still 60 fps.
- New test drivers: `catacombtest` (screenshots, fps, door/exit), `part2test` (plays the whole of part 2), `squareshot` (square screenshots, `-- <dir> night` for night).

**Not done yet:** audio tuning by ear, more areas beyond part 2 (see `HANDOVER.md`).

## 0.11-beta (2026-10-12) — new quests, totems and guards
**New in this version**
- **Two new NPCs:** Βασίλης ο Λοχαγός (watchtower) and Στέλιος ο Μυλωνάς (windmill).
- **Six new side quests:** "Τα Σακιά του Μυλωνά", "Ξύλα για τη Φωτιά", the chain "Οι Τοξότες" → "Οι Μάγοι" → "Οι Βάναυσοι" (reward +5 damage), and "Τα Οστέινα Τοτέμ". Quest rewards can now include power and speed potions.
- **Bone totems:** appear while their quest is active at the camp, the quarry and the crypt gate; they have a health bar and break under George's sword.
- **Village guards:** during a night invasion guards defend the well: 2, plus one for every finished quest of Βασίλης (up to 6).
- New test drivers: `sidequesttest`, `guardtest`, `propshot`.

**Not done yet:** more areas and story, a second dungeon, audio tuning by ear (see `HANDOVER.md`).

## 0.10.1-beta (2026-10-12) — saving, menus and remote-play fixes
**New in this version**
- **Save game:** plain-text JSON (`savegame.json`), autosave on quest completion, level up and at dawn, plus manual save. Saves level, gold, gear, talents, action bar, position, quests, time, defeated bosses, opened chests and collected quest items.
- **Menus:** title menu (Continue / New game / Settings / Quit) and an Esc pause menu. The prologue now plays only on a new game.
- **Settings:** volume sliders, audio output device and **key re-binding** (saved in `settings.json`).
- **Remote-desktop (AnyDesk) fixes:** keys are bound by physical and logical code, Space/Enter advance dialogue, Enter also interacts, jump respects the dialogue lock, F9 cycles the audio device, F12 shows an input diagnostics overlay.

**Not done yet:** more NPCs/quests, totems, village guards (see `HANDOVER.md`).

## 0.10-beta (2026-10-12) — map, 1080p and sound
**New in this version**
- **Minimap and map (M):** corner minimap plus a full-screen map from a live top-down capture of the world. Quest markers: "!" new quest, "?" hand-in, gold diamonds for quest items and bosses; red dots for enemies; a pulsing ring at the well during an invasion; named places on the big map.
- **1920x1080:** the window opens at 1080p with native 3D rendering (HUD scaled 1.5x). F11 toggles fullscreen.
- **Music:** 9 looping tracks (day, night, wilderness, combat, boss, invasion, crypt, tavern, church) that follow what is happening and crossfade.
- **Sound effects (about 70):** combat, footsteps by surface, all skills, UI, shops, quests, chests, doors, skeleton/archer/mage/brute/boss sounds, church bells, war horns, rooster, wolves and owls.
- **Ambience:** birds by day, crickets at night, wind, tavern and church atmosphere, the camp fire, the pond.
- F7 toggles music, F8 toggles sounds.
- All audio is synthesized by `tools/gen_audio.py` (numpy only), so it is free and editable. It has only been checked numerically, not by ear: expect to tune levels.

**Not done yet:** save/load, more NPCs/quests, totems (see `HANDOVER.md`).

## 0.9-beta (2026-10-12) — day, night and the invasion
**New in this version**
- **Day/night cycle:** 10-minute days, custom sky (sun, moon, stars), coloured sunsets and dawns, clock with sun/moon icon in the HUD.
- **Night lighting:** door lights, lantern posts around the square, camp and crypt fires, a lantern on George, fireflies. Outdoor villagers go indoors at dusk and return at dawn.
- **Night invasion:** every night the dead march on the village well in 3 waves from 4 gates. A "village safety" bar drains while they stand at the well. Win for XP, gold, potions and a golden chest; lose and George loses 15% of his gold. Leftovers crumble at dawn. Mini-boss (Οστέινος Πολέμαρχος) from night 3.
- **New side quest:** "Η Νύχτα της Εισβολής" from Παπά-Σταύρος.
- New test drivers: `daytest`, `eventtest`, `nightinterior`, `shelter`, `skytest`, `perftest -- night`.

**Not done yet:** save/load, minimap, audio, more NPCs/quests, totems (see `HANDOVER.md`).

## 0.8-beta (2026-10-12) — first public snapshot
Playable single-map RPG in Godot 4.7, all in-game text in Greek.

**World and story**
- Large village map with enterable buildings, villagers, tavern regulars, three story areas (west camp, SE quarry, north crypt).
- Prologue, 4 quest NPCs, 5 quests, ending.

**Combat and mobs**
- WoW-style controls, 3-hit combo, block, 8-slot action bar.
- Skeleton warriors, minions, archers, mages, brutes, two bosses; loot, XP, levels up to 20.

**New in this version**
- **Shops:** Κυρά-Ελένη (market) and Νικήτας (blacksmith) with buy/sell windows. Skeleton junk loot sells at the market.
- **Equipment:** weapon, armor and shield in 4 tiers, visible on George.
- **Talent tree (T):** 3 branches (Φρουρός, Πολεμιστής, Άγιος), 1 point per level, respec at the church.
- **6 new skills:** Κραυγή Πρόκλησης, Τείχος, Αιματηρή Μανία, Κεραυνός του Πολέμου, Θεία Φλόγα, Ιερός Κύκλος, plus the passive Ανάσταση.
- New stat layer (defense, crit, lifesteal, cooldown reduction, regeneration, healing bonus).

**Not done yet:** day/night cycle, night invasion, save/load, minimap, audio (see `HANDOVER.md`).
