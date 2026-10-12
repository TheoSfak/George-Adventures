class_name TalentData
## The talent tree (Greek): three branches of nine talents. George gets 1 talent point per
## level from level 2 (19 at level 20), so he can fill about one branch, not everything.
## A row (tier) opens once enough points sit in its branch: TIER_GATE.
## "mods" are per rank and use the keys of stats.gd. "skill" unlocks an active skill from
## skill_data.gd. col/tier place the node in the window (3 x 3 grid per branch).

const TIER_GATE: Array[int] = [0, 5, 10]
const BRANCH_ORDER: Array[String] = ["guardian", "warrior", "saint"]

const BRANCHES := {
	"guardian": {"name": "Φρουρός", "color": Color(0.40, 0.66, 1.0), "icon": "shield", "desc": "Αντοχή και προστασία"},
	"warrior": {"name": "Πολεμιστής", "color": Color(0.96, 0.52, 0.22), "icon": "sword", "desc": "Ζημιά και ταχύτητα"},
	"saint": {"name": "Άγιος", "color": Color(0.98, 0.90, 0.42), "icon": "cross", "desc": "Θεραπεία και ευλογία"},
}

const NODES := {
	# ---------------------------------------------------------------- Φρουρός ----
	"g_hp": {"branch": "guardian", "tier": 0, "col": 0, "name": "Ατσάλινη Υγεία", "max": 3, "icon": "heart",
		"mods": {"hp_add": 15}, "desc": "Το σώμα σου αντέχει περισσότερα χτυπήματα."},
	"g_def": {"branch": "guardian", "tier": 0, "col": 1, "name": "Σκληρό Δέρμα", "max": 3, "icon": "armor",
		"mods": {"defense": 0.03}, "desc": "Κάθε χτύπημα που δέχεσαι πονάει λιγότερο."},
	"g_block": {"branch": "guardian", "tier": 0, "col": 2, "name": "Θώρακας Ασπίδας", "max": 2, "icon": "shield",
		"mods": {"block_add": 0.03}, "desc": "Η άμυνα (K) απορροφά ακόμα περισσότερη ζημιά."},
	"g_regen": {"branch": "guardian", "tier": 1, "col": 0, "name": "Ανθεκτικότητα", "max": 3, "icon": "heart",
		"mods": {"regen": 0.4}, "desc": "Οι πληγές σου κλείνουν μόνες τους."},
	"g_guard": {"branch": "guardian", "tier": 1, "col": 1, "name": "Ενισχυμένη Ασπίδα", "max": 2, "icon": "shield",
		"mods": {"guard_time_add": 1.5}, "desc": "Η Ασπίδα του Αγίου διαρκεί περισσότερο."},
	"g_taunt": {"branch": "guardian", "tier": 1, "col": 2, "name": "Κραυγή Πρόκλησης", "max": 1, "icon": "shout",
		"skill": "taunt", "desc": "Ξεκλειδώνει την ικανότητα Κραυγή Πρόκλησης."},
	"g_fort": {"branch": "guardian", "tier": 2, "col": 0, "name": "Φρούριο", "max": 3, "icon": "tower",
		"mods": {"hp_add": 25, "defense": 0.02}, "desc": "Στέκεσαι σαν τείχος."},
	"g_wall": {"branch": "guardian", "tier": 2, "col": 1, "name": "Τείχος", "max": 1, "icon": "tower",
		"skill": "wall", "desc": "Ξεκλειδώνει την ικανότητα Τείχος."},
	"g_last": {"branch": "guardian", "tier": 2, "col": 2, "name": "Τελευταία Στάση", "max": 1, "icon": "star",
		"mods": {"last_stand": 0.2}, "desc": "Με λιγότερο από 30% ζωή δέχεσαι 20% λιγότερη ζημιά."},

	# ------------------------------------------------------------- Πολεμιστής ----
	"w_dmg": {"branch": "warrior", "tier": 0, "col": 0, "name": "Δύναμη Μάχης", "max": 3, "icon": "sword",
		"mods": {"damage_mult": 0.05}, "desc": "Κάθε χτύπημα του σπαθιού σου δυναμώνει."},
	"w_crit": {"branch": "warrior", "tier": 0, "col": 1, "name": "Οξύ Μάτι", "max": 3, "icon": "eye",
		"mods": {"crit": 0.04}, "desc": "Βρίσκεις τα αδύναμα σημεία: διπλή ζημιά με κάποια πιθανότητα."},
	"w_move": {"branch": "warrior", "tier": 0, "col": 2, "name": "Γοργοπόδαρος", "max": 2, "icon": "arrow",
		"mods": {"speed_mult": 0.04}, "desc": "Τρέχεις πιο γρήγορα."},
	"w_cdr": {"branch": "warrior", "tier": 1, "col": 0, "name": "Συγκέντρωση", "max": 3, "icon": "star",
		"mods": {"cdr": 0.05}, "desc": "Οι ικανότητές σου ξαναγεμίζουν πιο γρήγορα."},
	"w_ps": {"branch": "warrior", "tier": 1, "col": 1, "name": "Αιχμηρό Χτύπημα", "max": 2, "icon": "sword",
		"mods": {"ps_mult": 0.25}, "desc": "Το Δυνατό Χτύπημα χτυπά πιο δυνατά."},
	"w_frenzy": {"branch": "warrior", "tier": 1, "col": 2, "name": "Αιματηρή Μανία", "max": 1, "icon": "claw",
		"skill": "frenzy", "desc": "Ξεκλειδώνει την ικανότητα Αιματηρή Μανία."},
	"w_whirl": {"branch": "warrior", "tier": 2, "col": 0, "name": "Ανεμοστρόβιλος", "max": 2, "icon": "whirl",
		"mods": {"whirl_radius": 1.2}, "desc": "Ο Σίφουνας πιάνει εχθρούς σε μεγαλύτερη απόσταση."},
	"w_leap": {"branch": "warrior", "tier": 2, "col": 1, "name": "Κεραυνός του Πολέμου", "max": 1, "icon": "bolt",
		"skill": "leap", "desc": "Ξεκλειδώνει την ικανότητα Κεραυνός του Πολέμου."},
	"w_life": {"branch": "warrior", "tier": 2, "col": 2, "name": "Αρπακτικό", "max": 2, "icon": "fang",
		"mods": {"lifesteal": 0.03}, "desc": "Γιατρεύεσαι από τη ζημιά που προκαλείς."},

	# ------------------------------------------------------------------ Άγιος ----
	"s_heal": {"branch": "saint", "tier": 0, "col": 0, "name": "Θεία Χάρη", "max": 3, "icon": "cross",
		"mods": {"heal_mult": 0.10}, "desc": "Κάθε θεραπεία (φίλτρα, ευχές) δυναμώνει."},
	"s_regen": {"branch": "saint", "tier": 0, "col": 1, "name": "Αγιασμός", "max": 3, "icon": "heart",
		"mods": {"regen": 0.3}, "desc": "Ένα ζεστό φως σε γιατρεύει σιγά σιγά."},
	"s_hp": {"branch": "saint", "tier": 0, "col": 2, "name": "Ευλογία", "max": 2, "icon": "star",
		"mods": {"hp_add": 15}, "desc": "Ο Άγιος σου χαρίζει περισσότερη ζωή."},
	"s_prayer": {"branch": "saint", "tier": 1, "col": 0, "name": "Ισχυρή Ευχή", "max": 2, "icon": "cross",
		"mods": {"prayer_add": 0.10}, "desc": "Η Ευχή του Αγίου γιατρεύει περισσότερο."},
	"s_fire": {"branch": "saint", "tier": 1, "col": 1, "name": "Φωτιά του Αγίου", "max": 2, "icon": "flame",
		"mods": {"damage_mult": 0.04}, "desc": "Το σπαθί σου καίει τους νεκρούς."},
	"s_flame": {"branch": "saint", "tier": 1, "col": 2, "name": "Θεία Φλόγα", "max": 1, "icon": "flame",
		"skill": "flame", "desc": "Ξεκλειδώνει την ικανότητα Θεία Φλόγα."},
	"s_rebirth": {"branch": "saint", "tier": 2, "col": 0, "name": "Ανάσταση", "max": 1, "icon": "star",
		"mods": {"rebirth": 1}, "desc": "Όταν πέφτεις, ο Άγιος σε σηκώνει με 50% ζωή (μία φορά ανά 5 λεπτά)."},
	"s_sanct": {"branch": "saint", "tier": 2, "col": 1, "name": "Ιερός Κύκλος", "max": 1, "icon": "ring",
		"skill": "sanctuary", "desc": "Ξεκλειδώνει την ικανότητα Ιερός Κύκλος."},
	"s_halo": {"branch": "saint", "tier": 2, "col": 2, "name": "Φωτοστέφανο", "max": 3, "icon": "ring",
		"mods": {"defense": 0.02, "regen": 0.2}, "desc": "Ένα αχνό φωτοστέφανο σε προστατεύει."},
}


## Talent points George has earned at this level.
static func points_for_level(level: int) -> int:
	return maxi(level - 1, 0)


static func spent(talents: Dictionary) -> int:
	var n := 0
	for id in talents:
		n += int(talents[id])
	return n


static func points_in_branch(talents: Dictionary, branch: String) -> int:
	var n := 0
	for id in talents:
		if NODES[id]["branch"] == branch:
			n += int(talents[id])
	return n


static func tier_open(talents: Dictionary, branch: String, tier: int) -> bool:
	return points_in_branch(talents, branch) >= TIER_GATE[tier]


## Why a talent cannot be learned right now ("" = it can).
static func block_reason(talents: Dictionary, id: String, free_points: int) -> String:
	var node: Dictionary = NODES[id]
	if int(talents.get(id, 0)) >= int(node["max"]):
		return "Στο μέγιστο"
	if not tier_open(talents, node["branch"], node["tier"]):
		return "Χρειάζονται %d πόντοι στον κλάδο %s" % [TIER_GATE[node["tier"]], BRANCHES[node["branch"]]["name"]]
	if free_points <= 0:
		return "Δεν έχεις πόντους ταλέντων"
	return ""


## Total modifiers of all learned talents: {key: value}.
static func mods_for(talents: Dictionary) -> Dictionary:
	var out := {}
	for id in talents:
		var rank := int(talents[id])
		if rank <= 0 or not NODES[id].has("mods"):
			continue
		var m: Dictionary = NODES[id]["mods"]
		for key in m:
			out[key] = float(out.get(key, 0.0)) + float(m[key]) * rank
	return out
