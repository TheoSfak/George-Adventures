class_name MountRules
extends RefCounted
## The rules of the horse. Pure functions, no scene access, so tests can use them directly.

const SPEED_FACTOR := 1.8        # riding speed relative to walking or running on foot
const PRICE := 350               # gold at the stable
const MIN_LEVEL := 5
const CHASE_RANGE := 30.0        # a skeleton this close and chasing stops George from mounting
const CHASE := 2                 # Enemy.State.CHASE
const ATTACK := 3                # Enemy.State.ATTACK


static func can_buy(level: int, gold: int, owned: bool) -> bool:
	return not owned and level >= MIN_LEVEL and gold >= PRICE


## Why George cannot mount right now: "" means he can. The order is the order of importance.
static func block_reason(owned: bool, indoors: bool, busy: bool, dead: bool, stunned: bool, chased_now: bool) -> String:
	if not owned:
		return "not_owned"
	if dead:
		return "dead"
	if indoors:
		return "indoors"
	if busy:
		return "busy"
	if stunned:
		return "stunned"
	if chased_now:
		return "chased"
	return ""


## `states` are the `_state` values of the enemies (Enemy.State), `distances` how far each is from George.
static func chased(states: Array, distances: Array) -> bool:
	for i in states.size():
		if (states[i] == CHASE or states[i] == ATTACK) and float(distances[i]) <= CHASE_RANGE:
			return true
	return false
