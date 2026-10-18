class_name AchievementData
extends RefCounted
## Data definitions for the 37+ Achievements system in George Adventures.
## Categories:
##   - combat: Kill counts and weapon mastery
##   - bosses: Epic boss battles and mini-bosses
##   - arena: Gladiator proving grounds tiers
##   - exploration: Secrets, regions, parkour, and island landmarks
##   - wealth: Gold, chests, fishing, and foraging
##   - progression: Hero levels, blacksmith upgrades, home, and pets

const CATEGORIES := {
	"all": "Όλα",
	"combat": "⚔️ Μάχη",
	"bosses": "👑 Αφεντικά",
	"arena": "🏟️ Αρένα",
	"exploration": "🧭 Εξερεύνηση",
	"wealth": "💰 Πλούτος",
	"progression": "⚒️ Ήρωας",
}

const ACHIEVEMENTS: Array[Dictionary] = [
	# -------------------------------------------------------------------------
	# 1. Combat & Kills
	# -------------------------------------------------------------------------
	{
		"id": "first_blood",
		"category": "combat",
		"title": "Πρώτο Αίμα",
		"desc": "Εξολόθρευσε τον 1ο σου εχθρό στον Άγιο Βλάση.",
		"icon": "⚔️",
		"stat": "total_kills",
		"target": 1,
		"reward": {"gold": 50, "xp": 100, "title": "Μαχητής"}
	},
	{
		"id": "skeleton_bane",
		"category": "combat",
		"title": "Καταλύτης των Σκελετών",
		"desc": "Στείλε 25 σκελετούς πίσω στον τάφο τους.",
		"icon": "💀",
		"stat": "skeleton_kills",
		"target": 25,
		"reward": {"gold": 250, "xp": 400, "title": "Εξορκιστής των Οστών"}
	},
	{
		"id": "orc_slayer",
		"category": "combat",
		"title": "Εξολοθρευτής των Ορκ",
		"desc": "Εξόντωσε 20 πολεμιστές και berserkers των Ορκ.",
		"icon": "🪓",
		"stat": "orc_kills",
		"target": 20,
		"reward": {"gold": 350, "xp": 600, "title": "Τρομοκράτης των Ορκ"}
	},
	{
		"id": "bandit_hunter",
		"category": "combat",
		"title": "Τιμωρός των Ληστών",
		"desc": "Εξουδετέρωσε 15 ληστές και επιδρομείς.",
		"icon": "🏹",
		"stat": "bandit_kills",
		"target": 15,
		"reward": {"gold": 300, "xp": 500, "title": "Φύλακας των Δρόμων"}
	},
	{
		"id": "corsair_cleaner",
		"category": "combat",
		"title": "Κυνηγός Πειρατών",
		"desc": "Εξόντωσε 15 κουρσάρους στο Νησί των Πειρατών.",
		"icon": "🏴‍☠️",
		"stat": "pirate_kills",
		"target": 15,
		"reward": {"gold": 400, "xp": 650, "title": "Μάστιγα των Κουρσάρων"}
	},
	{
		"id": "wolf_stalker",
		"category": "combat",
		"title": "Ιχνηλάτης Λύκων",
		"desc": "Κατατρόπωσε 10 άγριους λύκους στα δάση.",
		"icon": "🐺",
		"stat": "wolf_kills",
		"target": 10,
		"reward": {"gold": 200, "xp": 350, "title": "Κυνηγός των Πεύκων"}
	},
	{
		"id": "centurion_slayer",
		"category": "combat",
		"title": "Εκατόνταρχος του Πολέμου",
		"desc": "Φτάσε τις 100 συνολικές εξοντώσεις εχθρών.",
		"icon": "🛡️",
		"stat": "total_kills",
		"target": 100,
		"reward": {"gold": 750, "xp": 1200, "title": "Εκατόνταρχος"}
	},
	{
		"id": "master_executioner",
		"category": "combat",
		"title": "Μέγας Εκτελεστής",
		"desc": "Φτάσε τις 250 συνολικές εξοντώσεις πλασμάτων.",
		"icon": "⚡",
		"stat": "total_kills",
		"target": 250,
		"reward": {"gold": 1500, "xp": 2500, "title": "Αήττητος Στρατηλάτης"}
	},

	# -------------------------------------------------------------------------
	# 2. Bosses & Champions
	# -------------------------------------------------------------------------
	{
		"id": "werewolf_slayer",
		"category": "bosses",
		"title": "Φονέας του Λυκάνθρωπου",
		"desc": "Νίκησε τον Λυκάνθρωπο στην είσοδο του χωριού.",
		"icon": "🌕",
		"stat": "kill_werewolf",
		"target": 1,
		"reward": {"gold": 100, "xp": 200, "title": "Λυκοφονιάς"}
	},
	{
		"id": "bone_king_down",
		"category": "bosses",
		"title": "Η Πτώση του Βασιλιά των Οστών",
		"desc": "Νίκησε τον Βασιλιά των Οστών στην αρχαία κρύπτη.",
		"icon": "👑",
		"stat": "kill_king",
		"target": 1,
		"reward": {"gold": 300, "xp": 500, "title": "Καταλυτής του Θρόνου"}
	},
	{
		"id": "bandit_chief_down",
		"category": "bosses",
		"title": "Το Τέλος του Αρχιληστή",
		"desc": "Εξουδετέρωσε τον Αρχηγό των Ληστών στο κρησφύγετο.",
		"icon": "🗡️",
		"stat": "kill_bandit_chief",
		"target": 1,
		"reward": {"gold": 350, "xp": 600, "title": "Ειρηνοποιός"}
	},
	{
		"id": "shadow_conqueror",
		"category": "bosses",
		"title": "Εξολοθρευτής του Μαλάκαρ",
		"desc": "Νίκησε τον Σκοτεινό Άρχοντα Μαλάκαρ στα Σύνορα.",
		"icon": "🔮",
		"stat": "kill_malakar",
		"target": 1,
		"reward": {"gold": 600, "xp": 1000, "title": "Φως στο Σκοτάδι"}
	},
	{
		"id": "fire_subduer",
		"category": "bosses",
		"title": "Δαμαστής της Φλόγας",
		"desc": "Νίκησε τον Πυρφόρο στο Ναό της Κοιλάδας της Στάχτης.",
		"icon": "🔥",
		"stat": "kill_pyrforos",
		"target": 1,
		"reward": {"gold": 800, "xp": 1500, "title": "Πυροδαμαστής"}
	},
	{
		"id": "cinder_ruler",
		"category": "bosses",
		"title": "Κυρίαρχος της Τέφρας",
		"desc": "Κατατρόπωσε τον Άρχοντα της Τέφρας στο Άδυτο της Φλόγας.",
		"icon": "🌋",
		"stat": "kill_cinder_archon",
		"target": 1,
		"reward": {"gold": 1200, "xp": 2500, "title": "Άρχοντας της Τέφρας"}
	},
	{
		"id": "gromgar_down",
		"category": "bosses",
		"title": "Ο Θάνατος του Γκρομ'γκαρ",
		"desc": "Κατατρόπωσε τον Πολέμαρχο των Ορκ στο Ερειπωμένο Κάστρο.",
		"icon": "👹",
		"stat": "kill_orc_warlord",
		"target": 1,
		"reward": {"gold": 500, "xp": 900, "title": "Πορθητής του Προπυργίου"}
	},
	{
		"id": "dread_down",
		"category": "bosses",
		"title": "Η Ύστατη Βύθιση του Μαυροδόντη",
		"desc": "Νίκησε τον Αρχικουρσάρο Μαυροδόντη στην καλντέρα του ηφαιστείου.",
		"icon": "⚓",
		"stat": "kill_pirate_captain",
		"target": 1,
		"reward": {"gold": 750, "xp": 1300, "title": "Κυρίαρχος των Επτά Θαλασσών"}
	},

	# -------------------------------------------------------------------------
	# 3. Arena Proving Grounds
	# -------------------------------------------------------------------------
	{
		"id": "arena_bronze",
		"category": "arena",
		"title": "Χάλκινος Μονομάχος",
		"desc": "Ολοκλήρωσε τη Χάλκινη Δοκιμασία στην Αρένα.",
		"icon": "🥉",
		"stat": "arena_bronze",
		"target": 1,
		"reward": {"gold": 200, "xp": 400, "title": "Μονομάχος"}
	},
	{
		"id": "arena_silver",
		"category": "arena",
		"title": "Ασημένιος Μονομάχος",
		"desc": "Ολοκλήρωσε την Ασημένια Δοκιμασία στην Αρένα.",
		"icon": "🥈",
		"stat": "arena_silver",
		"target": 1,
		"reward": {"gold": 400, "xp": 800, "title": "Σιδερένιος Μονομάχος"}
	},
	{
		"id": "arena_gold",
		"category": "arena",
		"title": "Χρυσός Μονομάχος",
		"desc": "Ολοκλήρωσε τη Χρυσή Δοκιμασία απέναντι στον Βοργκ'θουλ.",
		"icon": "🥇",
		"stat": "arena_gold",
		"target": 1,
		"reward": {"gold": 750, "xp": 1500, "title": "Αδάμαστος Μονομάχος"}
	},
	{
		"id": "arena_heroic",
		"category": "arena",
		"title": "Ηρωικός Μονομάχος",
		"desc": "Νίκησε τον Σκελετό Τιτάνα στην Ηρωική Δοκιμασία.",
		"icon": "🏆",
		"stat": "arena_heroic",
		"target": 1,
		"reward": {"gold": 1200, "xp": 2500, "title": "Ηρωικός Μονομάχος"}
	},
	{
		"id": "arena_champion",
		"category": "arena",
		"title": "Πρωταθλητής του Αγίου Βλάση",
		"desc": "Νίκησε τον Ανώτατο Πρωταθλητή Βαλτάσαρ στη Μυθική Δοκιμασία.",
		"icon": "🌟",
		"stat": "arena_mythic",
		"target": 1,
		"reward": {"gold": 3000, "xp": 5000, "title": "Πρωταθλητής του Αγίου Βλάση"}
	},

	# -------------------------------------------------------------------------
	# 4. Exploration & World
	# -------------------------------------------------------------------------
	{
		"id": "rooftop_parkour",
		"category": "exploration",
		"title": "Ακροβάτης των Στεγών",
		"desc": "Ολοκλήρωσε τη διαδρομή Parkour στις στέγες του χωριού.",
		"icon": "🎪",
		"stat": "parkour_completed",
		"target": 1,
		"reward": {"gold": 350, "xp": 600, "title": "Ακροβάτης των Στεγών"}
	},
	{
		"id": "sea_voyager",
		"category": "exploration",
		"title": "Άρχοντας των Κυμάτων",
		"desc": "Άνοιξε πανιά με τη βάρκα και ταξίδεψε στην ανοικτή νότια θάλασσα.",
		"icon": "⛵",
		"stat": "sailed_boat",
		"target": 1,
		"reward": {"gold": 250, "xp": 450, "title": "Θαλασσοπόρος"}
	},
	{
		"id": "eagle_bell",
		"category": "exploration",
		"title": "Ηχώ των Κορυφών",
		"desc": "Ανέβα στο Πανόραμα του Αετού και χτύπησε την αρχαία καμπάνα.",
		"icon": "🔔",
		"stat": "rang_eagle_bell",
		"target": 1,
		"reward": {"gold": 200, "xp": 350, "title": "Ορειβάτης"}
	},
	{
		"id": "castle_visitor",
		"category": "exploration",
		"title": "Εξερευνητής Κάστρων",
		"desc": "Μπες στο εσωτερικό των τριών μεγάλων κάστρων του νησιού.",
		"icon": "🏰",
		"stat": "castles_visited",
		"target": 3,
		"reward": {"gold": 400, "xp": 750, "title": "Καστροφύλακας"}
	},
	{
		"id": "smugglers_grotto",
		"category": "exploration",
		"title": "Το Μυστικό των Λαθρεμπόρων",
		"desc": "Ανακάλυψε τη μυστική κρύπτη των πειρατών στο Νησί.",
		"icon": "🏝️",
		"stat": "found_smugglers_grotto",
		"target": 1,
		"reward": {"gold": 500, "xp": 800, "title": "Εξερευνητής Σπηλαίων"}
	},
	{
		"id": "frontier_scout",
		"category": "exploration",
		"title": "Πρωτοπόρος των Συνόρων",
		"desc": "Διάβηκε τη μεγάλη ορεινή πύλη προς τα Σύνορα.",
		"icon": "🗺️",
		"stat": "entered_frontier",
		"target": 1,
		"reward": {"gold": 300, "xp": 500, "title": "Πρωτοπόρος"}
	},
	{
		"id": "ash_explorer",
		"category": "exploration",
		"title": "Στις Φλόγες της Στάχτης",
		"desc": "Εξερεύνησε τα ηφαιστειακά περάσματα της Κοιλάδας της Στάχτης.",
		"icon": "🌋",
		"stat": "entered_ash_valley",
		"target": 1,
		"reward": {"gold": 400, "xp": 700, "title": "Σταχτοβάτης"}
	},

	# -------------------------------------------------------------------------
	# 5. Wealth, Gathering & Fishing
	# -------------------------------------------------------------------------
	{
		"id": "chest_finder",
		"category": "wealth",
		"title": "Κυνηγός Θησαυρών",
		"desc": "Άνοιξε 10 σεντούκια θησαυρών στο νησί.",
		"icon": "📦",
		"stat": "chests_opened",
		"target": 10,
		"reward": {"gold": 300, "xp": 500, "title": "Κυνηγός Θησαυρών"}
	},
	{
		"id": "pirate_hoard",
		"category": "wealth",
		"title": "Συλλέκτης Θαμμένων Θησαυρών",
		"desc": "Ξέθαψε και άνοιξε τους θαμμένους πειρατικούς θησαυρούς.",
		"icon": "💎",
		"stat": "buried_chests_opened",
		"target": 5,
		"reward": {"gold": 750, "xp": 1200, "title": "Πειρατής Θησαυροφύλακας"}
	},
	{
		"id": "gold_stack",
		"category": "wealth",
		"title": "Χρυσοχόος του Χωριού",
		"desc": "Συγκέντρωσε 1.000 χρυσά νομίσματα στο πουγκί σου.",
		"icon": "🪙",
		"stat": "gold_held",
		"target": 1000,
		"reward": {"gold": 200, "xp": 350, "title": "Ευκατάστατος"}
	},
	{
		"id": "gold_tycoon",
		"category": "wealth",
		"title": "Μεγιστάνας του Αγίου Βλάση",
		"desc": "Συγκέντρωσε 10.000 χρυσά νομίσματα.",
		"icon": "💰",
		"stat": "gold_held",
		"target": 10000,
		"reward": {"gold": 1500, "xp": 2500, "title": "Μεγιστάνας"}
	},
	{
		"id": "master_angler",
		"category": "wealth",
		"title": "Δεινός Ψαράς",
		"desc": "Ψάρεψε 5 ψάρια στις ακτές και τις λίμνες.",
		"icon": "🐟",
		"stat": "fish_caught",
		"target": 5,
		"reward": {"gold": 250, "xp": 400, "title": "Δεινός Ψαράς"}
	},
	{
		"id": "herbalist",
		"category": "wealth",
		"title": "Βοτανολόγος των Κορυφών",
		"desc": "Σύλλεξε 10 άγρια βότανα και άνθη από τη φύση.",
		"icon": "🌿",
		"stat": "herbs_harvested",
		"target": 10,
		"reward": {"gold": 200, "xp": 350, "title": "Βοτανολόγος"}
	},

	# -------------------------------------------------------------------------
	# 6. Progression & Hero Mastery
	# -------------------------------------------------------------------------
	{
		"id": "level_ten",
		"category": "progression",
		"title": "Ανερχόμενος Ήρωας",
		"desc": "Φτάσε στο Επίπεδο 10.",
		"icon": "⭐",
		"stat": "hero_level",
		"target": 10,
		"reward": {"gold": 300, "xp": 500, "title": "Ανερχόμενος Ήρωας"}
	},
	{
		"id": "level_twenty_five",
		"category": "progression",
		"title": "Βετεράνος των Μαχών",
		"desc": "Φτάσε στο Επίπεδο 25.",
		"icon": "🌟",
		"stat": "hero_level",
		"target": 25,
		"reward": {"gold": 800, "xp": 1500, "title": "Βετεράνος των Μαχών"}
	},
	{
		"id": "level_forty",
		"category": "progression",
		"title": "Θρύλος του Αγίου Βλάση",
		"desc": "Φτάσε στο Μέγιστο Επίπεδο 40.",
		"icon": "🔱",
		"stat": "hero_level",
		"target": 40,
		"reward": {"gold": 2500, "xp": 5000, "title": "Θρύλος του Αγίου Βλάση"}
	},
	{
		"id": "forge_master",
		"category": "progression",
		"title": "Μάστορας του Αμονιού",
		"desc": "Αναβάθμισε οποιοδήποτε όπλο ή πανοπλία στο μέγιστο +5.",
		"icon": "🔨",
		"stat": "gear_upgraded_5",
		"target": 1,
		"reward": {"gold": 1000, "xp": 1800, "title": "Μάστορας του Αμονιού"}
	},
	{
		"id": "legendary_craft",
		"category": "progression",
		"title": "Σιδηρουργός των Θρύλων",
		"desc": "Σφυρηλάτησε ένα θρυλικό όπλο ή πανοπλία στο σιδηρουργείο.",
		"icon": "⚔️",
		"stat": "crafted_legendary",
		"target": 1,
		"reward": {"gold": 750, "xp": 1200, "title": "Αρχισιδηρουργός"}
	},
	{
		"id": "homeowner",
		"category": "progression",
		"title": "Νοικοκύρης του Χωριού",
		"desc": "Απόκτησε το δικό σου σπίτι στον Άγιο Βλάση.",
		"icon": "🏡",
		"stat": "cottage_owned",
		"target": 1,
		"reward": {"gold": 500, "xp": 800, "title": "Νοικοκύρης"}
	},
	{
		"id": "best_friend",
		"category": "progression",
		"title": "Ο Καλύτερος Φίλος",
		"desc": "Χάιδεψε και γίνε φίλος με τον πιστό σκύλο Μούργο ή το λυκάκι.",
		"icon": "🐾",
		"stat": "petted_companion",
		"target": 1,
		"reward": {"gold": 150, "xp": 300, "title": "Φίλος των Ζώων"}
	},
]

static func get_achievement(ach_id: String) -> Dictionary:
	for a in ACHIEVEMENTS:
		if a["id"] == ach_id:
			return a
	return {}

static func get_by_category(category: String) -> Array[Dictionary]:
	if category == "all" or category.is_empty():
		return ACHIEVEMENTS.duplicate()
	var res: Array[Dictionary] = []
	for a in ACHIEVEMENTS:
		if a.get("category") == category:
			res.append(a)
	return res
