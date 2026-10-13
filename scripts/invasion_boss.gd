class_name InvasionBoss
extends RefCounted
## The rules of the invasion boss nights. On night 5 and every 5th night after it a fourth
## wave brings the Night Lord ("night_lord" in enemies.gd KINDS), stronger each time.
## Pure functions, no scene access, so tests can use them directly.

const KIND := "night_lord"
const EVERY := 5                 # a boss comes on nights 5, 10, 15 ...
const GROWTH := 0.4              # extra health and damage per tier after the first
const SUMMON_CAP := 8


static func is_boss_night(night: int) -> bool:
	return night > 0 and night % EVERY == 0


## 1 for night 5, 2 for night 10 ... (0 on nights without a boss).
static func tier_of(night: int) -> int:
	return night / EVERY


## The invasion has one more wave than usual on a boss night.
static func total_waves(night: int, base: int) -> int:
	return base + 1 if is_boss_night(night) else base


static func factor(tier: int) -> float:
	return 1.0 + GROWTH * float(maxi(tier, 1) - 1)


static func summon_cap(base: int, tier: int) -> int:
	return mini(base + maxi(tier, 1) - 1, SUMMON_CAP)


static func escort_size(tier: int) -> int:
	return 4 + 2 * maxi(tier, 1)


static func bonus_xp(tier: int) -> int:
	return 200 * tier


static func roman(n: int) -> String:
	var values: Array[int] = [10, 9, 5, 4, 1]
	var symbols: Array[String] = ["X", "IX", "V", "IV", "I"]
	var out := ""
	var left := n
	for i in values.size():
		while left >= values[i]:
			out += symbols[i]
			left -= values[i]
	return out


## "Άρχοντας της Νύχτας", then "... II", "... III" for the later tiers.
static func title(base_name: String, tier: int) -> String:
	return base_name if tier <= 1 else "%s %s" % [base_name, roman(tier)]


## Stats to put on the boss of this tier. `base` is its entry in Enemies.KINDS.
static func overrides(tier: int, base: Dictionary) -> Dictionary:
	var f := factor(tier)
	return {
		"max_health": float(base["max_health"]) * f,
		"attack_damage": float(base["attack_damage"]) * f,
		"summon_max": summon_cap(int(base["summon_max"]), tier),
		"display_name": title(String(base["display_name"]), tier),
	}
