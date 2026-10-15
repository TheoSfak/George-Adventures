class_name SkillData
## George's skills and consumable items (Greek names and descriptions).
## An action-bar entry is a string: a skill id ("power_strike") or "item:<id>" ("item:health").
## "level" is the player level at which a skill unlocks; "cooldown" is in seconds.
## To add a skill: add it here, add its effect to Player.use_skill(), give it an icon in icons.gd.

const SKILLS := {
	"power_strike": {
		"name": "Δυνατό Χτύπημα", "level": 1, "cooldown": 5.0, "icon": "sword", "color": Color(0.96, 0.52, 0.22),
		"desc": "Ένα δυνατό χτύπημα με διπλάσια ζημιά που πετάει τον εχθρό πίσω.",
	},
	"guard": {
		"name": "Ασπίδα του Αγίου", "level": 2, "cooldown": 18.0, "icon": "shield", "color": Color(0.40, 0.66, 1.0),
		"desc": "Η προστασία του Αγίου Βλάση σε κάνει άτρωτο για 5 δευτερόλεπτα: καμία ζημιά και κανένα σπρώξιμο προς τα πίσω.",
	},
	"whirlwind": {
		"name": "Σίφουνας", "level": 3, "cooldown": 9.0, "icon": "whirl", "color": Color(0.78, 0.88, 0.98),
		"desc": "Γυρίζεις με το σπαθί και χτυπάς όλους τους εχθρούς γύρω σου.",
	},
	"prayer": {
		"name": "Ευχή του Αγίου", "level": 4, "cooldown": 25.0, "icon": "cross", "color": Color(0.98, 0.90, 0.42),
		"desc": "Γιατρεύεις το 40% της ζωής σου.",
	},
	"charge": {
		"name": "Εφόρμηση", "level": 5, "cooldown": 12.0, "icon": "arrow", "color": Color(0.92, 0.34, 0.32),
		"desc": "Ορμάς μπροστά, χτυπάς και ζαλίζεις όσους βρεθούν στον δρόμο σου.",
	},
	"thunder_strike": {
		"name": "Κεραυνός των Αρχαίων", "level": 15, "cooldown": 14.0, "icon": "bolt", "color": Color(0.35, 0.85, 1.0),
		"desc": "Ένα καταστροφικό χτύπημα κεραυνού: 2.8x ζημιά και ζαλίζει όλους τους εχθρούς μπροστά σου για 2 δευτερόλεπτα.",
	},
	"battle_cry": {
		"name": "Πολεμική Κραυγή", "level": 25, "cooldown": 30.0, "icon": "shout", "color": Color(1.0, 0.40, 0.20),
		"desc": "Εμψυχώνει τον Γιώργο: αυξάνει τη ζημιά κατά 30% και την ταχύτητα επίθεσης κατά 15% για 12 δευτερόλεπτα.",
	},
	# --- skills learned in the talent tree (see talent_data.gd); "talent" is the node that unlocks them
	"taunt": {
		"name": "Κραυγή Πρόκλησης", "level": 1, "talent": "g_taunt", "cooldown": 22.0, "icon": "shout", "color": Color(0.45, 0.72, 1.0),
		"desc": "Μια τρομακτική κραυγή ζαλίζει τους εχθρούς γύρω σου για 2 δευτερόλεπτα και μειώνει τη ζημιά που δέχεσαι κατά 25% για 6 δευτερόλεπτα.",
	},
	"wall": {
		"name": "Τείχος", "level": 1, "talent": "g_wall", "cooldown": 60.0, "icon": "tower", "color": Color(0.62, 0.82, 1.0),
		"desc": "Γίνεσαι άτρωτος για 3 δευτερόλεπτα.",
	},
	"frenzy": {
		"name": "Αιματηρή Μανία", "level": 1, "talent": "w_frenzy", "cooldown": 40.0, "icon": "claw", "color": Color(0.95, 0.27, 0.27),
		"desc": "Για 8 δευτερόλεπτα: +25% ζημιά, +15% ταχύτητα και ρουφάς το 12% της ζημιάς σου ως ζωή.",
	},
	"leap": {
		"name": "Κεραυνός του Πολέμου", "level": 1, "talent": "w_leap", "cooldown": 20.0, "icon": "bolt", "color": Color(1.0, 0.80, 0.30),
		"desc": "Πηδάς μπροστά και προσγειώνεσαι με δύναμη, χτυπώντας και ζαλίζοντας όλους γύρω σου.",
	},
	"flame": {
		"name": "Θεία Φλόγα", "level": 1, "talent": "s_flame", "cooldown": 15.0, "icon": "flame", "color": Color(1.0, 0.86, 0.40),
		"desc": "Ένα κύμα ιερής φωτιάς χτυπά όλους τους εχθρούς γύρω σου και σε γιατρεύει με το ένα τέταρτο της ζημιάς.",
	},
	"sanctuary": {
		"name": "Ιερός Κύκλος", "level": 1, "talent": "s_sanct", "cooldown": 45.0, "icon": "ring", "color": Color(0.98, 0.92, 0.55),
		"desc": "Για 8 δευτερόλεπτα ένας ιερός κύκλος γιατρεύει όποιον στέκεται μέσα του και μειώνει τη ζημιά που δέχεται κατά 15%.",
	},
}

const ITEMS := {
	"health": {
		"name": "Φίλτρο Υγείας", "icon": "potion", "color": Color(0.92, 0.22, 0.28),
		"desc": "Γιατρεύει 40 ζωή.",
	},
	"health_big": {
		"name": "Μεγάλο Φίλτρο Υγείας", "icon": "potion", "color": Color(0.95, 0.35, 0.60),
		"desc": "Γιατρεύει 100 ζωή.",
	},
	"power": {
		"name": "Φίλτρο Δύναμης", "icon": "potion", "color": Color(1.0, 0.62, 0.16),
		"desc": "Η ζημιά σου αυξάνεται κατά 60% για 25 δευτερόλεπτα.",
	},
	"speed": {
		"name": "Φίλτρο Ταχύτητας", "icon": "potion", "color": Color(0.32, 0.76, 1.0),
		"desc": "Τρέχεις 40% πιο γρήγορα για 20 δευτερόλεπτα.",
	},
}

## The bar when the game starts: 12 slots.
const DEFAULT_BAR: Array[String] = [
	"power_strike", "guard", "whirlwind", "prayer", "charge", "item:health", "item:power", "item:speed",
	"", "", "", "",
]


## True for skills that the talent tree unlocks (they have no level requirement).
static func is_talent_skill(id: String) -> bool:
	return SKILLS.has(id) and SKILLS[id].has("talent")


static func is_item(entry: String) -> bool:
	return entry.begins_with("item:")


static func item_id(entry: String) -> String:
	return entry.substr(5)


## Everything the UI needs to draw and describe an entry.
## {"name", "desc", "icon", "color", "level", "cooldown", "item": bool, "id"}
static func info(entry: String) -> Dictionary:
	if entry == "":
		return {}
	if is_item(entry):
		var d: Dictionary = ITEMS[item_id(entry)].duplicate()
		d["item"] = true
		d["id"] = item_id(entry)
		d["level"] = 1
		d["cooldown"] = 0.6
		return d
	var s: Dictionary = SKILLS[entry].duplicate()
	s["item"] = false
	s["id"] = entry
	return s
