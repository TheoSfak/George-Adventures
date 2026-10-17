class_name BountyData
extends RefCounted
## Data definitions for the Village Bounty Board & Hunting Contracts.
## Contains contract templates, difficulty tiers, rewards, and Hunter Rank titles.

const TIERS := {
	"bronze": {
		"name": "Χάλκινη Επικήρυξη",
		"color": Color(0.85, 0.58, 0.32),
		"tag": "ΧΑΛΚΙΝΟ",
	},
	"silver": {
		"name": "Ασημένια Επικήρυξη",
		"color": Color(0.78, 0.85, 0.95),
		"tag": "ΑΣΗΜΕΝΙΟ",
	},
	"gold": {
		"name": "Χρυσή Επικήρυξη",
		"color": Color(1.0, 0.84, 0.28),
		"tag": "ΧΡΥΣΟ",
	},
}

const HUNTER_RANKS: Array[Dictionary] = [
	{"threshold": 0, "title": "Μισθοφόρος του Χωριού", "badge": "⚔️"},
	{"threshold": 3, "title": "Ιχνηλάτης Αγρίων Θηρίων", "badge": "🐾"},
	{"threshold": 6, "title": "Κυνηγός Επικηρυγμένων", "badge": "🎯"},
	{"threshold": 10, "title": "Προστάτης του Αγίου Βλάση", "badge": "🛡️"},
	{"threshold": 15, "title": "Θρυλικός Εκτελεστής", "badge": "👑"},
]

const CONTRACT_TEMPLATES: Array[Dictionary] = [
	{
		"id": "bounty_wolves",
		"title": "Εξόντωσε το Alpha Wolf στα Χρυσά Πεύκα",
		"tier": "bronze",
		"desc": "Η αγέλη των λύκων στα Χρυσά Πεύκα έχει αγριέψει και επιτίθεται στους ταξιδιώτες. Εξολόθρευσε 4 λύκους για να προστατέψεις το χωριό.",
		"target_kind": "wolf",
		"target_name": "Λύκοι των Χρυσών Πεύκων",
		"count": 4,
		"reward_gold": 450,
		"reward_xp": 380,
		"reward_items": {"bone_shard": 2},
	},
	{
		"id": "bounty_spiders",
		"title": "Καθάρισε τη Φωλιά των Αραχνών",
		"tier": "bronze",
		"desc": "Γιγάντιες σπηλαιόβιες αράχνες έχουν απλώσει δηλητηριώδεις ιστούς στα μονοπάτια. Εξόντωσε 5 αράχνες για να ανοίξει ο δρόμος.",
		"target_kind": "spider",
		"target_name": "Σπηλαιόβιες Αράχνες",
		"count": 5,
		"reward_gold": 480,
		"reward_xp": 400,
		"reward_items": {"iron_scrap": 1, "potion": 2},
	},
	{
		"id": "bounty_bandits",
		"title": "Ανάκτησε τα Κλεμμένα Εφόδια του Εμπόρου",
		"tier": "silver",
		"desc": "Οι ληστές του δάσους άρπαξαν τα εφόδια και τα σακιά του εμπόρου κυρ-Παντελή. Τιμώρησε 5 ληστές στο κρησφύγετό τους.",
		"target_kind": "bandit",
		"target_name": "Ληστές του Δάσους",
		"count": 5,
		"reward_gold": 650,
		"reward_xp": 520,
		"reward_items": {"iron_scrap": 2},
	},
	{
		"id": "bounty_skeletons",
		"title": "Εξαγνισμός των Ακοίμητων Σκελετών",
		"tier": "silver",
		"desc": "Νεκροζώντανοι σκελετοί περιπολούν τη νύχτα γύρω από την κρύπτη και το λατομείο. Καθάρισε 8 σκελετούς για την ασφάλεια των κατοίκων.",
		"target_kind": "skeleton",
		"target_name": "Ακοίμητοι Σκελετοί",
		"count": 8,
		"reward_gold": 580,
		"reward_xp": 460,
		"reward_items": {"bone_shard": 3},
	},
	{
		"id": "bounty_orcs",
		"title": "Εμπροσθοφυλακή των Όρκ",
		"tier": "silver",
		"desc": "Άγριοι πολεμιστές όρκ από το Κατεστραμμένο Φρούριο παραμονεύουν στα ανατολικά. Εξόντωσε 4 πολεμιστές όρκ πριν οργανώσουν επιδρομή.",
		"target_kind": "orc",
		"target_name": "Όρκ Πολεμιστές",
		"count": 4,
		"reward_gold": 750,
		"reward_xp": 580,
		"reward_items": {"iron_scrap": 2, "lava_ember": 1},
	},
	{
		"id": "bounty_chief",
		"title": "Επικήρυξη: Αρχηγός των Ληστών",
		"tier": "gold",
		"desc": "Ο διαβόητος Αρχηγός των Ληστών κρύβεται στις σκηνές του βορειοδυτικού δάσους. Εξολόθρευσε τον αρχηγό και τερμάτισε τη δράση της συμμορίας!",
		"target_kind": "bandit_chief",
		"target_name": "Αρχηγός των Ληστών",
		"count": 1,
		"reward_gold": 950,
		"reward_xp": 750,
		"reward_items": {"iron_scrap": 3, "potion": 3},
	},
	{
		"id": "bounty_golem",
		"title": "Ο Τρόμος της Στάχτης: Magma Golem",
		"tier": "gold",
		"desc": "Στην Κοιλάδα της Στάχτης, γιγάντια γκόλεμ μάγματος κινούνται κατά μήκος των ποταμών λάβας. Κατέστρεψε 2 Magma Golem.",
		"target_kind": "magma_golem",
		"target_name": "Γκόλεμ Μάγματος",
		"count": 2,
		"reward_gold": 1100,
		"reward_xp": 850,
		"reward_items": {"lava_ember": 2},
	},
	{
		"id": "bounty_warlord",
		"title": "Επικήρυξη Warlord: Γκρομ'γκαρ",
		"tier": "gold",
		"desc": "Ο αιμοδιψής Πολέμαρχος Γκρομ'γκαρ απειλεί ολόκληρο το νησί. Εισέβαλε στο φρούριο, νίκησε τον πολέμαρχο και πάρε τη μέγιστη αμοιβή!",
		"target_kind": "orc_warlord",
		"target_name": "Πολέμαρχος Γκρομ'γκαρ",
		"count": 1,
		"reward_gold": 1400,
		"reward_xp": 1100,
		"reward_items": {"lava_ember": 3},
	},
]

static func get_hunter_rank(completed_count: int) -> Dictionary:
	var best_rank: Dictionary = HUNTER_RANKS[0]
	for r in HUNTER_RANKS:
		if completed_count >= int(r["threshold"]):
			best_rank = r
	return best_rank

static func get_template(id: String) -> Dictionary:
	for t in CONTRACT_TEMPLATES:
		if t["id"] == id:
			return t
	return {}

static func is_target_match(target_kind: String, killed_kind: String) -> bool:
	if target_kind == killed_kind:
		return true
	if target_kind == "skeleton" and QuestData.is_skeleton(killed_kind):
		return true
	if target_kind == "bandit" and QuestData.is_bandit(killed_kind):
		return true
	if target_kind == "orc" and QuestData.is_orc(killed_kind):
		return true
	return false
