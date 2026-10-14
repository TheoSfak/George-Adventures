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
	Color(0.40, 0.95, 0.80), Color(0.35, 0.55, 1.0), Color(1.0, 0.62, 0.20), Color(0.95, 0.40, 0.55), Color(1.0, 1.0, 0.85),
]

const GEAR := {
	"weapon_1": {
		"name": "Σιδερένιο Σπαθί", "slot": "weapon", "tier": 1, "level": 1, "price": 60,
		"mods": {"damage_add": 4}, "desc": "Ένα γερό σπαθί από το σιδηρουργείο του χωριού.",
	},
	"weapon_2": {
		"name": "Ατσαλένιο Σπαθί", "slot": "weapon", "tier": 2, "level": 5, "price": 220,
		"mods": {"damage_add": 9, "crit": 0.03, "attack_speed": 0.03}, "desc": "Ατσάλι που κόβει κόκαλα σαν κλαδιά.",
	},
	"weapon_3": {
		"name": "Σπαθί του Αγίου", "slot": "weapon", "tier": 3, "level": 10, "price": 600,
		"mods": {"damage_add": 16, "crit": 0.05, "attack_speed": 0.06}, "desc": "Ευλογημένο από τον Άγιο Βλάση· λάμπει στο σκοτάδι.",
	},
	"weapon_4": {
		"name": "Βασιλικό Σπαθί", "slot": "weapon", "tier": 4, "level": 15, "price": 1500,
		"mods": {"damage_add": 26, "crit": 0.08, "lifesteal": 0.03, "attack_speed": 0.09}, "desc": "Φτιαγμένο για βασιλιάδες, κρατημένο από ήρωες.",
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
	"weapon_5": {
		"name": "Σπαθί της Αυγής", "slot": "weapon", "tier": 5, "level": 20, "price": 3500,
		"mods": {"damage_add": 36, "crit": 0.10, "lifesteal": 0.04, "attack_speed": 0.12}, "desc": "Το πρώτο φως της μέρας χαράζει τη λεπίδα του.",
	},
	"weapon_6": {
		"name": "Σπαθί της Καταιγίδας", "slot": "weapon", "tier": 6, "level": 25, "price": 7000,
		"mods": {"damage_add": 48, "crit": 0.12, "lifesteal": 0.05, "attack_speed": 0.15}, "desc": "Κεραυνοί κουρνιάζουν στην κόψη του.",
	},
	"weapon_7": {
		"name": "Σπαθί του Ήλιου", "slot": "weapon", "tier": 7, "level": 30, "price": 14000,
		"mods": {"damage_add": 62, "crit": 0.14, "lifesteal": 0.06, "attack_speed": 0.18}, "desc": "Καίει σαν το μεσημέρι και λάμπει σαν χρυσάφι.",
	},
	"weapon_8": {
		"name": "Σπαθί του Ουρανού", "slot": "weapon", "tier": 8, "level": 35, "price": 26000,
		"mods": {"damage_add": 80, "crit": 0.16, "lifesteal": 0.07, "attack_speed": 0.21}, "desc": "Φτιαγμένο από ουράνιο ατσάλι· κόβει τον άνεμο.",
	},
	"weapon_9": {
		"name": "Σπαθί των Αρχαγγέλων", "slot": "weapon", "tier": 9, "level": 40, "price": 45000,
		"mods": {"damage_add": 100, "crit": 0.18, "lifesteal": 0.08, "attack_speed": 0.24}, "desc": "Το όπλο που κρατούσαν οι φύλακες του ουρανού.",
	},
	"armor_5": {
		"name": "Πανοπλία της Αυγής", "slot": "armor", "tier": 5, "level": 20, "price": 3500,
		"mods": {"hp_add": 240, "defense": 0.28, "regen": 1.5}, "desc": "Ελαφριά σαν πρωινή ομίχλη, σκληρή σαν βράχος.",
	},
	"armor_6": {
		"name": "Πανοπλία της Καταιγίδας", "slot": "armor", "tier": 6, "level": 25, "price": 7000,
		"mods": {"hp_add": 310, "defense": 0.32, "regen": 2.0}, "desc": "Σκουριάζει από τη βροχή, μα ποτέ από τη μάχη.",
	},
	"armor_7": {
		"name": "Πανοπλία του Ήλιου", "slot": "armor", "tier": 7, "level": 30, "price": 14000,
		"mods": {"hp_add": 390, "defense": 0.36, "regen": 2.5}, "desc": "Λάμπει τόσο που τυφλώνει τους νεκρούς.",
	},
	"armor_8": {
		"name": "Πανοπλία του Ουρανού", "slot": "armor", "tier": 8, "level": 35, "price": 26000,
		"mods": {"hp_add": 480, "defense": 0.40, "regen": 3.0}, "desc": "Τα αστέρια είναι σφυρηλατημένα στο μέταλλό της.",
	},
	"armor_9": {
		"name": "Πανοπλία των Αρχαγγέλων", "slot": "armor", "tier": 9, "level": 40, "price": 45000,
		"mods": {"hp_add": 580, "defense": 0.44, "regen": 3.5}, "desc": "Δεν τη φόρεσε ποτέ θνητός. Μέχρι τώρα.",
	},
	"shield_5": {
		"name": "Ασπίδα της Αυγής", "slot": "shield", "tier": 5, "level": 20, "price": 3500,
		"mods": {"block_add": 0.10, "defense": 0.10, "hp_add": 80}, "desc": "Στέκει ακλόνητη στο πρώτο φως.",
	},
	"shield_6": {
		"name": "Ασπίδα της Καταιγίδας", "slot": "shield", "tier": 6, "level": 25, "price": 7000,
		"mods": {"block_add": 0.11, "defense": 0.12, "hp_add": 100}, "desc": "Οι κεραυνοί αναπηδούν πάνω της.",
	},
	"shield_7": {
		"name": "Ασπίδα του Ήλιου", "slot": "shield", "tier": 7, "level": 30, "price": 14000,
		"mods": {"block_add": 0.12, "defense": 0.14, "hp_add": 130}, "desc": "Ζεστή στο άγγιγμα, παγωμένη στην άμυνα.",
	},
	"shield_8": {
		"name": "Ασπίδα του Ουρανού", "slot": "shield", "tier": 8, "level": 35, "price": 26000,
		"mods": {"block_add": 0.13, "defense": 0.16, "hp_add": 160}, "desc": "Τόσο μεγάλη όσο ο ορίζοντας.",
	},
	"shield_9": {
		"name": "Ασπίδα των Αρχαγγέλων", "slot": "shield", "tier": 9, "level": 40, "price": 45000,
		"mods": {"block_add": 0.14, "defense": 0.18, "hp_add": 200}, "desc": "Μια ασπίδα που φυλάει όλο το χωριό.",
	},
}

## Loot that only sells: dropped by skeletons, bought by the market.
const JUNK := {
	"bone": {"name": "Κόκαλο", "price": 3, "color": Color(0.92, 0.90, 0.82), "icon": "bone", "desc": "Ένα καθαρό κόκαλο σκελετού."},
	"rust": {"name": "Σκουριασμένη Λεπίδα", "price": 9, "color": Color(0.70, 0.45, 0.28), "icon": "sword", "desc": "Παλιό σίδερο· κάποιος θα το λιώσει."},
	"charm": {"name": "Φυλαχτό των Νεκρών", "price": 25, "color": Color(0.55, 0.95, 0.65), "icon": "star", "desc": "Λάμπει με ένα ψυχρό πράσινο φως."},
	# --- fish of the pond (fishing.gd). "zone" = share of the catch bar that counts as a hit, "speed" = bar widths
	# per second of the marker, "weight" = how often it bites, "only" = "day" or "night" (missing = always).
	"goby": {"name": "Γοβιός", "price": 6, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Μικρό και γρήγορο, ζει στα ρηχά.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"perch": {"name": "Πέρκα", "price": 8, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Ασημένια πέρκα με ριγέ πλευρές.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"sazani": {"name": "Σαζάνι", "price": 10, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Το άγριο σαζάνι της λίμνης.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"carp": {"name": "Κυπρίνος", "price": 12, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Χοντρός κυπρίνος· χορταίνει δύο.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"barbel": {"name": "Γριβάδι", "price": 14, "color": Color(0.75, 0.85, 0.95), "icon": "fish", "desc": "Γριβάδι με μουστάκια, αγαπά το ρεύμα.",
		"fish": true, "rarity": "common", "zone": 0.30, "speed": 0.70, "weight": 10.0},
	"trout": {"name": "Πέστροφα", "price": 20, "color": Color(0.45, 0.85, 0.55), "icon": "fish", "desc": "Πέστροφα με κόκκινα στίγματα, από τα πιο νόστιμα.",
		"fish": true, "rarity": "uncommon", "zone": 0.20, "speed": 0.95, "weight": 4.0},
	"eel": {"name": "Χέλι", "price": 25, "color": Color(0.45, 0.85, 0.55), "icon": "fish", "desc": "Γλιστερό χέλι, δύσκολο στο πιάσιμο.",
		"fish": true, "rarity": "uncommon", "zone": 0.20, "speed": 0.95, "weight": 4.0},
	"catfish": {"name": "Γλάνος", "price": 30, "color": Color(0.45, 0.85, 0.55), "icon": "fish", "desc": "Ο γλάνος: ένα τεράστιο ψάρι με μουστάκια.",
		"fish": true, "rarity": "uncommon", "zone": 0.20, "speed": 0.95, "weight": 4.0},
	"pike": {"name": "Λούτσος", "price": 35, "color": Color(0.45, 0.85, 0.55), "icon": "fish", "desc": "Λούτσος με μυτερά δόντια· ο κυνηγός της λίμνης.",
		"fish": true, "rarity": "uncommon", "zone": 0.20, "speed": 0.95, "weight": 4.0},
	"sunfish": {"name": "Ηλιόψαρο", "price": 50, "color": Color(0.45, 0.68, 1.0), "icon": "fish", "desc": "Λάμπει χρυσό στο φως της ημέρας. Τσιμπάει μόνο τη μέρα.",
		"fish": true, "rarity": "rare", "zone": 0.12, "speed": 1.20, "weight": 2.0, "only": "day"},
	"moonfish": {"name": "Φεγγαρόψαρο", "price": 55, "color": Color(0.45, 0.68, 1.0), "icon": "fish", "desc": "Ασημένιο και απαλό σαν το φεγγάρι. Τσιμπάει μόνο τη νύχτα.",
		"fish": true, "rarity": "rare", "zone": 0.12, "speed": 1.20, "weight": 2.0, "only": "night"},
	"goldfish": {"name": "Χρυσόψαρο του Αγίου", "price": 70, "color": Color(0.45, 0.68, 1.0), "icon": "fish", "desc": "Λένε πως φέρνει την ευλογία του Αγίου.",
		"fish": true, "rarity": "rare", "zone": 0.12, "speed": 1.20, "weight": 1.5},
	"king": {"name": "Ο Βασιλιάς της Λίμνης", "price": 150, "color": Color(1.0, 0.78, 0.30), "icon": "fish", "desc": "Ο γέρο-Γιάννης λέει πως τον είδε πριν πενήντα χρόνια.",
		"fish": true, "rarity": "legendary", "zone": 0.07, "speed": 1.60, "weight": 0.5},
}

const RARITY_ORDER: Array[String] = ["common", "uncommon", "rare", "legendary"]
## "3 συχνά ψάρια", "1 σπάνιο ψάρι": the adjective of each rarity, singular and plural.
const RARITY_ONE := {"common": "συχνό", "uncommon": "ασυνήθιστο", "rare": "σπάνιο", "legendary": "θρυλικό"}
const RARITY_MANY := {"common": "συχνά", "uncommon": "ασυνήθιστα", "rare": "σπάνια", "legendary": "θρυλικά"}

## Meals of the tavern kitchen. "tab" "buy" = paid with gold only, "cook" = made from fish. "cost" has the gold
## and, for cooked meals, {"fish": {rarity: count}}; the cheapest fish of the rarity is used. "mods" use the
## keys of stats.gd; the buff lasts "duration" seconds (a game day is 600 s).
const MEALS := {
	"fasolada": {
		"name": "Φασολάδα", "desc": "Η φασολάδα του Θανάση: ζεστή, χορταστική, με λάδι.", "tab": "buy", "duration": 600.0,
		"mods": {"hp_add": 30}, "cost": {"gold": 25},
	},
	"tyropita": {
		"name": "Τυρόπιτα", "desc": "Τραγανή τυρόπιτα με φύλλο, φρέσκια από τον φούρνο.", "tab": "buy", "duration": 600.0,
		"mods": {"speed_mult": 0.08}, "cost": {"gold": 30},
	},
	"kreas": {
		"name": "Κρέας με Πατάτες", "desc": "Χοιρινό με πατάτες στο φούρνο· δίνει δύναμη στο χέρι.", "tab": "buy", "duration": 600.0,
		"mods": {"damage_mult": 0.10}, "cost": {"gold": 40},
	},
	"fried": {
		"name": "Τηγανητά Ψαράκια", "desc": "Τηγανητά ψαράκια της λίμνης με λεμόνι.", "tab": "cook", "duration": 600.0,
		"mods": {"hp_add": 50, "regen": 1.0}, "cost": {"gold": 5, "fish": {"common": 3}},
	},
	"soup": {
		"name": "Ψαρόσουπα", "desc": "Ψαρόσουπα με λαχανικά· ζεσταίνει και θεραπεύει.", "tab": "cook", "duration": 600.0,
		"mods": {"hp_add": 80, "regen": 2.0, "defense": 0.05}, "cost": {"gold": 8, "fish": {"uncommon": 2}},
	},
	"grilled": {
		"name": "Ψητό του Αγίου", "desc": "Ψάρι ψημένο στα κάρβουνα, όπως το ψήνουν οι ψαράδες του Αγίου.", "tab": "cook", "duration": 600.0,
		"mods": {"damage_mult": 0.15, "crit": 0.10, "speed_mult": 0.10}, "cost": {"gold": 10, "fish": {"rare": 1}},
	},
	"feast": {
		"name": "Γιορτινό του Βασιλιά", "desc": "Το γιορτινό τραπέζι του Βασιλιά της Λίμνης. Θα το θυμάσαι για δεκαπέντε λεπτά.", "tab": "cook", "duration": 900.0,
		"mods": {"damage_mult": 0.20, "defense": 0.12, "hp_add": 100, "crit": 0.08, "lifesteal": 0.03},
		"cost": {"gold": 20, "fish": {"legendary": 1}},
	},
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
			{"type": "gear", "id": "weapon_5"}, {"type": "gear", "id": "weapon_6"}, {"type": "gear", "id": "weapon_7"},
			{"type": "gear", "id": "weapon_8"}, {"type": "gear", "id": "weapon_9"},
			{"type": "gear", "id": "armor_5"}, {"type": "gear", "id": "armor_6"}, {"type": "gear", "id": "armor_7"},
			{"type": "gear", "id": "armor_8"}, {"type": "gear", "id": "armor_9"},
			{"type": "gear", "id": "shield_5"}, {"type": "gear", "id": "shield_6"}, {"type": "gear", "id": "shield_7"},
			{"type": "gear", "id": "shield_8"}, {"type": "gear", "id": "shield_9"},
		],
		"buys": "gear",
	},
	# The stable: one item, the horse (see mount_rules.gd); no selling tab
	"stable": {
		"title": "Στάβλος",
		"keeper": "Μανώλης ο Ιπποκόμος",
		"kind": "stable",
		"greeting": [
			"Καλώς τον Γιώργο! Δες τι άλογο έχω εδώ. Με δαύτο θα διασχίζεις το νησί πριν προλάβει να κρυώσει ο καφές σου. Μόνο μην το βάλεις σε μάχη, είναι φοβιτσιάρικο!",
		],
		"stock": [
			{"type": "mount", "id": "horse", "price": MountRules.PRICE, "level": MountRules.MIN_LEVEL},
		],
		"buys": "",
	},
	# The tavern kitchen: no stock or selling, the window shows MEALS in two tabs (see shop_window.gd)
	"kitchen": {
		"title": "Κουζίνα",
		"keeper": "Θανάσης ο Μάγειρας",
		"kind": "kitchen",
		"greeting": [
			"Καλώς τον Γιώργο! Φασολάδα, τυρόπιτα, κρέας με πατάτες… Και αν μου φέρεις ψάρια από τη λίμνη, θα σου φτιάξω πιάτα που δεν έχεις ξαναφάει!",
		],
		"stock": [],
		"buys": "",
	},
}


static func gear_sell_price(id: String) -> int:
	return int(GEAR[id]["price"] * 0.4)


static func tier_color(id: String) -> Color:
	return TIER_COLORS[int(GEAR[id]["tier"]) - 1]


## Ids of all fish species, in the order of JUNK.
static func fish_ids() -> Array[String]:
	var out: Array[String] = []
	for id in JUNK:
		if JUNK[id].get("fish", false):
			out.append(id)
	return out


## Fish of one rarity, cheapest first.
static func fish_by_rarity(rarity: String) -> Array[String]:
	var out: Array[String] = []
	for id in fish_ids():
		if JUNK[id]["rarity"] == rarity:
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool: return int(JUNK[a]["price"]) < int(JUNK[b]["price"]))
	return out


## How many fish of a rarity are in the bag (junk: id -> count).
static func fish_have(junk: Dictionary, rarity: String) -> int:
	var n := 0
	for id in fish_by_rarity(rarity):
		n += int(junk.get(id, 0))
	return n


static func can_prepare(meal_id: String, gold: int, junk: Dictionary) -> bool:
	var cost: Dictionary = MEALS[meal_id]["cost"]
	if gold < int(cost["gold"]):
		return false
	var need: Dictionary = cost.get("fish", {})
	for rarity in need:
		if fish_have(junk, rarity) < int(need[rarity]):
			return false
	return true


## The fish a meal would use, cheapest first: {junk id: count}.
static func fish_to_use(meal_id: String, junk: Dictionary) -> Dictionary:
	var used := {}
	var need: Dictionary = MEALS[meal_id]["cost"].get("fish", {})
	for rarity in need:
		var left := int(need[rarity])
		for id in fish_by_rarity(rarity):
			if left <= 0:
				break
			var n := mini(left, int(junk.get(id, 0)))
			if n > 0:
				used[id] = int(used.get(id, 0)) + n
				left -= n
	return used


## "3 συχνά ψάρια (έχεις 2)" for the kitchen window.
static func fish_need_text(meal_id: String, junk: Dictionary) -> String:
	var parts: Array[String] = []
	var need: Dictionary = MEALS[meal_id]["cost"].get("fish", {})
	for rarity in need:
		var n := int(need[rarity])
		var word: String = RARITY_MANY[rarity] if n > 1 else RARITY_ONE[rarity]
		parts.append("%d %s %s (έχεις %d)" % [n, word, "ψάρια" if n > 1 else "ψάρι", fish_have(junk, rarity)])
	return ", ".join(parts)


## The Stats modifiers of the meal George is digesting ({} when none).
static func meal_mods(food: Dictionary) -> Dictionary:
	if food.is_empty():
		return {}
	return MEALS[food["id"]]["mods"]


## Modifiers of everything equipped: {key: value}.
static func equipment_mods(equipped: Dictionary) -> Dictionary:
	var out := {}
	for slot in SLOTS:
		var id: String = equipped.get(slot, "")
		if id != "":
			out = Stats.merge(out, GEAR[id]["mods"])
	return out
