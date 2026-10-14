# Bandits — design

Date: 2026-10-14. Status: approved by Theodore in chat ("nai proxora").

## Goal
Most mobs are skeletons. Add a human enemy faction, the bandits, built from the Adventurers models that are already in the project (no new assets): a hideout in the forest with a boss, patrols on the roads and a quest.

## Kinds (`Enemies.KINDS`, `"human": true`)
All human models are tinted and/or scaled so they cannot be mistaken for NPCs. Numbers are first guesses to be tuned by playing.
- `bandit_thug` "Ληστής": Barbarian, 1H axe + round shield, 60 hp, 14 damage, melee.
- `bandit_archer` "Ληστής Τοξότης": Rogue, 1H crossbow, 40 hp, arrows (existing `ranged`/`projectile_kind: "arrow"`).
- `bandit_thief` "Κλέφτης": Rogue_Hooded, knife, 35 hp, fast, quick attacks (short cooldown, low damage).
- `bandit_chief` "Αρχηγός των Ληστών" (boss): Barbarian, 2H axe, scale 1.7, dark tint, about 450 hp, `display_name`, calls two thugs below half health (`enrage_below` 0.5, `enrage_summon` `bandit_thug`, `summon_max`), `respawn_after` 60 s like every boss, always drops a potion and gold (`BOSSES`).
- Ordinary bandits respawn like skeletons (45 s). Bandits do not take part in night invasions.

## Shared character props (`character_props.gd`, class `CharacterProps`, no scene access besides the model it is given)
The list of weapon and accessory nodes that the KayKit Adventurers models ship with (now `Npc.WEAPON_NODES`) moves here: `CharacterProps.NODES` and `static func apply(model: Node3D, show: Array)` (hides every listed node that is not in `show`). `Npc` and `Enemy` both call it. `Enemy` gets `@export var show_nodes: Array[String]` (empty for skeletons: they are not touched) and `@export var walk_anim := "Walking_D_Skeletons"` (humans use "Walking_A"); `LOOPED` gains the human walk/run names that exist.

## Hideout (`bandit_camp.gd`, class `BanditCamp`, added by `Village._ready` like the stable)
- Site: `BanditCamp.CENTER` (-140, -90), found open (14 m free disc, 49 m from the nearest skeleton spawn, 54 m from the nearest zone) by `tools/bandit_site_probe.gd`; `Village._occupy(CENTER, 36)` keeps the scatter off it.
- Built from existing props (tents, crates, barrels, sacks, flag from the west camp's piece list), a campfire (OmniLight in group `night_lights`, lit after dusk, positional fire loop reused), a golden chest (gold 150 to 250; `SaveGame` remembers it) and a signpost "Κρησφύγετο των Ληστών".
- Creatures (`BanditCamp.SPAWNS` data merged into `Enemies.SPAWNS`): the chief, 3 thugs, 2 archers, 1 thief inside; 3 patrol pairs (thug + archer) at open spots on the roads, chosen with the probe (candidates (140, 10), (-20, 170), (90, 145), (60, -160)).

## Quest `bandits` "Οι Ληστές του Δάσους"
- Giver and hand-in: `stelios` (the miller; the windmill is 50 m from the hideout). `requires: ["sacks"]`.
- Objectives: `{"type": "kill", "target": "bandit", "count": 6}` (any `bandit_*` kind except the chief) then `{"type": "kill", "target": "bandit_chief", "count": 1}`.
- Reward: 450 XP, 220 gold, 2 potions, +3 damage.
- Greek story: the bandits stole the mill's carts and frighten the farmers. All text in `quest_data.gd` and `strings_el.gd`.
- `QuestData.is_skeleton(kind)`: true unless the kind is `totem` or begins with `bandit`; `Quests.report_kill` uses it for the target `"skeleton"`, so bandits never count for the skeleton quests, and counts the target `"bandit"` for every kind that begins with `bandit_` and is not the chief.
- The quest boss respawn rule of 1.2.1 applies to the chief.

## Presentation
- Map: red dots like skeletons; the chief is drawn like a boss; big map place `bandits` "Κρησφύγετο" at the camp; a gold diamond for the quest objective `bandit_chief` while the quest is active (`Minimap.BOSS_AREAS`).
- Sounds: reuse existing ones. A human is hurt/dies with `player_hurt` instead of `skel_hurt`/`skel_death`; no aggro shout except `boss_roar` for the chief. No new audio recipes.

## Out of scope
Bandits stealing gold and fleeing, timed ambushes, dialogue, new sounds.

## Tests
- `bandit_data_test` (headless): kinds exist with human flag, models and weapon nodes exist, animations exist, `show_nodes` names are real nodes, `Npc` still hides its props.
- `bandit_quest_test` (headless): bandits do not count for skeleton quests, count for `bandit` and `bandit_chief`, quest chain and reward.
- `bandit_camp_test` (headless): the camp builds, the creatures spawn on open ground, the chest exists, the chief respawns (reuses the boss rule).
- `banditshot` (screenshots + fps), `tools/mob_asset_probe.gd` and `tools/bandit_site_probe.gd` stay as probes.
- Regression: `gender_test`, `part3_data_test`, `rescue_flow_test`, `boss_respawn_test`, `savetest`, `shield_test`, `totem_test`, `minimaptest`.
