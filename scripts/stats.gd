class_name Stats
extends RefCounted
## Stat modifiers on George. Every source (equipment, talents) registers a dictionary of
## modifiers; total() adds them up. Player._recalc() turns the totals into max_health and
## sword_damage, the other stats are read at the point of use.
##
## Keys:
##   damage_add   flat sword damage            damage_mult  +share of damage (0.1 = +10%)
##   hp_add       flat max health              defense      share of damage ignored (capped at 80%)
##   block_add    extra share absorbed by a block
##   speed_mult   +share of move speed         crit         chance of a double-damage hit
##   cdr          skill cooldown reduction     lifesteal    share of damage dealt returned as health
##   heal_mult    +share of all healing        regen        health per second
##   guard_time_add  extra seconds of the Ασπίδα του Αγίου
##   prayer_add   extra share of max health healed by the Ευχή
##   ps_mult      +share of Δυνατό Χτύπημα damage    whirl_radius  extra metres of the Σίφουνας
##   last_stand   extra damage reduction below 30% health          rebirth  1 = Ανάσταση learned
##   attack_speed +share of sword swing speed (0.1 = +10%)

const NAMES := {
	"damage_add": "Ζημιά", "damage_mult": "Ζημιά", "hp_add": "Ζωή", "defense": "Άμυνα",
	"block_add": "Μπλοκ", "speed_mult": "Ταχύτητα", "crit": "Κρίσιμο χτύπημα", "cdr": "Ταχύτερη επαναφορά",
	"lifesteal": "Ρουφά ζωή", "heal_mult": "Θεραπεία", "regen": "Ζωή/δ", "guard_time_add": "Διάρκεια Ασπίδας",
	"prayer_add": "Ευχή του Αγίου", "ps_mult": "Δυνατό Χτύπημα", "whirl_radius": "Εύρος Σίφουνα",
	"last_stand": "Άμυνα με χαμηλή ζωή", "rebirth": "Ανάσταση", "attack_speed": "Ταχύτητα επίθεσης",
}
## Keys shown as a percentage (value 0.1 -> "+10%").
const PERCENT := ["damage_mult", "defense", "block_add", "speed_mult", "crit", "cdr", "lifesteal",
	"heal_mult", "prayer_add", "ps_mult", "last_stand", "attack_speed"]
const CAPS := {"defense": 0.8, "cdr": 0.5, "crit": 0.75, "lifesteal": 0.4}

var _sources := {}


func set_source(source: String, mods: Dictionary) -> void:
	_sources[source] = mods


func total(key: String) -> float:
	var sum := 0.0
	for s in _sources:
		sum += float(_sources[s].get(key, 0.0))
	if CAPS.has(key):
		sum = minf(sum, CAPS[key])
	return sum


## One modifier as Greek text, e.g. "+9 Ζημιά" or "+10% Άμυνα".
static func line(key: String, value: float) -> String:
	var sign_text := "+" if value >= 0.0 else "-"
	var v := absf(value)
	if key == "rebirth":
		return NAMES[key]
	if key == "whirl_radius":
		return "%s%.1f μ %s" % [sign_text, v, NAMES[key]]
	if key == "guard_time_add":
		return "%s%.1f δ %s" % [sign_text, v, NAMES[key]]
	if key == "regen":
		return "%s%.1f %s" % [sign_text, v, NAMES[key]]
	if PERCENT.has(key):
		return "%s%d%% %s" % [sign_text, roundi(v * 100.0), NAMES[key]]
	return "%s%d %s" % [sign_text, roundi(v), NAMES[key]]


## All modifiers of a dictionary, joined: "+9 Ζημιά, +10% Άμυνα".
static func describe(mods: Dictionary) -> String:
	var parts: Array[String] = []
	for key in NAMES:
		if mods.has(key):
			parts.append(line(key, mods[key]))
	return ", ".join(parts)


## Adds b into a (both {key: value}).
static func merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for key in b:
		out[key] = float(out.get(key, 0.0)) + float(b[key])
	return out
