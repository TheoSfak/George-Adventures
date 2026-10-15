class_name CombatExtras
## The two combat extras after the sword combo (combat_timing.gd): the dodge roll and the shield bash.
## Pure data and arithmetic, no scene access. See docs/superpowers/specs/2026-10-15-dodge-bash-design.md.

# --- the dodge roll (key V, gamepad right shoulder; rebindable)
const DODGE_DISTANCE := 4.2        # metres in all, counting the slide while he slows down again
const DODGE_MOVE_TIME := 0.30      # seconds he is pushed at full speed
const DODGE_ANIM_TIME := 0.40      # the Dodge_* animations last 0.4 s
const DODGE_INVULN := 0.38         # nothing can hurt him for this long
const DODGE_COOLDOWN := 1.4        # seconds until he can roll again

# --- the shield bash (attack while blocking)
const BASH_ANIM := "Block_Attack"
const BASH_HIT := 0.30             # animation seconds until the shield lands (divided by the swing speed)
const BASH_COMMIT := 0.62          # animation seconds until he is free again
const BASH_REACH := 2.5            # metres in front of him
const BASH_ARC := 0.3              # min dot(facing, direction to the enemy): a 145 degree cone
const BASH_DAMAGE := 0.5           # share of the sword damage
const BASH_KNOCK := 9.0
const BASH_STUN := 1.4             # seconds an ordinary enemy cannot act
const BASH_STUN_BOSS := 0.5        # named bosses are stunned for much less
const BASH_COOLDOWN := 2.5


## The push speed that carries him `DODGE_DISTANCE` metres in all: he is pushed for DODGE_MOVE_TIME at this
## speed and then slows down with `acceleration` (the same rate that stops him when he lets go of the keys).
static func dodge_speed(acceleration: float) -> float:
	var t := DODGE_MOVE_TIME
	return acceleration * (sqrt(t * t + 2.0 * DODGE_DISTANCE / acceleration) - t)


## The Knight animation for a roll in the direction `local_dir` (x = to his right, y = forward).
static func dodge_anim(local_dir: Vector2) -> String:
	if absf(local_dir.y) >= absf(local_dir.x):
		return "Dodge_Forward" if local_dir.y > 0.0 else "Dodge_Backward"
	return "Dodge_Right" if local_dir.x > 0.0 else "Dodge_Left"


## How long a bash stuns: bosses (they have a name over their head) much less.
static func bash_stun(is_boss: bool) -> float:
	return BASH_STUN_BOSS if is_boss else BASH_STUN
