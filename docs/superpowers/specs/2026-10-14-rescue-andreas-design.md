# Rescue Andreas — design

Date: 2026-10-14. Status: approved by Theodore in chat.

## Goal
A few minutes into a game, a window warns George that his friend Andreas is surrounded by skeletons. George must reach him before he dies. All in-game text is Greek.

## Trigger
- New node `Rescue` (`scripts/rescue.gd`) in `main.tscn`, group `rescue`. Pure rules in `scripts/rescue_rules.gd` (class `RescueRules`, no scene access).
- Counts only active play time: it does not advance while a menu is open, the game is paused, a dialogue/shop/fishing is running (`player.busy`), or while George is indoors / in the catacombs / in the Frontier (`Interiors.is_inside()`, `in_region()`).
- Random limit between `MIN_DELAY` 180 s and `MAX_DELAY` 300 s, drawn once per game.
- When the limit is reached it waits (does not fire) while George is busy, indoors, in a region, dead, or a night invasion is running; it fires on the first free moment.
- Once per game. State saved: `rescue.state` (`WAITING`, `ALERT`, `ACTIVE`, `SAVED`, `FAILED`), `rescue.elapsed`, `rescue.limit`, `rescue.health`.
- A new game resets it. Loading a game in `WAITING` continues counting; in `ACTIVE` rebuilds the scene with the saved health.

## The window
- Modal card built with `UiKit` (dark glass panel), title «Κίνδυνος!», text exactly:
  `Ο φίλος σου ο Αντρέας είναι σε κίνδυνο, ακούω τις φωνές του. Γρήγορα οι σκελετοί τον έχουν περικυκλώσει! Σώσε τον!`
- Button «Πάω!» (also Space / Enter / R). Alarm sound `rescue_alert`. George is `busy` while it is open.
- Closing it starts the quest and the rescue scene.

## Quest `andreas`
- `QuestData.QUESTS["andreas"]`: title «Σώσε τον Αντρέα», giver and turn_in `andreas`, no `requires`, started by `Quests.start_event_quest("andreas")` (state ACTIVE directly; the normal availability pass never offers it, `"event": true`).
- Objective type `rescue` (count 1, text «Σώσε τον Αντρέα») with `Quests.report_rescue()`.
- New quest state `S.FAILED` (not shown in the tracker, no reward).
- Reward: 250 XP, 120 gold, 2 health potions. Hand-in dialogue from Andreas.
- NPC `andreas` in `QuestData.NPCS` (model Rogue_Hooded, idle lines). After the rescue he stands in the square as an ordinary `Npc`; restored on load.

## The scene
- Site: one fixed open meadow about 70–90 m from the well (`Rescue.SITE`, chosen on the map, clear of buildings, trees, the pond and the stable; `Village._occupy` so nothing is scattered on it).
- Andreas: a stationary character with a name tag and a health bar (`FancyBar.texture()`), plays hurt/idle animations.
- Six skeletons in a ring (radius 4 m): mix scales with the player level (minions and warriors; a rogue from level 5). Spawned through `Enemies.spawn_extra`-style call `Enemies.spawn_besiegers(kinds, site, andreas_node)`, they never respawn and drop normal loot and XP.
- Besiege stance in `enemy.gd` (`besiege_target`): attack the target in place (face it, play attack, deal drain through `Rescue`) until George comes within aggro range, then fight George normally and, if George leaves, return to the target.
- Drain: `RescueRules.drain(alive_count, delta)`. Full health lasts `FULL_TIME` 150 s with all six alive; the rate is proportional to `alive / 6`. Andreas' health is shown in the quest tracker bar and above him.
- Markers: gold diamond on the minimap (sticks to the border when far away) and on the big map, labelled «Αντρέας».

## Outcomes
- All besiegers dead while Andreas lives: `Quests.report_rescue()` → READY; Andreas thanks George; hand in to get the reward; he then walks (teleports at fade) to the square.
- Andreas' health reaches 0: death animation, message «Ο Αντρέας χάθηκε…», quest FAILED, banner, remaining besiegers dissolve after 20 s. No penalty.
- George dies and respawns while the rescue is active: the timer keeps running (the scene stays).
- A night invasion that begins while ACTIVE: the rescue continues (outdoors); the invaders do not target Andreas.

## Errors and edge cases
- Spawn points are nudged to free ground by the existing `_free_spot`.
- If the site collider is not ready (first physics frames) the scene waits two physics frames like `Enemies._ready`.
- Saving while ACTIVE stores the surviving besiegers count only; on load the ring is rebuilt with that many skeletons.

## Tests
- `rescue_rules_test` (headless): delay range, wait conditions, drain formula, state transitions.
- `rescue_flow_test` (headless): alert after the time, quest starts, killing the skeletons gives READY and the reward, letting him die gives FAILED, save/load round trip in each state. Back up and restore `savegame.json` and `.bak`.
- `rescueshot` (windowed): screenshots of the window, the ring and the health bar, plus fps.
- Run the existing `questtest`, `savetest`, `minimaptest` for regressions.
