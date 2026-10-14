class_name RescueRules
## Pure rules of the "Σώσε τον Αντρέα" event (no scene access): when the alert fires, how fast
## Andreas loses health, and which skeletons surround him.

enum State { WAITING, ALERT, ACTIVE, SAVED, FAILED }

const MIN_DELAY := 180.0      # play time before the alert, seconds
const MAX_DELAY := 300.0
const FULL_TIME := 150.0      # seconds until Andreas dies with all besiegers alive
const BESIEGERS := 6


static func pick_limit(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(MIN_DELAY, MAX_DELAY)


## True when the clock of the event may run: George is outdoors in the village and in control.
static func is_free(ctx: Dictionary) -> bool:
	return not (ctx.get("busy", false) or ctx.get("indoors", false) or ctx.get("region", false) or ctx.get("dead", false))


static func should_fire(elapsed: float, limit: float, ctx: Dictionary) -> bool:
	return elapsed >= limit and is_free(ctx) and not ctx.get("invasion", false)


## Andreas' health (0..1) after `delta` seconds with `besieging` skeletons hitting him.
static func drain(health: float, besieging: int, delta: float) -> float:
	var rate := float(besieging) / float(BESIEGERS) / FULL_TIME
	return maxf(health - rate * delta, 0.0)


static func kinds_for(level: int) -> Array[String]:
	var kinds: Array[String] = ["warrior", "warrior"]
	if level >= 10:
		kinds.append_array(["minion", "minion", "rogue", "brute"])
	elif level >= 5:
		kinds.append_array(["minion", "minion", "minion", "rogue"])
	else:
		kinds.append_array(["minion", "minion", "minion", "minion"])
	return kinds
