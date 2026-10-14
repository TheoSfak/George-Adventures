# More mobs: creatures made from props, and the cult — design

Date: 2026-10-14. Step 3 of the 1.5.0 batch (backlog item L of `HANDOVER.md`). Spec only, no plan (Theodore's rule for this batch).

## Problem

Almost every enemy is still a skeleton (the bandits of 1.3.0 added people). The packs hold many more things that can
fight: the Halloween Bits (pumpkins, bones, a ribcage, a skull, dead trees), the hexagon rocks, the dungeon chest. Seven
new creatures, one set piece (a cult) and a quest make the world less uniform without a new system for each.

## The engine step: creatures without a skeleton

`Enemy` learns to be a **static model** (a prop that fights, no `AnimationPlayer`): its body language is made in code.

- `static_mob := true` (also `parts`, below). `_load_model` skips the "no AnimationPlayer" warning; `_play` already does
  nothing without an animation.
- **Motion by code** (`_animate_static`, after `move_and_slide`): `hop_height` / `hop_rate` make a hopping gait while the
  creature moves (a squash and stretch on the way), `sway` rocks a rooted creature, standing still breathes by 2%. An attack
  is a crouch for the first part of `attack_hit_time`, a lunge at the hit and a recovery; `static_attack_time` (default 0.9 s)
  ends it by timer (`_on_animation_finished` does that for animated ones). A hit shakes the model. A creature whose model has
  a node named `*_lid` flaps it while it chases and attacks (the mimic).
- **Death by code:** the model shrinks and tilts in 0.6 s and the body sinks, no animation needed (`_die`, `dissolve`).
- **Composite creatures.** `parts` is a list of `{path, pos, scale, yaw}` placed under the model root when `model_path` is
  empty (rock golem: a boulder with a head and two fists; bone heap: ribcage, skull and bones).
- **Rooted creatures** never move (speeds 0) and just reach with a long `attack_range` (haunted tree).
- **Dormant creatures** (`dormant := true`, `wake_range`): they stand as an ordinary-looking thing (squashed, a pile, a
  boulder) in state `DORMANT` and do nothing until George comes within `wake_range` or hurts them. Then they `_wake`: a sound,
  a message, the model rises over 0.8 s and the state becomes CHASE (golem), or, with `wake_spawn` / `wake_count`, they burst
  into that many creatures of another kind (bone heap -> 3 skeletons) and dissolve without a reward.
- **Sounds.** `sound_set` ("bone" default, "stone", "wood", "squish"): hurt, attack and death sounds per set; five new
  recipes in `tools/audio/sfx.py` (`stone_hit`, `stone_death`, `wood_hit`, `wood_death`, `squish_hit`, `squish_death`,
  `mimic_snap`) generated with `tools/gen_audio.py` (stone and wood reuse `brute_roar` / `boss_roar` for the aggro cry).
- The nav grid and the camera fade need nothing special: they use the capsule and `model_scale` as for any enemy.

## The creatures (`Enemies.KINDS`, Greek names, ordinary ones respawn after 45 s, bosses after 60 s)

| kind | name | what it is | stats (hp / damage / speed) |
|---|---|---|---|
| `pumpkin` | Κολοκυθένιο Τέρας | jack-o-lantern, hops, orange glow (a small light) | 42 / 10 / chase 5.2, hop 0.45 m |
| `haunted_tree` | Στοιχειωμένο Δέντρο | dead tree, rooted, lashes within 5 m, sways | 170 / 15 / reach 5.0, cooldown 2.0 |
| `golem` | Πέτρινος Γίγαντας | boulder that stands up (dormant, wake 6 m), slow, stomp stuns George for 1 s | 260 / 24 / chase 2.6 |
| `bone_heap` | Σωρός Οστών | pile of bones, wakes at 6 m and bursts into 3 skeleton minions | 30 / 0 / dormant only |
| `mimic` | Μίμικ | a chest that was opened: jumps, bites, lid flaps; better loot | 90 / 14 / chase 4.6, hop 0.3 |
| `cultist` | Οπαδός της Σέκτας | hooded human, dark-red tint, magic orbs from range, `slows` | 55 / 11 / ranged 6 to 14 |
| `cult_priest` | Αρχιερέας της Σέκτας | boss: tall mage, calls cultists then skeletons, enrages at half health | 520 / 20 / chase 4.4 |

`pumpkin`, `haunted_tree`, `golem`, `bone_heap` and `cultist` get XP and gold like the other creatures of their strength
(`xp_reward` 24 / 40 / 70 / 10 / 34, gold in step); the priest gives 360 XP, 120 to 200 gold and a potion; the mimic 60 XP and
40 to 90 gold and a buff potion half of the time.

## Where they stand

- **Pumpkin patch**: five pumpkins and two haunted trees at the edge of the graveyard fence (north), a ring of ordinary
  pumpkin props and candles around them.
- **Boulders** (golems, dormant) in the quarry (three), looking like its other rocks.
- **Bone heaps** in the west camp and on the road to the bandits (four).
- **Mimics**: three chests flagged `"mimic": true` in `Village.CHESTS` (a normal wooden chest, same prompt): near the
  crypt, in the east meadow by the Great Tree road and in the quarry. Opening one: the lid pops, a message
  (`Strings.MIMIC_REVEAL`), the chest vanishes and the mimic appears on its spot; a saved game remembers the chest as opened
  (nothing comes out of it again). A mimic killed once is gone.
- **The cult's ritual circle** (`CultSite`, `scripts/cult_site.gd`, built by `Village._build_cult_site`, like the bandit
  camp): a ring of candles and skull posts round a flat ground patch with a shrine as the altar, red banners, bone piles and
  a golden chest; four cultists and the priest on and around the altar. The position is found with a probe on open ground
  in the south-east forest (the one corner without a story area).

## The quest "Η Σέκτα του Σκότους" (`cult`)

Given by Παπά-Σταύρος once the Bone King is dead (`requires: ["king"]`): kill 5 cultists (target `"cultist"`, the priest does
not count) and the priest (`"cult_priest"`). Reward: 500 XP, 250 gold, 2 health potions, +3 damage. New dialogue lines in
`quest_data.gd` (Greek: offer, progress, complete) are voiced like all others (the generator is run again). The big map names
the place (`MAP_PLACES`) and points the quest diamond at it (`BOSS_AREAS`); cultists show as red dots, the priest like a boss.

## Tests

- `mob_kinds_test` (headless): every new kind has a name, a model or parts that load, sane numbers, a known `sound_set`, and
  its sounds exist; `static_mob` kinds have no `AnimationPlayer` in their model; `QuestData` accepts the new targets.
- `static_mob_test` (headless, real physics): each kind is spawned near George and checked: a hopper moves toward him and its
  model rises and falls, the rooted tree does not move but hits at 5 m, the golem sleeps until 6 m, wakes and chases, the
  bone heap bursts into three skeletons and leaves nothing, every kind dies when hit (model shrinks, group `enemies` left,
  `died` emitted once) and the golem's stomp stuns.
- `mimic_test` (headless): the chest looks and prompts like any chest, opening it spawns the mimic and removes the chest,
  the save remembers it as opened, loading a save with that chest opened shows no mimic.
- `cult_camp_test` / `cult_quest_test` (headless): the site is on free ground, the creatures stand inside it, none of them is
  closer than 40 m to the village spawn points, the quest unlocks after `king`, counts cultists and the priest, rewards.
- `voice_files_test` stays green after the generator is run for the new lines.
- `mobshot` (windowed): screenshots of every creature by day and a night shot of the pumpkin patch; fps with all of them
  awake.

## Not included

Dark knights, witches, raiders, thieves that steal gold, ambushes on a timer, farm animals as creatures, new bosses with
their own arena music. The cult has no map of its own and no interior.
