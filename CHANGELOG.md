# Changelog

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
