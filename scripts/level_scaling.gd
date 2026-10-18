class_name LevelScaling
## How the world grows with George above level 20 (see docs/superpowers/specs/2026-10-14-levels-combat-design.md).
## Everything is unchanged up to level 20; above it every enemy gets stronger with George's level.
## Pure rules, no scene access. The multipliers are read live from George's current level, so a loaded
## save, a respawn, a summon or an invasion all scale the same way.

const MAX_LEVEL := 40
const SCALE_FROM := 20             # the level the old game stopped at

const HEALTH_PER_LEVEL := 0.22     # +22% enemy health per level above 20 (about x5.4 at level 40)
const DAMAGE_PER_LEVEL := 0.16     # +16% enemy damage per level above 20 (about x4.2)
const XP_PER_LEVEL := 0.15         # +15% XP per level above 20 (about x4)
const GOLD_PER_LEVEL := 0.15

const XP_BASE := 40                # xp to go from level L to L + 1: BASE + STEP * (L - 1) up to level 20
const XP_STEP := 35
const XP_STEP_ABOVE := 80          # above level 20 each level asks 80 XP more than the one before


static func over(level: int) -> int:
	return maxi(level - SCALE_FROM, 0)


static func health_mult(level: int) -> float:
	return 1.0 + HEALTH_PER_LEVEL * over(level)


static func damage_mult(level: int) -> float:
	return 1.0 + DAMAGE_PER_LEVEL * over(level)


static func xp_mult(level: int) -> float:
	return 1.0 + XP_PER_LEVEL * over(level)


static func gold_mult(level: int) -> float:
	return 1.0 + GOLD_PER_LEVEL * over(level)


## XP needed to go from `level` to `level + 1`.
static func xp_needed(level: int) -> int:
	if level <= SCALE_FROM:
		return XP_BASE + XP_STEP * (level - 1)
	return XP_BASE + XP_STEP * (SCALE_FROM - 1) + XP_STEP_ABOVE * (level - SCALE_FROM)


## Total XP from level `from_level` up to `to_level`.
static func xp_total(from_level: int, to_level: int) -> int:
	var sum := 0
	for l in range(from_level, to_level):
		sum += xp_needed(l)
	return sum
