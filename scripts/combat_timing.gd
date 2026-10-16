class_name CombatTiming
## The sword combo of George (see docs/superpowers/specs/2026-10-14-levels-combat-design.md): one entry per
## hit with the animation, when the blow lands, when George may move or attack again, and how it hits.
## All times are in ANIMATION seconds; divide them by the swing speed to get real seconds.
## Pure data and arithmetic, no scene access.

const BASE_SPEED := 1.7            # the swing animations play at 1.7x
const COMBO_WINDOW := 1.0          # real seconds after a swing in which the next hit continues the combo

# anim:   the Knight animation
# hit:    animation seconds until the blade connects
# commit: animation seconds until George may move or attack again (the rest of the animation is cut off)
# damage: multiplier of the sword damage
# lunge:  metres George steps forward while the blow lands
# knock:  knockback of the enemies hit
# around: hits every enemy around him instead of a cone in front of him
const COMBO: Array[Dictionary] = [
	{"anim": "1H_Melee_Attack_Slice_Diagonal", "hit": 0.28, "commit": 0.55, "damage": 1.0, "lunge": 0.0, "knock": 5.0, "around": false, "sfx": "sword_swing"},
	{"anim": "1H_Melee_Attack_Slice_Horizontal", "hit": 0.30, "commit": 0.58, "damage": 1.0, "lunge": 0.0, "knock": 5.0, "around": false, "sfx": "sword_swing"},
	{"anim": "1H_Melee_Attack_Stab", "hit": 0.45, "commit": 0.90, "damage": 1.25, "lunge": 1.2, "knock": 6.5, "around": false, "sfx": "sword_swing"},
	{"anim": "1H_Melee_Attack_Chop", "hit": 0.34, "commit": 0.62, "damage": 1.4, "lunge": 0.0, "knock": 6.0, "around": false, "sfx": "sword_swing"},
	{"anim": "2H_Melee_Attack_Spinning", "hit": 0.25, "commit": 0.50, "damage": 1.8, "lunge": 0.0, "knock": 8.0, "around": true, "sfx": "sword_swing"},
]

const COMBO_2H: Array[Dictionary] = [
	{"anim": "2H_Melee_Attack_Slice", "hit": 0.34, "commit": 0.62, "damage": 1.35, "lunge": 0.2, "knock": 7.5, "around": false, "sfx": "swing_2h"},
	{"anim": "2H_Melee_Attack_Chop", "hit": 0.38, "commit": 0.68, "damage": 1.55, "lunge": 0.3, "knock": 8.5, "around": false, "sfx": "swing_2h"},
	{"anim": "2H_Melee_Attack_Spin", "hit": 0.30, "commit": 0.56, "damage": 1.75, "lunge": 0.0, "knock": 9.5, "around": true, "sfx": "swing_2h"},
	{"anim": "2H_Melee_Attack_Spinning", "hit": 0.26, "commit": 0.52, "damage": 2.20, "lunge": 0.0, "knock": 12.0, "around": true, "sfx": "swing_2h"},
]

const COMBO_DUAL: Array[Dictionary] = [
	{"anim": "Dualwield_Melee_Attack_Slice", "hit": 0.18, "commit": 0.35, "damage": 0.85, "lunge": 0.0, "knock": 4.0, "around": false, "sfx": "swing_dual"},
	{"anim": "Dualwield_Melee_Attack_Chop", "hit": 0.20, "commit": 0.38, "damage": 0.95, "lunge": 0.2, "knock": 4.5, "around": false, "sfx": "swing_dual"},
	{"anim": "Dualwield_Melee_Attack_Stab", "hit": 0.22, "commit": 0.40, "damage": 1.15, "lunge": 0.5, "knock": 5.0, "around": false, "sfx": "swing_dual"},
	{"anim": "Dualwield_Melee_Attack_Slice", "hit": 0.18, "commit": 0.35, "damage": 1.10, "lunge": 0.0, "knock": 5.5, "around": false, "sfx": "swing_dual"},
	{"anim": "2H_Melee_Attack_Spinning", "hit": 0.22, "commit": 0.45, "damage": 1.60, "lunge": 0.0, "knock": 7.0, "around": true, "sfx": "swing_dual"},
]

# Δυνατό Χτύπημα: a heavy chop (its damage comes from the skill)
const POWER_STRIKE := {"anim": "1H_Melee_Attack_Chop", "hit": 0.36, "commit": 0.70, "damage": 1.0, "lunge": 0.0, "knock": 11.0, "around": false, "sfx": "sword_swing"}

const SWING_MOVE_FACTOR := 1.0     # George keeps 100% of his speed while he swings
const LUNGE_TIME := 0.15           # real seconds the stab's step lasts


static func combo_for(weapon_type: String) -> Array[Dictionary]:
	match weapon_type:
		"2h": return COMBO_2H
		"dual": return COMBO_DUAL
		_: return COMBO


## Animation names used by the swings (the upper-body layer copies these).
static func animations() -> Array[String]:
	var out: Array[String] = []
	for list in [COMBO, COMBO_2H, COMBO_DUAL]:
		for step in list:
			if not out.has(step["anim"]):
				out.append(step["anim"])
	if not out.has(POWER_STRIKE["anim"]):
		out.append(POWER_STRIKE["anim"])
	return out


## Swing speed with George's attack-speed stat (0.1 = +10%).
static func speed(attack_speed_stat: float) -> float:
	return BASE_SPEED * (1.0 + maxf(attack_speed_stat, -0.5))


static func hit_delay(step: Dictionary, swing_speed: float) -> float:
	return float(step["hit"]) / swing_speed


static func commit_delay(step: Dictionary, swing_speed: float) -> float:
	return float(step["commit"]) / swing_speed


## The step of the combo after `index` for a given weapon type.
static func next_index(index: int, weapon_type: String = "1h") -> int:
	var c := combo_for(weapon_type)
	return (index + 1) % c.size()
