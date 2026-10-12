# Changelog

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
