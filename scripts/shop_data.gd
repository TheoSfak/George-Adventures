class_name ShopData
## Everything the shops sell and buy (Greek): equipment, loot to sell, the two shops.
## Rebalance prices and stats here. "mods" use the keys documented in stats.gd.
## The starting sword and shield are not items: an empty slot means George's own gear.

const SLOTS: Array[String] = ["weapon", "armor", "shield"]
const SLOT_NAMES := {"weapon": "Όπλο", "armor": "Πανοπλία", "shield": "Ασπίδα"}
const SLOT_ICONS := {"weapon": "sword", "armor": "armor", "shield": "shield"}
## Icon colour per tier: steel, blue steel, holy gold, royal purple.
const TIER_COLORS: Array[Color] = [
	Color(0.78, 0.80, 0.84), Color(0.45, 0.68, 1.0), Color(1.0, 0.85, 0.35), Color(0.78, 0.45, 1.0),
]

const GEAR := {
	"weapon_1": {
		"name": "Σιδερένιο Σπαθί", "slot": "weapon", "tier": 1, "level": 1, "price": 60,
		"mods": {"damage_add": 4}, "desc": "Ένα γερό σπαθί από το σιδηρουργείο του χωριού.",
	},
	"weapon_2": {
		"name": "Ατσαλένιο Σπαθί", "slot": "weapon", "tier": 2, "level": 5, "price": 220,
		"mods": {"damage_add": 9, "crit": 0.03}, "desc": "Ατσάλι που κόβει κόκαλα σαν κλαδιά.",
	},
	"weapon_3": {
		"name": "Σπαθί του Αγίου", "slot": "weapon", "tier": 3, "level": 10, "price": 600,
		"mods": {"damage_add": 16, "crit": 0.05}, "desc": "Ευλογημένο από τον Άγιο Βλάση· λάμπει στο σκοτάδι.",
	},
	"weapon_4": {
		"name": "Βασιλικό Σπαθί", "slot": "weapon", "tier": 4, "level": 15, "price": 1500,
		"mods": {"damage_add": 26, "crit": 0.08, "lifesteal": 0.03}, "desc": "Φτιαγμένο για βασιλιάδες, κρατημένο από ήρωες.",
	},
	"armor_1": {
		"name": "Δερμάτινη Πανοπλία", "slot": "armor", "tier": 1, "level": 1, "price": 60,
		"mods": {"hp_add": 25, "defense": 0.05}, "desc": "Ελαφριά και άνετη· σε προστατεύει από τα πρώτα χτυπήματα.",
	},
	"armor_2": {
		"name": "Ατσαλένια Πανοπλία", "slot": "armor", "tier": 2, "level": 5, "price": 220,
		"mods": {"hp_add": 60, "defense": 0.10}, "desc": "Βαριά πανοπλία από τον Νικήτα τον σιδερά.",
	},
	"armor_3": {
		"name": "Πανοπλία του Αγίου", "slot": "armor", "tier": 3, "level": 10, "price": 600,
		"mods": {"hp_add": 110, "defense": 0.16, "regen": 0.5}, "desc": "Μια χρυσή ευχή είναι ραμμένη στο εσωτερικό της.",
	},
	"armor_4": {
		"name": "Βασιλική Πανοπλία", "slot": "armor", "tier": 4, "level": 15, "price": 1500,
		"mods": {"hp_add": 180, "defense": 0.24, "regen": 1.0}, "desc": "Η πανοπλία των παλιών φρουράρχων.",
	},
	"shield_1": {
		"name": "Ξύλινη Ασπίδα", "slot": "shield", "tier": 1, "level": 1, "price": 60,
		"mods": {"block_add": 0.02, "defense": 0.02}, "desc": "Απλή, με σιδερένιο κέντρο.",
	},
	"shield_2": {
		"name": "Ατσαλένια Ασπίδα", "slot": "shield", "tier": 2, "level": 5, "price": 220,
		"mods": {"block_add": 0.04, "defense": 0.04}, "desc": "Τετράγωνη, βαριά, αξιόπιστη.",
	},
	"shield_3": {
		"name": "Ασπίδα του Αγίου", "slot": "shield", "tier": 3, "level": 10, "price": 600,
		"mods": {"block_add": 0.06, "defense": 0.06, "hp_add": 30}, "desc": "Τα αγκάθια της τρομάζουν ακόμη και τους νεκρούς.",
	},
	"shield_4": {
		"name": "Βασιλική Ασπίδα", "slot": "shield", "tier": 4, "level": 15, "price": 1500,
		"mods": {"block_add": 0.09, "defense": 0.08, "hp_add": 60}, "desc": "Δεν έχει χτυπηθεί ποτέ σε μάχη. Ακόμα.",
	},
}

## Loot that only sells: dropped by skeletons, bought by the market.
const JUNK := {
	"bone": {"name": "Κόκαλο", "price": 3, "color": Color(0.92, 0.90, 0.82), "icon": "bone", "desc": "Ένα καθαρό κόκαλο σκελετού."},
	"rust": {"name": "Σκουριασμένη Λεπίδα", "price": 9, "color": Color(0.70, 0.45, 0.28), "icon": "sword", "desc": "Παλιό σίδερο· κάποιος θα το λιώσει."},
	"charm": {"name": "Φυλαχτό των Νεκρών", "price": 25, "color": Color(0.55, 0.95, 0.65), "icon": "star", "desc": "Λάμπει με ένα ψυχρό πράσινο φως."},
}

## Stock lines: {"type": "item" | "gear", "id", "price" (items only), "level" (items only)}
const SHOPS := {
	"market": {
		"title": "Παζάρι",
		"keeper": "Κυρά-Ελένη",
		"greeting": [
			"Καλώς τον Γιώργο! Φίλτρα, βότανα, ό,τι χρειάζεται ένας ήρωας. Και ό,τι κόκαλα φέρεις, τα αγοράζω!",
		],
		"stock": [
			{"type": "item", "id": "health", "price": 25},
			{"type": "item", "id": "health_big", "price": 70, "level": 8},
			{"type": "item", "id": "power", "price": 60},
			{"type": "item", "id": "speed", "price": 45},
		],
		"buys": "junk",
	},
	"blacksmith": {
		"title": "Σιδηρουργείο",
		"keeper": "Νικήτας ο Σιδεράς",
		"greeting": [
			"Έλα, Γιώργο! Καλό σίδερο, καλή καρδιά. Δες τι έχω στο πάγκο· και ό,τι παλιό σου περισσεύει, το αγοράζω.",
		],
		"stock": [
			{"type": "gear", "id": "weapon_1"}, {"type": "gear", "id": "weapon_2"},
			{"type": "gear", "id": "weapon_3"}, {"type": "gear", "id": "weapon_4"},
			{"type": "gear", "id": "armor_1"}, {"type": "gear", "id": "armor_2"},
			{"type": "gear", "id": "armor_3"}, {"type": "gear", "id": "armor_4"},
			{"type": "gear", "id": "shield_1"}, {"type": "gear", "id": "shield_2"},
			{"type": "gear", "id": "shield_3"}, {"type": "gear", "id": "shield_4"},
		],
		"buys": "gear",
	},
}


static func gear_sell_price(id: String) -> int:
	return int(GEAR[id]["price"] * 0.4)


static func tier_color(id: String) -> Color:
	return TIER_COLORS[int(GEAR[id]["tier"]) - 1]


## Modifiers of everything equipped: {key: value}.
static func equipment_mods(equipped: Dictionary) -> Dictionary:
	var out := {}
	for slot in SLOTS:
		var id: String = equipped.get(slot, "")
		if id != "":
			out = Stats.merge(out, GEAR[id]["mods"])
	return out
