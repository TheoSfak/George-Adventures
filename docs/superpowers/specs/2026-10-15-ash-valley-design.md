# Story part 4: the Ash Valley (a first slice for levels 20 to 40) — design

Date: 2026-10-15. Status: **implemented and released in 1.7.0** (see "As built" at the end); approved by Theodore in chat (queue "3, then 5, then 4"; answers: **Part 4: a new region + story**, theme **Burning valley**, scope **a solid first slice**). No plan file (he works with spec only, then straight to implementation).

## Goal
Real content for levels 21 to 40 (today those levels only make the old world tougher): a third outdoor region like the Frontier, with a camp, creatures, four quests and a boss, all scaled by `LevelScaling` on top of base stats tuned for a strong level-20 hero.

## Story
After Malakar's fall Παπά-Σταύρος knows the knowledge came from the Ash Valley, where the Keeper of the Flame (**Πυρφόρος**) woke and sets the old fire cult's dead alight. A refugee, the pyromancer monk **Θεόφιλος**, and the smith **Δαμιανός** hold a camp at the mouth of the valley. George must find the three Shards of the Flame, break the Keeper's temple seal and put the fire out.

## Region framework (`Interiors`, `SaveGame`, `SoundManager`)
- Regions become a registry: `Interiors.REGIONS = {"frontier": Frontier, "ashvalley": AshValley}`, one node per built region (`_regions`), `current_kind` = the region id while George is in it, `enter_region(id, ...)` builds the right class on first use (classes share `ORIGIN`, `build()`, `spawn_point()`, `exit_action`). `in_region()` stays the generic test (minimap hidden, no weather, no invasion, no rescue event).
- `SaveGame` stores `player.region` (`"frontier"`, `"ashvalley"` or `""`) and still reads the old `in_frontier`.
- `SoundManager`: music `crypt` (dark) and the new ambience loop `amb_ash` (low wind + embers crackling) in the Ash Valley; the Frontier keeps `mountain` / `amb_mountain`.

## The region (`ash_valley.gd`, class `AshValley`, `ORIGIN` (6000, 0, -6000), local metres, x east, z south)
- Entry: a stone arch "Πύλη της Στάχτης" in the south-east mountains of the village (`AshValley.VILLAGE_GATE`, open ground found with a probe), sealed until quest `a_gate` is ACTIVE and shut during a night invasion (like the pass gate). `Village._build_ash_gate`.
- `BOUNDS` about 180 x 340 m, entry and the arch back to the village at the south end, ring of mountains (as in the Frontier), ground = the village ground shader with ash-grey and ember-orange colours, scorched paths, dead trees and boulders, glowing lava cracks and a lava stream (emissive meshes, orange `OmniLight3D`s, a stone bridge), no snow.
- Zones: the **ash road** (south, ember skeletons), the **Καταφύγιο** camp (Θεόφιλος and Δαμιανός, a fire, tents, safe: no spawns within `CAMP_RADIUS`), the **valley** (lava stream, shards, ash casters, three dormant magma golems), the **Temple of the Flame** (north): a ruined temple with braziers, a sealed gate (red barrier, dissolves when quest `a_shards` is READY or DONE) and the boss.
- NavGrid region `ashvalley`; four chests; creatures spawned with `Enemies.spawn_extra`; the boss comes back 60 s after he dies and at once while his quest needs him (like Malakar).

## Creatures (`Enemies.KINDS`, base stats for about level 20; `LevelScaling` adds the rest)
- `ember_skeleton` Φλογοσκελετός: Skeleton_Warrior, orange tint, 300 hp, 34 damage, quick.
- `ash_caster` Στάχτινος Μάγος: Skeleton_Mage, orange tint, fire orbs (`projectile_kind` "fire", a new orange projectile), 160 hp, 30 damage.
- `magma_golem` Γίγαντας του Μάγματος: a dormant rock creature (`StaticRig` parts with glowing eyes), 900 hp, 52 damage, stomp slows.
- boss `pyrforos` ο Πυρφόρος, Φύλακας της Φλόγας: Skeleton_Warrior x2.8, fiery tint, 6000 hp, 55 damage, enrages below 50% (faster, calls ember skeletons), `quest: "a_boss"`, `respawn_after` 60 s, listed in `BOSSES` and `SoundManager` boss kinds.
- `QuestData.is_skeleton` keeps counting them for "skeleton" targets (they are skeletons); quest targets by kind.

## Quests (`quest_data.gd`, all Greek, voiced)
1. `a_gate` «Η Πύλη της Στάχτης» (giver Παπά-Σταύρος after `f_return`, hand-in Θεόφιλος): reach `ashvalley`. Reward 1,200 XP, 300 gold, 2 potions.
2. `a_embers` «Τα Αναμμένα Κόκαλα» (Θεόφιλος, after `a_gate`): 8 `ember_skeleton` and 4 `ash_caster`. 2,500 XP, 500 gold, 3 potions, +4 damage.
3. `a_shards` «Τα Θραύσματα της Φλόγας» (Δαμιανός, after `a_gate`): collect 3 `shard` (quest item, a candle-skull with the golden beam). 2,500 XP, 500 gold, 2 power potions. When ready the temple gate opens.
4. `a_boss` «Ο Πυρφόρος» (Θεόφιλος, after `a_embers` and `a_shards`, hand-in Θεόφιλος): kill `pyrforos`. 6,000 XP, 1,500 gold, 4 potions, +8 damage, `ends_game` (the "Συνεχίζεται…" banner).

## Presentation
Strings in `strings_el.gd` (gate prompts and messages, building name, temple gate), NPCs `theofilos` (Mage, voice `man_slow`) and `damianos` (Barbarian, `man`) with idle lines in `quest_data.gd`, voice lines generated with `tools/dump_voice_lines.gd` and `tools/gen_voice.py`, sounds reuse existing recipes plus `amb_ash`, minimap hidden as in every region.

## Tests
`ash_data_test` (kinds, spawns, quests chain and rewards, strings, shard item), `ash_build_test` (builds the region, creatures, chests, NPCs, gate, nav grid, enter and leave through `Interiors`, save and load inside it, the old `in_frontier` save), `ash_quest_test` (plays the four quests with the reports), `ashshot` (screenshots + fps), `voice_files_test` (every new line has a recording), regression: `frontier_enter_test`, `frontier_build_test`, `part3_hooks_test`, `part3_data_test`, `savetest`, `save_gaps_test`.

## Not in this slice
More quests and NPCs, shop, gear from the valley, a second boss, music of its own, region-specific sky and fog, ash particles.

## Guesses
All numbers (stats, rewards, distances), the layout, the look of the lava and the colours.

## As built (2026-10-15)
- The region registry is `Interiors.REGION_IDS` + `_regions` + `_new_region(id)` + the static `region_gate(id)` (not a `REGIONS` dictionary of classes: the classes are referenced in two small `match` blocks); `current_kind` is the region id; `SaveGame` writes `player.region` and still reads `in_frontier`.
- The gate stands at `AshValley.VILLAGE_GATE` (178, 64), 189 m from the well, found with `tools/gate_site_probe.gd`; the arch faces the well (`Village._build_ash_gate`).
- Layout: `BOUNDS` 180 x 350 m (z from -210 to 140), camp at (0, 30), lava river along z = -60 with a 6 m wave and one bridge at x = 0, temple walls from z = -200 to -130 with the gate at z = -130. 32 spawns (19 ember skeletons, 8 ash casters, 3 magma golems, the boss), 4 chests, 3 shards.
- Lava is a spatial shader (`shaders/lava.gdshader`: two layers of drifting noise, `world_offset` like the ground shaders), the river has invisible wall colliders so nobody walks into it (only the bridge is open), the nav grid knows both.
- Sound: ambience loop `amb_ash` (new recipe) instead of the planned reuse; music `crypt`; footsteps `footstep_stone`.
- Measured: about 28 lights in the region, 60 fps everywhere by day and night except 49 fps at the Flame during a night fight before two braziers lost their light; measured again after that change: 60 fps at every spot, day and night.
- Not done (as planned): everything under "Not in this slice". Also: by day the sky and fog are the village's, so the valley only looks "burning" thanks to the lava, the lights and the night.
