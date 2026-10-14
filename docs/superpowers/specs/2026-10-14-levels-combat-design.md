# Levels 21-40 and a faster, richer combat system — design

Date: 2026-10-14. Status: approved by Theodore in chat ("write spec then move on with implement not plan"). Choices made: scaling world + new gear; upper-body animation layer; longer combo and an attack-speed stat (no dodge roll, no shield bash this round).

## Part 1: levels 21 to 40

### `LevelScaling` (`scripts/level_scaling.gd`, pure, no scene access)
Everything is unchanged up to level 20. `over(level) = max(0, level - 20)`.
- `health_mult(level) = 1 + 0.22 * over` (about 5.4 at level 40)
- `damage_mult(level) = 1 + 0.12 * over` (about 3.4)
- `xp_mult(level) = 1 + 0.15 * over` (about 4.0)
- `gold_mult(level) = 1 + 0.15 * over`
- `xp_needed(level)` (XP to go from `level` to `level + 1`): `40 + 35 * (level - 1)` up to level 20 (705 at level 20), then `705 + 80 * (level - 20)` (2225 at level 39); about 29,000 XP for levels 20 to 40 in total.
- `MAX_LEVEL = 40`.

### Applied live to enemies (`Enemy`, `Enemies`, `Guard`)
The multipliers use George's current level, read when they are needed, so a loaded save, respawns, summons, bosses, bandits, the cult and invasions all scale the same way.
- `Enemy.take_damage` divides the incoming amount by `health_mult(player level)` (health and health bar are untouched).
- Every enemy attack reads `attack_damage * damage_mult(...)` (melee blow, arrow, orb, projectile kinds, prop-creature lunges).
- `Enemies._on_enemy_died` / `_on_extra_died` give `xp_reward * xp_mult`; `_drop_loot` gives `gold * gold_mult`.
- `Guard` multiplies the damage it deals to enemies by `health_mult` so guards stay as useful as before.
- Totems (`breakables`), quest rewards and chests stay fixed.

### Progression
- `Player.max_level = 40`; `xp_needed` calls `LevelScaling.xp_needed`. Health +10 and damage +2 per level stay.
- **Gear tiers 5 to 9** (levels 20, 25, 30, 35, 40) for weapon, armor and shield, in `ShopData.GEAR` (ids `weapon_5`..`weapon_9`, `armor_5`.., `shield_5`..), names «της Αυγής», «της Καταιγίδας», «του Ήλιου», «του Ουρανού», «των Αρχαγγέλων». About +35% per tier over tier 4 (weapon damage 36, 48, 62, 80, 100; armor hp and defense up; shield block and defense up); prices 3500, 7000, 14000, 26000, 45000 gold; the blacksmith stock lists them. Tiers 5-9 draw like tier 4 (same model) with a different glow colour (`TIER_COLORS` grows). Weapons from tier 2 add `attack_speed` (+0.03 per tier).
- `Player` caps total `defense` at 0.8.
- **Talents:** every stat talent (no `"skill"` key) gets +2 `max` ranks. No window layout change. The warrior talents `w_dmg` and `w_ps` also give `attack_speed`.
- **Potions:** a health potion heals `max(potion_heal, 25% of max health)`, the big one `max(its heal, 50%)`.
- Old saves load unchanged (a level-20 save simply continues).

## Part 2: combat

### `CombatTiming` (`scripts/combat_timing.gd`, pure)
`COMBO` is a table of five hits, each with `anim`, `hit` (animation seconds at which the blow lands), `commit` (animation seconds after which George may move or attack again), `damage` (multiplier), `lunge` (metres stepped forward), `knock`, `around` (hits all around). All animation times are divided by the swing speed.
1. `1H_Melee_Attack_Slice_Diagonal` (hit 0.28, commit 0.55, x1.0)
2. `1H_Melee_Attack_Slice_Horizontal` (0.30, 0.58, x1.0)
3. `1H_Melee_Attack_Stab` (0.45, 0.90, x1.25, lunge 1.2)
4. `1H_Melee_Attack_Chop` (0.34, 0.62, x1.4)
5. `2H_Melee_Attack_Spinning` (0.25, 0.50, x1.8, around, knock 8)
`BASE_SPEED = 1.7`; `speed(attack_speed_stat) = BASE_SPEED * (1 + stat)`; `COMBO_WINDOW = 1.0` s. Power Strike uses the chop entry with its own damage.

### `Player`
- A swing plays at `CombatTiming.speed(...)` (`AnimationPlayer.play(name, blend, speed)`), the hit lands at `hit / speed`, `_attacking` ends at `commit / speed` by a timer (not by `animation_finished`, which stays as a safety net).
- While `_attacking` George moves at `SWING_MOVE_FACTOR` = 0.85 of his speed (instead of 0). The stab adds a forward step of `lunge` metres.
- `_assist_aim` only turns toward an enemy within about 60 degrees of the heading while George is moving.
- The finisher hits every enemy within `sword_reach` all around.
- **Upper-body layer** (`scripts/upper_body_layer.gd`, class `UpperBodyLayer`): builds a second `AnimationPlayer` under the model with copies of the attack animations whose tracks of the hips, legs, feet and toes are removed (`UpperBodyLayer.is_lower_body(path)`), plays them while `_attacking` and George is moving (horizontal speed above 1.0 at the start of the swing), and stops them at the end. The base `AnimationPlayer` keeps playing the locomotion. When standing still the full-body animation plays as before.
- **`attack_speed`** is a new `Stats` key (fraction). Sources: weapons, the warrior talents; it shows in the hero window (Greek label «Ταχύτητα επίθεσης»).

## Tests
- Headless: `level_scaling_test`, `level_cap_test` (levelling 20 to 40, xp curve, gear levels, potions, defense cap, talent ranks), `enemy_scaling_test` (damage, health, rewards at levels 1, 20, 40 on real enemies), `combat_timing_test`, `combat_move_test` (George keeps moving while attacking, the hit lands, the finisher hits around him, the upper layer has no leg tracks and the base keeps running).
- `combatshot` (screenshots, fps): a mid-swing run, each of the five hits.
- Regression: `savetest`, `shield_test`, `boss_respawn_test`, `rescue_flow_test`, `bandit_*`, `mount_ride_test`, `invasion_boss_flow_test`, `part3_mobs_test`, `gender_test`, `mob_kinds_test`, `enemy_nav_test`.

## Known guesses
All numbers (multipliers, xp, prices, gear stats, hit and commit times) are first guesses to tune by playing. The hit times of the stab and the finisher are judged on screenshots only. The upper-body layer may need tuning after Theodore sees it.
