# Οι Περιπέτειες του Γιώργου στον Άγιο Βλάση
*(George Adventures at Agios Vlasis)*

3D RPG in Godot 4.7, fully in Greek: a big village map with enterable houses, villagers, a story with five quests, skeleton enemies, loot chests, skills and potions, shops with equipment, and a talent tree.

## Run it
1. Install **Godot 4.7** (free, standard build, not .NET): https://godotengine.org/download
2. Open Godot -> Import -> select `project.godot` in this folder.
3. First open takes ~1 minute (it imports the 3D models). Press **F5** to play.

## Controls (World of Warcraft style)
The mouse cursor is free. Hold a mouse button to move the camera.

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Look + steer George | Hold **right mouse**, move mouse | Right stick |
| Orbit camera only | Hold **left mouse**, move mouse | |
| Run forward | Hold **both** mouse buttons | |
| Forward / back | W / S | Left stick |
| Turn (strafe while right mouse held) | A / D | |
| Strafe | Q / E | |
| Run | Shift | Left stick click |
| Jump | Space | A |
| Attack (3-hit combo) | Quick left click (no drag) / F / J | X |
| Block | K / Ctrl | Left bumper |
| Talk / open / enter | R | B |
| Action bar (skills, potions) | 1 – 8, or click | |
| Health potion | H | Y |
| Skill book (drag skills to the bar) | P | |
| Talent tree (1 point per level from level 2) | T | |
| Equipment and stats | I | |
| Shops (market, blacksmith) | R on the shopkeeper; Esc closes | |
| Zoom | Mouse wheel | |

## Project layout
- `scripts/player.gd`      George: movement, camera, combat, skills, potions, interaction
- `scripts/village.gd`     The world builder. **Edit the BUILDINGS / CHESTS / QUEST_ITEMS lists at the top.**
- `scripts/terrain.gd`     Meadow ground, paths, flowers, gardens, pond (with `shaders/`)
- `scripts/interiors.gd`   Inside of the houses. **Edit DEFS to rearrange furniture.**
- `scripts/enemies.gd`     Enemy spawner. **Edit SPAWNS / KINDS to place or tune skeletons.**
- `scripts/quest_data.gd`  **The story, NPCs, quests and dialogue (Greek).**
- `scripts/villager_data.gd` Villager names, gossip and conversations (Greek)
- `scripts/skill_data.gd`  Skills and potions
- `scripts/shop_data.gd`   **Shops: equipment, prices, junk loot (Greek).**
- `scripts/talent_data.gd` **The talent tree: 3 branches x 9 talents (Greek).**
- `scripts/stats.gd`       Stat modifiers from equipment and talents
- `scripts/shop_window.gd`, `hero_window.gd`, `talent_node.gd`, `ui_kit.gd`  The shop window, the P/T/I window and shared UI styles
- `scripts/strings_el.gd`  All other UI text (Greek)
- `scripts/hud.gd`         On-screen UI
- `scripts/inputs.gd`      All controls (physical keys, so they work on a Greek layout)
- `tools/`                 Automated test drivers with screenshots
- `assets/`                KayKit models (CC0, free for commercial use)

## Credits
Art by Kay Lousberg (KayKit) — Adventurers, Skeletons, Medieval Hexagon, Dungeon Remastered, Furniture Bits and Halloween Bits packs, CC0.
