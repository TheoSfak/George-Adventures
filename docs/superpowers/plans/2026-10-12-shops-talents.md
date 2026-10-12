# Shops, Equipment, Talent Tree & New Skills — Implementation Plan

> **For agentic workers:** execute task-by-task (inline). Steps use checkbox syntax. No git repo exists; a backup of `scripts/ tools/ scenes/` was copied to the session scratchpad before work began.

**Goal:** Market + Blacksmith shops with a buy/sell window and equipment (weapon/armor/shield, 4 tiers), a 3-branch talent tree (1 point per level from level 2) with 6 new active skills, all in Greek.

**Architecture:** One `Stats` object on `Player` aggregates modifiers from sources (`equip`, `talents`); `Player._recalc()` turns them into `max_health` / `sword_damage` (effective values, so existing code and tests keep working) plus extra stats read at the point of use (defense, crit, lifesteal, cooldown reduction, regen, heal multiplier, ...). Data lives in plain-text const dictionaries (`shop_data.gd`, `talent_data.gd`, `skill_data.gd`). UI is built in code like the existing HUD (`ui_kit.gd` shares styles).

**Tech Stack:** Godot 4.7.2, GDScript, KayKit CC0 assets. Verification via `godot --headless --import` / `--quit-after` compile checks and `tools/*.gd` windowed drivers with screenshots.

## Global Constraints
- ALL in-game text Greek (UI, items, talents, dialogue); code/comments/file names English.
- Greek strings only written with Write/Edit tools (UTF-8), never shell heredocs; no `%%` in non-formatted strings.
- GDScript uses tabs. Only free assets. 60 fps must hold (`tools/perftest.gd`).
- Collision layers: 1 world, 2 player, 4 enemies, 16 NPCs. Interactables implement `interact_prompt()`, `interact_range()`, `interact(player)`.
- Test drivers: `await process_frame` first, set `/root/Quests`.intro_seen = true; no typed references to classes mentioning `Quests` (use untyped access).
- Existing behaviours that must not change with no gear/talents: guard takes 75% off (`40 dmg -> 10`), power strike `15*2.2`, whirlwind `*1.4`.

## File structure
| File | Responsibility |
|---|---|
| `scripts/ui_kit.gd` (new) | static UI helpers: panel style, labels, button styles, icon control |
| `scripts/stats.gd` (new) | `Stats`: modifier sources, `total(key)`, Greek `describe(mods)` |
| `scripts/shop_data.gd` (new) | `ShopData`: EQUIPMENT, JUNK, SHOPS, helpers |
| `scripts/shop_window.gd` (new) | `ShopWindow`: modal buy/sell UI |
| `scripts/talent_data.gd` (new) | `TalentData`: branches, nodes, tier rules, `mods_for()` |
| `scripts/talent_node.gd` (new) | `TalentNode`: one clickable node control |
| `scripts/hero_window.gd` (new) | `HeroWindow`: tabs Ικανότητες / Ταλέντα / Εξοπλισμός (P, T, I) |
| `scripts/player.gd` | stats, equipment, talents, new skills, hit helper |
| `scripts/skill_data.gd` | 6 new talent skills, `health_big` item |
| `scripts/icons.gd` | new icons |
| `scripts/action_slot.gd` | locked state for talent skills, cooldown totals |
| `scripts/hud.gd` | HeroWindow + ShopWindow hosting, new buffs |
| `scripts/npc.gd`, `quest_data.gd` | shopkeeper NPC support |
| `scripts/interiors.gd` | shopkeepers in market/blacksmith, respec shrine in church |
| `scripts/pickup.gd`, `enemies.gd` | junk drops (+ remove 4x duplicated potion-glow block) |
| `scripts/inputs.gd`, `strings_el.gd` | keys T / I, Greek strings |
| `tools/shoptest.gd`, `tools/talenttest.gd` (new) | verification drivers |

## Tasks
### Task 1: Stat layer in Player (no visible change)
**Interfaces — Produces:** `Stats.set_source(src: String, mods: Dictionary)`, `Stats.total(key) -> float`; `Player.stats: Stats`, `Player.base_max_health`, `Player.base_damage`, `Player.gear_owned: Array[String]`, `Player.equipped: Dictionary` (`weapon/armor/shield -> id or ""`), `Player.talents: Dictionary`, `Player.junk: Dictionary`, `Player._recalc()`, `Player.heal(amount)`, `Player.cooldown_total(id)`.
- [ ] Create `stats.gd`; stat keys: `damage_add, damage_mult, hp_add, defense, block_add, speed_mult, crit, cdr, lifesteal, heal_mult, regen, guard_time_add, prayer_add, ps_mult, whirl_radius, last_stand, rebirth`.
- [ ] Player: level-up/reward growth goes to `base_*`; `_recalc()` sets effective `max_health`/`sword_damage`; defense in `take_damage`; `_hit()` helper (crit, lifesteal, stun) replaces direct `take_damage` in swing/whirl/dash; cooldown reduction; speed; regen; heal multiplier on potions/prayer.
- [ ] Verify: `godot --headless --import`, then `tools/skilltest.gd` prints unchanged numbers.

### Task 2: Shop data, equipment, junk loot
- [ ] `shop_data.gd`: 12 gear items (4 tiers × weapon/armor/shield), 3 junk items, SHOPS (market: potions + `health_big`, buys junk; blacksmith: gear, buys gear at 40%).
- [ ] Player: `equip(id)`, `unequip(slot)`, `buy/sell` primitives, equipment visuals (shield node swap, weapon node/scale + glow overlay, armor tint overlay).
- [ ] `health_big` consumable in `SkillData.ITEMS` + `use_consumable`.
- [ ] Junk: `Pickup` kinds `junk_bone / junk_rust / junk_charm`, `enemies.gd` drop rolls; fix duplicated glow code in `pickup.gd`.

### Task 3: UI kit + ShopWindow + shopkeepers
- [ ] `ui_kit.gd`; `hud.gd` delegates `_panel_style`/`_plain_label` to it.
- [ ] `shop_window.gd`: tabs Αγορά/Πώληση, rows with icon, name, stat comparison (green/red), price, button; Esc/R/✕ closes; sets `player.busy`.
- [ ] `hud.open_shop(shop_id)`; NPC entries `elena`, `nikitas_forge` with `"shop"` field; `Npc.interact` opens greeting then shop; `interiors.gd` DEFS `"shopkeeper"` entries.

### Task 4: Talent data + HeroWindow + respec
- [ ] `talent_data.gd` (3 branches × 9 nodes, tier gates 0/5/10 points spent in branch), `Player.talent_points_free()`, `can_learn()`, `learn_talent()`, `respec()`, `respec_cost() = 50 * level`.
- [ ] `hero_window.gd` replaces the HUD skill book; keys P (skills), T (talents), I (equipment); `talent_node.gd` with drag-to-bar for active talent skills.
- [ ] Church shrine `InteractSpot` for respec.

### Task 5: Six new skills
- [ ] `SkillData.SKILLS`: `taunt`, `wall`, `frenzy`, `leap`, `flame`, `sanctuary` (each `"talent": "<node id>"`); `ActionSlot` lock logic via `Player.knows_skill()`.
- [ ] `Player.use_skill` cases + passive upgrades (power strike, whirlwind radius, prayer, guard duration) + Ανάσταση.
- [ ] Icons; HUD buffs (frenzy, shout, wall).

### Task 6: Tests, perf, docs
- [ ] `tools/shoptest.gd`, `tools/talenttest.gd`; re-run `skilltest`, `questtest`, `interiortest`, `perftest`.
- [ ] Update `CLAUDE.md`, `HANDOVER.md`, `README.md`.
