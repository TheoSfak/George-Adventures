# Invasion boss nights — design

Date: 2026-10-13. Backlog item E ("more invasion variety"), option A: a boss on night 5 and every 5th night after it.

## Goal
Every night plays the same way today (3 waves of random skeletons, a Warlord on wave 3 from night 3). Give the nights a goal to look forward to: a named boss, arriving as its own final wave, that gets stronger every time.

## Decisions (made with Theodore)
- Boss on night 5, then every 5th night (10, 15, ...). Other nights stay as they are.
- The boss arrives as a separate final wave (wave 4), after waves 1 to 3.
- The same boss returns, stronger each tier. No different bosses per tier.

## Design

### Boss nights and scaling
- `Invasion.is_boss_night(n)`: `n > 0 and n % 5 == 0`. `Invasion.boss_tier(n)`: `n / 5`.
- New enemy kind `night_lord` in `enemies.gd` KINDS, display name "Άρχοντας της Νύχτας": melee, `Skeleton_Warrior.glb` at scale 2.4, blade and large shield, dark blue-violet tint, `respawn: false`, no `quest` key (it is not a quest boss). Tier 1 values: 900 hp, damage 28, chase speed 4.0, attack range 3.8, attack cooldown 1.9, aggro 26, `summon_kind` "minion", `summon_interval` 12, `summon_max` 4, `enrage_below` 0.5, `enrage_summon` "warrior", xp 500, gold 120 to 160, potion chance 1.0.
- Tier scaling (`Invasion` applies it to the spawned enemy): health and damage times `1 + 0.4 * (tier - 1)`, `summon_max` + (tier - 1), capped at 8. From tier 2 the display name gets a Roman numeral suffix ("Άρχοντας της Νύχτας ΙΙ").
- The summon and enrage logic is the existing one (`Enemy._summon`, `_enrage`); no new combat code except that helpers of an invader are invaders too (below).
- The boss is added to `Enemies.BOSSES` (always drops a buff potion and a charm), the boss kind list of `minimap.gd` (red boss marker) and the boss list of `sound_manager.gd` (boss music within 45 m).

### Flow (`invasion.gd`)
- `waves_this_night()` is `WAVES + 1` on a boss night, else `WAVES`. The `updated` signal and the HUD text use it, so the HUD shows "Κύμα 4/4".
- Waves 1 to 3 are unchanged (including the Warlord on wave 3 from night 3).
- The existing advance rule (30 % of the wave or fewer alive, or 70 s timeout) also starts the boss wave. Banner "Ο Άρχοντας της Νύχτας έρχεται!", `wave_horn`, then `Sfx.play("boss_roar")` at the gate when it spawns.
- Boss wave: the boss from one gate (random, 150 m out) plus an escort of `4 + 2 * tier` skeletons from the normal pool through two other gates. All are invaders marching to the well.
- Helpers called by an invader are invaders as well: `Enemies.spawn_summon` copies `invader` and `march_target` from the summoner. Each tick `Invasion` merges any member of group `invaders` that is not in `_alive` into `_alive`, so the night cannot be won while helpers live. Failure and dawn already dissolve every invader.
- Success on a boss night: the usual rewards plus XP `+ 200 * tier`, one power and one speed potion, the golden chest with double gold, banner "Ο Άρχοντας της Νύχτας έπεσε!" instead of the normal one.

### Out of scope
Saving an invasion in progress (backlog F), different bosses per tier, themed nights (B), new music.

## Strings (Greek, `strings_el.gd`)
`INVASION_BOSS_COMING`, `INVASION_BOSS_WON`, `NIGHT_LORD_NAME`.

## Testing
- Headless `invasion_boss_test`: schedule (nights 0, 4, 5, 6, 10), tiers, stat scaling and name numerals for tiers 1 to 3, `waves_this_night`, the helper-becomes-invader rule, merge of unlisted invaders into `_alive`.
- Windowed `bossnighttest`: forces night 5, plays waves 1 to 4 (killing invaders through the API), checks the boss arrives only after wave 3 is cleared, that it summons helpers, that the night ends only when all are dead, takes screenshots and reads fps.
- Re-run `eventtest` and `guardtest` (normal nights unchanged), `perftest -- night`.
