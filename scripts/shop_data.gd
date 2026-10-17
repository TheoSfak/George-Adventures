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
	Color(1.0, 0.32, 0.08),
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
	"weapon_10": {
		"name": "Σπαθί της Αιώνιας Φλόγας", "slot": "weapon", "tier": 10, "level": 40, "price": 60000,
		"mods": {"damage_add": 125, "crit": 0.20, "lifesteal": 0.10, "attack_speed": 0.28},
		"desc": "Σφυρηλατημένο από τον Δαμιανό στη λάβα του Καταφυγίου. Καίει ό,τι αγγίζει.",
	},
	"weapon_2h_1": {
		"name": "Βαρύ Δίχειρο Σπαθί", "slot": "weapon", "weapon_type": "2h", "tier": 3, "level": 10, "price": 750,
		"mods": {"damage_add": 24, "crit": 0.08, "attack_speed": -0.04}, "desc": "Μακρύ δίχειρο σπαθί με σαρωτικό εύρος χτυπήματος.",
	},
	"weapon_2h_2": {
		"name": "Δίχειρο της Καταιγίδας", "slot": "weapon", "weapon_type": "2h", "tier": 6, "level": 25, "price": 8500,
		"mods": {"damage_add": 72, "crit": 0.16, "lifesteal": 0.06}, "desc": "Βαρύ δίχειρο σπαθί που συντρίβει πανοπλίες με ένα χτύπημα.",
	},
	"weapon_2h_3": {
		"name": "Τιτάνιο Δίχειρο της Φλόγας", "slot": "weapon", "weapon_type": "2h", "tier": 10, "level": 40, "price": 68000,
		"mods": {"damage_add": 175, "crit": 0.24, "lifesteal": 0.12}, "desc": "Κολοσσιαίο δίχειρο φτιαγμένο από ηφαιστειακό βασάλτη. Σαρώνει τα πάντα.",
	},
	"weapon_dual_1": {
		"name": "Δίδυμες Ατσαλένιες Λεπίδες", "slot": "weapon", "weapon_type": "dual", "tier": 2, "level": 5, "price": 280,
		"mods": {"damage_add": 7, "attack_speed": 0.14, "crit": 0.05}, "desc": "Ζευγάρι αιχμηρών λεπίδων για γρήγορα συνεχή χτυπήματα.",
	},
	"weapon_dual_2": {
		"name": "Δίδυμες Λεπίδες του Ανέμου", "slot": "weapon", "weapon_type": "dual", "tier": 5, "level": 20, "price": 4500,
		"mods": {"damage_add": 32, "attack_speed": 0.22, "crit": 0.12}, "desc": "Κινούνται τόσο γρήγορα που ο εχθρός βλέπει μόνο τον άνεμο.",
	},
	"weapon_dual_3": {
		"name": "Δίδυμα Σπαθιά της Στάχτης", "slot": "weapon", "weapon_type": "dual", "tier": 9, "level": 40, "price": 52000,
		"mods": {"damage_add": 95, "attack_speed": 0.35, "crit": 0.20, "lifesteal": 0.08}, "desc": "Δύο φλεγόμενες λεπίδες που κατακαίνε τους αντιπάλους σε μια θύελλα χτυπημάτων.",
	},
	"bow_1": {
		"name": "Κυνηγετικό Τόξο", "slot": "weapon", "weapon_type": "bow", "tier": 1, "level": 1, "price": 60,
		"mods": {"damage_add": 5, "crit": 0.04}, "desc": "Απλό ξύλινο τόξο από ξύλο καρυδιάς, κατάλληλο για αρχάριους τοξότες.",
	},
	"crossbow_1": {
		"name": "Ελαφριά Βαλλίστρα", "slot": "weapon", "weapon_type": "crossbow", "tier": 2, "level": 5, "price": 240,
		"mods": {"damage_add": 11, "crit": 0.06}, "desc": "Μηχανική βαλλίστρα με ατσάλινη σκανδάλη και γρήγορο όπλισμα.",
	},
	"bow_2": {
		"name": "Μακρύ Τόξο του Ιχνηλάτη", "slot": "weapon", "weapon_type": "bow", "tier": 3, "level": 10, "price": 650,
		"mods": {"damage_add": 18, "crit": 0.08, "attack_speed": 0.05}, "desc": "Βαθύ καμπυλωτό μακρύ τόξο των αρχαίων ιχνηλατών του νησιού.",
	},
	"crossbow_2": {
		"name": "Βαριά Πολεμική Βαλλίστρα", "slot": "weapon", "weapon_type": "crossbow", "tier": 4, "level": 15, "price": 1600,
		"mods": {"damage_add": 28, "crit": 0.10, "lifesteal": 0.03}, "desc": "Βαριά στρατιωτική βαλλίστρα που διαπερνά σιδερένιους θώρακες.",
	},
	"bow_3": {
		"name": "Τόξο της Αυγής", "slot": "weapon", "weapon_type": "bow", "tier": 5, "level": 20, "price": 3800,
		"mods": {"damage_add": 39, "crit": 0.12, "attack_speed": 0.08}, "desc": "Ευλογημένο με το πρώτο χρυσό φως της αυγής, τα βέλη του λάμπουν.",
	},
	"crossbow_3": {
		"name": "Βαλλίστρα της Καταιγίδας", "slot": "weapon", "weapon_type": "crossbow", "tier": 6, "level": 25, "price": 7500,
		"mods": {"damage_add": 52, "crit": 0.14, "lifesteal": 0.05}, "desc": "Εκτοξεύει βέλη φορτισμένα με την ορμή κεραυνού.",
	},
	"bow_4": {
		"name": "Τόξο του Ήλιου", "slot": "weapon", "weapon_type": "bow", "tier": 7, "level": 30, "price": 15000,
		"mods": {"damage_add": 66, "crit": 0.16, "attack_speed": 0.12}, "desc": "Χρυσό τόξο που πυρακτώνει τα βέλη κατά την πτήση.",
	},
	"bow_5": {
		"name": "Τόξο του Ουρανού", "slot": "weapon", "weapon_type": "bow", "tier": 8, "level": 35, "price": 28000,
		"mods": {"damage_add": 84, "crit": 0.18, "attack_speed": 0.15}, "desc": "Φτιαγμένο από ουράνιο μέταλλο, τα βέλη του σχίζουν τον αέρα αθόρυβα.",
	},
	"crossbow_4": {
		"name": "Ουράνια Βαλλίστρα των Αρχαγγέλων", "slot": "weapon", "weapon_type": "crossbow", "tier": 9, "level": 40, "price": 48000,
		"mods": {"damage_add": 105, "crit": 0.20, "lifesteal": 0.08}, "desc": "Ιερή βαλλίστρα των αρχαγγέλων που εξαπολύει ουράνια δικαιοσύνη.",
	},
	"bow_6": {
		"name": "Τόξο της Αιώνιας Φλόγας", "slot": "weapon", "weapon_type": "bow", "tier": 10, "level": 40, "price": 62000,
		"mods": {"damage_add": 130, "crit": 0.24, "lifesteal": 0.10, "attack_speed": 0.18}, "desc": "Σφυρηλατημένο από τον Δαμιανό με ηφαιστειακή στάχτη. Κάθε βέλος γίνεται πύρινη καταιγίδα.",
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
	"armor_10": {
		"name": "Πανοπλία της Αιώνιας Φλόγας", "slot": "armor", "tier": 10, "level": 40, "price": 60000,
		"mods": {"hp_add": 700, "defense": 0.48, "regen": 4.5},
		"desc": "Ηφαιστειακό μέταλλο με φλέβες λάβας που αποκρούει τη φωτιά και το σίδερο.",
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
	"shield_10": {
		"name": "Ασπίδα της Αιώνιας Φλόγας", "slot": "shield", "tier": 10, "level": 40, "price": 60000,
		"mods": {"block_add": 0.16, "defense": 0.20, "hp_add": 250},
		"desc": "Βαριά ασπίδα από βασάλτη και μάγμα· αντέχει ακόμη και το χτύπημα του Πυρφόρου.",
	},
	"weapon_orc_cleaver": {
		"name": "Ορκικός Μπαλτάς του Πολέμαρχου", "slot": "weapon", "weapon_type": "2h", "tier": 7, "level": 25, "price": 12000,
		"mods": {"damage_add": 78, "crit": 0.18, "lifesteal": 0.05, "attack_speed": -0.04},
		"desc": "Βαριά ορκική λεπίδα σφυρηλατημένη με θραύσματα από το φρούριο του Γκρομ'γκαρ. Συντρίβει οστά με απίστευτη δύναμη.",
	},
	"bow_wolf_stalker": {
		"name": "Τόξο του Κυνηγού των Λύκων", "slot": "weapon", "weapon_type": "bow", "tier": 6, "level": 22, "price": 8500,
		"mods": {"damage_add": 54, "crit": 0.18, "attack_speed": 0.15},
		"desc": "Εύκαμπτο και θανατηφόρο τόξο από καλάμια ποταμού και σκληρυμένα κόκαλα λύκων.",
	},
	"armor_corsair_mail": {
		"name": "Ενισχυμένος Θώρακας του Κουρσάρου", "slot": "armor", "tier": 7, "level": 25, "price": 14000,
		"mods": {"hp_add": 210, "defense": 0.28, "regen": 1.2},
		"desc": "Ατσάλινη πανοπλία με θαλασσινά καρφιά και ενισχυμένες πλάκες.",
	},
	"shield_bulwark": {
		"name": "Απόρθητο Προπύργιο των Κορυφών", "slot": "shield", "tier": 7, "level": 25, "price": 11000,
		"mods": {"block_add": 0.13, "defense": 0.16, "hp_add": 120},
		"desc": "Βαριά ασπίδα από σίδηρο και σκληρά πετρώματα των ορεινών πλαγιών.",
	},
	"armor_gladiator_champion": {
		"name": "Θώρακας του Πρωταθλητή των Μονομάχων", "slot": "armor", "tier": 10, "level": 38, "price": 35000,
		"mods": {"hp_add": 380, "defense": 0.25, "regen": 2.0},
		"desc": "Ο θρυλικός επίχρυσος θώρακας με τον πορφυρό μανδύα, που απονέμεται αποκλειστικά στον αδιαμφισβήτητο Πρωταθλητή της Αρένας του Αγίου Βλάση.",
	},
}

## Loot that only sells: dropped by skeletons, bought by the market.
const JUNK := {
	"bone": {"name": "Κόκαλο", "price": 3, "color": Color(0.92, 0.90, 0.82), "icon": "bone", "desc": "Ένα καθαρό κόκαλο σκελετού."},
	"rust": {"name": "Σκουριασμένη Λεπίδα", "price": 9, "color": Color(0.70, 0.45, 0.28), "icon": "sword", "desc": "Παλιό σίδερο· κάποιος θα το λιώσει."},
	"charm": {"name": "Φυλαχτό των Νεκρών", "price": 25, "color": Color(0.55, 0.95, 0.65), "icon": "star", "desc": "Λάμπει με ένα ψυχρό πράσινο φως."},
	"bone_shard": {"name": "Θραύσμα Οστού", "price": 8, "color": Color(0.90, 0.88, 0.82), "icon": "bone", "desc": "Σκληρό οστό κατάλληλο για ενίσχυση εξοπλισμού.", "material": true},
	"iron_scrap": {"name": "Κομμάτι Σιδήρου", "price": 18, "color": Color(0.72, 0.74, 0.80), "icon": "sword", "desc": "Ακατέργαστο σίδερο για σφυρηλάτηση και ενίσχυση.", "material": true},
	"lava_ember": {"name": "Αναμμένο Κάρβουνο", "price": 45, "color": Color(1.0, 0.45, 0.12), "icon": "star", "desc": "Ηφαιστειακό κάρβουνο που πάλλεται με μαγική θερμότητα.", "material": true},
	"trophy_arena_bronze": {"name": "Χάλκινο Έπαθλο Μονομάχου", "price": 100, "color": Color(0.85, 0.55, 0.30), "icon": "star", "desc": "Αναμνηστικό έπαθλο από τη νίκη στη Χάλκινη Δοκιμασία της Αρένας.", "trophy": true},
	"trophy_arena_silver": {"name": "Ασημένιο Έπαθλο Μονομάχου", "price": 250, "color": Color(0.85, 0.90, 0.95), "icon": "star", "desc": "Αναμνηστικό έπαθλο από τη νίκη στην Ασημένια Δοκιμασία της Αρένας.", "trophy": true},
	"trophy_arena_gold": {"name": "Χρυσό Έπαθλο Μονομάχου", "price": 500, "color": Color(1.0, 0.85, 0.25), "icon": "star", "desc": "Αναμνηστικό έπαθλο από τη νίκη στη Χρυσή Δοκιμασία της Αρένας.", "trophy": true},
	"trophy_arena_heroic": {"name": "Ηρωικό Έπαθλο Μονομάχου", "price": 1000, "color": Color(0.75, 0.35, 0.95), "icon": "star", "desc": "Αναμνηστικό έπαθλο από τη νίκη στην Ηρωική Δοκιμασία της Αρένας.", "trophy": true},
	"trophy_arena_mythic": {"name": "Μυθικό Έπαθλο Υπέρτατου Πρωταθλητή", "price": 2500, "color": Color(1.0, 0.30, 0.15), "icon": "star", "desc": "Το υπέρτατο δάφνινο στεφάνι του Αδιαμφισβήτητου Πρωταθλητή του Αγίου Βλάση.", "trophy": true},
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
	# --- Wild Flora Reagents for Alchemy & Herb Brewing ---
	"waterlily": {"name": "Άγριο Νούφαρο", "price": 12, "color": Color(0.40, 0.90, 0.95), "icon": "star",
		"desc": "Λευκό νούφαρο που επιπλέει στα ρηχά νερά της λίμνης και της νότιας θάλασσας. Βασικό για δροσιστικά έλαια.", "material": true},
	"reed": {"name": "Καλάμι του Ποταμού", "price": 8, "color": Color(0.55, 0.85, 0.35), "icon": "arrow",
		"desc": "Ανθεκτικό καλάμι από τις όχθες του ποταμού. Περιέχει εκχυλίσματα για δηλητηριώδεις επικαλύψεις.", "material": true},
	"mountain_herb": {"name": "Ορεινό Βότανο", "price": 15, "color": Color(0.85, 0.50, 0.95), "icon": "potion",
		"desc": "Αρωματικό βότανο των ψηλών βράχων και των ερειπίων. Χαρίζει αντοχή και δύναμη πέτρινης σάρκας.", "material": true},
	"autumn_cone": {"name": "Χρυσαφένιο Κουκουνάρι", "price": 10, "color": Color(0.95, 0.65, 0.20), "icon": "sun",
		"desc": "Κουκουνάρι από τα πεύκα του Χρυσού Άλσους. Εκλύει θερμή ρητίνη απαραίτητη για έλαια φλόγας.", "material": true},
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

## Alchemy brewing recipes crafted at Andreas' alchemy bench in the village square.
## Reagents gathered from wild flora across the island (waterlilies, reeds, mountain herbs, autumn cones).
const ALCHEMY_RECIPES := {
	"flame_oil": {
		"name": "Έλαιο Φλόγας",
		"category": "coating",
		"icon": "flame",
		"color": Color(1.0, 0.45, 0.15),
		"desc": "Επικάλυψη όπλου: προσθέτει +8 ζημιά φωτιάς σε κάθε χτύπημα για 5 λεπτά.",
		"duration": 300.0,
		"coating_type": "flame_oil",
		"coating_damage": 8.0,
		"cost": {"gold": 15, "ingredients": {"mountain_herb": 1, "autumn_cone": 1}},
	},
	"poison_coat": {
		"name": "Δηλητηριώδης Επικάλυψη",
		"category": "coating",
		"icon": "potion",
		"color": Color(0.40, 0.90, 0.35),
		"desc": "Επικάλυψη όπλου: προκαλεί συνεχή ζημιά δηλητηρίου στους εχθρούς (+5 ζημιά) για 5 λεπτά.",
		"duration": 300.0,
		"coating_type": "poison_coat",
		"coating_damage": 5.0,
		"cost": {"gold": 20, "ingredients": {"reed": 2, "waterlily": 1}},
	},
	"frost_ward": {
		"name": "Έλαιο Παγετού & Προστασίας",
		"category": "coating",
		"icon": "shield",
		"color": Color(0.45, 0.85, 1.0),
		"desc": "Ψυχρή επάλειψη λεπίδας: επιβραδύνει τους εχθρούς και ενισχύει την άμυνα κατά +15% για 5 λεπτά.",
		"duration": 300.0,
		"coating_type": "frost_ward",
		"coating_damage": 6.0,
		"mods": {"defense": 0.15},
		"cost": {"gold": 25, "ingredients": {"waterlily": 2, "autumn_cone": 1}},
	},
	"elixir_stone": {
		"name": "Ελιξίριο Πέτρινης Σάρκας",
		"category": "elixir",
		"icon": "tower",
		"color": Color(0.85, 0.75, 0.55),
		"desc": "Πυκνό αφέψημα που σκληραίνει το σώμα: +60 μέγιστη υγεία και +2.0 αναγέννηση ζωής/δευτερόλεπτο για 8 λεπτά.",
		"duration": 480.0,
		"mods": {"hp_add": 60, "regen": 2.0},
		"cost": {"gold": 30, "ingredients": {"mountain_herb": 2, "reed": 1}},
	},
	"elixir_swiftness": {
		"name": "Ελιξίριο Ανεμοστρόβιλου",
		"category": "elixir",
		"icon": "whirl",
		"color": Color(0.40, 0.95, 0.85),
		"desc": "Ελαφρύ ελιξίριο από νούφαρα και καλάμια: +20% ταχύτητα κίνησης και κολύμβησης για 8 λεπτά.",
		"duration": 480.0,
		"mods": {"speed_mult": 0.20},
		"cost": {"gold": 30, "ingredients": {"waterlily": 1, "reed": 2, "mountain_herb": 1}},
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
			{"type": "gear", "id": "weapon_dual_1"},
			{"type": "gear", "id": "weapon_3"}, {"type": "gear", "id": "weapon_2h_1"}, {"type": "gear", "id": "weapon_4"},
			{"type": "gear", "id": "armor_1"}, {"type": "gear", "id": "armor_2"},
			{"type": "gear", "id": "armor_3"}, {"type": "gear", "id": "armor_4"},
			{"type": "gear", "id": "shield_1"}, {"type": "gear", "id": "shield_2"},
			{"type": "gear", "id": "shield_3"}, {"type": "gear", "id": "shield_4"},
			{"type": "gear", "id": "weapon_5"}, {"type": "gear", "id": "weapon_dual_2"},
			{"type": "gear", "id": "weapon_6"}, {"type": "gear", "id": "weapon_2h_2"},
			{"type": "gear", "id": "weapon_7"},
			{"type": "gear", "id": "weapon_8"}, {"type": "gear", "id": "weapon_9"},
			{"type": "gear", "id": "weapon_dual_3"},
			{"type": "gear", "id": "armor_5"}, {"type": "gear", "id": "armor_6"}, {"type": "gear", "id": "armor_7"},
			{"type": "gear", "id": "armor_8"}, {"type": "gear", "id": "armor_9"},
			{"type": "gear", "id": "shield_5"}, {"type": "gear", "id": "shield_6"}, {"type": "gear", "id": "shield_7"},
			{"type": "gear", "id": "shield_8"}, {"type": "gear", "id": "shield_9"},
		],
		"buys": "gear",
	},
	"blacksmith_forge": {
		"title": "Αμόνι & Καμίνι του Νικήτα",
		"keeper": "Σιδηρουργείο του Νικήτα",
		"kind": "forge",
		"greeting": [
			"Το αμόνι καίει και το ατσάλι περιμένει! Ενίσχυσε τα όπλα σου ή σφυρηλάτησε θρυλικό εξοπλισμό από τα λάφυρα των μαχών.",
		],
		"stock": [],
		"buys": "gear",
	},
	"archery": {
		"title": "Οπλοστάσιο Τοξοβολίας",
		"keeper": "Δημήτρης ο Τοξότης",
		"greeting": [
			"Καλώς όρισες στο πεδίο τοξοβολίας, Γιώργο! Ένα καλό τόξο κι ένα κοφτερό μάτι σώζουν ζωές πριν καν πλησιάσει ο εχθρός.",
		],
		"stock": [
			{"type": "gear", "id": "bow_1"},
			{"type": "gear", "id": "crossbow_1"},
			{"type": "gear", "id": "bow_2"},
			{"type": "gear", "id": "crossbow_2"},
			{"type": "gear", "id": "bow_3"},
			{"type": "gear", "id": "crossbow_3"},
			{"type": "gear", "id": "bow_4"},
			{"type": "gear", "id": "bow_5"},
			{"type": "gear", "id": "crossbow_4"},
			{"type": "gear", "id": "bow_6"},
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
	# Damianos' forge at the Shelter in the Ash Valley
	"ash_forge": {
		"title": "Σιδηρουργείο της Στάχτης",
		"keeper": "Δαμιανός ο Σιδεράς",
		"greeting": [
			"Αν σπάσει ο οπλισμός σου, φέρ' τον εδώ. Έχω ακόμα κάρβουνο για ένα καλό σφυρί.",
		],
		"stock": [
			{"type": "gear", "id": "weapon_10"},
			{"type": "gear", "id": "weapon_2h_3"},
			{"type": "gear", "id": "armor_10"},
			{"type": "gear", "id": "shield_10"},
			{"type": "item", "id": "health_big", "price": 85},
			{"type": "item", "id": "power", "price": 75},
			{"type": "item", "id": "speed", "price": 60},
		],
		"buys": "gear",
	},
	# Andreas' herbs and provisions in the village square after rescue
	"andreas_herbs": {
		"title": "Βότανα & Προμήθειες",
		"keeper": "Αντρέας",
		"greeting": [
			"Γεια σου, σωτήρα μου Γιώργο! Μάζεψα αυτά τα φρέσκα βότανα και έφτιαξα γιατρικά. Για σένα, πάντα στις καλύτερες τιμές!",
		],
		"stock": [
			{"type": "item", "id": "health", "price": 18},
			{"type": "item", "id": "health_big", "price": 55, "level": 8},
			{"type": "item", "id": "power", "price": 45},
			{"type": "item", "id": "speed", "price": 35},
		],
		"buys": "junk",
	},
	# Andreas' alchemy bench in the village square
	"andreas_alchemy": {
		"title": "Πάγκος Αλχημείας του Αντρέα",
		"keeper": "Αντρέας",
		"kind": "alchemy",
		"greeting": [
			"Καλώς όρισες στον πάγκο αλχημείας, Γιώργο! Με τα σπάνια αγριολούλουδα του νησιού μπορούμε να παρασκευάσουμε ισχυρά έλαια λεπίδας και ελιξίρια!",
		],
		"stock": [],
		"buys": "junk",
	},
	# Traveling merchant wandering the island
	"wandering": {
		"title": "Πλανόδιος Έμπορος",
		"keeper": "Κυρ-Παντελής",
		"greeting": [
			"Καλώς τον άξιο πολεμιστή! Έχω σπάνια υλικά για σφυρηλάτηση, γιατρικά και περίεργα καλούδια από τα ταξίδια μου!",
		],
		"stock": [
			{"type": "junk", "id": "iron_scrap", "price": 28},
			{"type": "junk", "id": "bone_shard", "price": 15},
			{"type": "junk", "id": "lava_ember", "price": 75},
			{"type": "gear", "id": "weapon_dual_2"},
			{"type": "gear", "id": "weapon_2h_2"},
			{"type": "item", "id": "health_big", "price": 60, "level": 5},
			{"type": "item", "id": "power", "price": 50},
			{"type": "item", "id": "speed", "price": 40},
		],
		"buys": "junk",
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


## Returns tier (1..10) if weapon, armor and shield are all equipped and share the same tier (>= 2). Otherwise 0.
static func set_tier(equipped: Dictionary) -> int:
	var w: String = equipped.get("weapon", "")
	var a: String = equipped.get("armor", "")
	var s: String = equipped.get("shield", "")
	if w == "" or a == "" or s == "":
		return 0
	if not GEAR.has(w) or not GEAR.has(a) or not GEAR.has(s):
		return 0
	var tw: int = int(GEAR[w]["tier"])
	var ta: int = int(GEAR[a]["tier"])
	var ts: int = int(GEAR[s]["tier"])
	if tw == ta and ta == ts and tw >= 2:
		return tw
	return 0


## Greek name for each matching gear tier set.
static func set_bonus_name(tier: int) -> String:
	match tier:
		2: return "Σετ Ατσαλιού"
		3: return "Σετ του Αγίου"
		4: return "Βασιλικό Σετ"
		5: return "Σετ του Σταυροφόρου"
		6: return "Σετ του Μυθικού Ατσαλιού"
		7: return "Σετ του Δρακοκτόνου"
		8: return "Σετ του Φωτός"
		9: return "Σετ των Τιτάνων"
		10: return "Σετ της Αιώνιας Φλόγας"
		_: return "Σετ Εξοπλισμού"


## Modifiers granted by a full matching gear set of tier >= 2.
static func set_bonus_mods(tier: int) -> Dictionary:
	if tier < 2:
		return {}
	return {
		"hp_add": 20.0 * float(tier),
		"defense": 0.04 + 0.006 * float(tier),
		"damage_mult": 0.04 + 0.006 * float(tier),
	}


# --- Equipment Upgrades (Crafting) ---
const MAX_UPGRADE_LEVEL := 5

const UPGRADE_COSTS := {
	1: {"gold": 120, "material": "iron_scrap", "count": 2},
	2: {"gold": 350, "material": "bone_shard", "count": 3},
	3: {"gold": 800, "material": "lava_ember", "count": 2},
	4: {"gold": 1600, "material": "mountain_herb", "count": 4},
	5: {"gold": 3200, "material": "lava_ember", "count": 5},
}

static func weapon_type(id: String) -> String:
	return GEAR.get(id, {}).get("weapon_type", "1h")

static func upgrade_mods(slot: String, level: int) -> Dictionary:
	if level <= 0:
		return {}
	level = mini(level, MAX_UPGRADE_LEVEL)
	match slot:
		"weapon":
			return {
				"damage_mult": 0.12 * float(level),
				"crit": 0.02 * float(level),
				"attack_speed": 0.02 * float(level),
			}
		"armor":
			return {
				"hp_add": 50.0 * float(level),
				"defense": 0.04 * float(level),
				"regen": 0.3 * float(level),
			}
		"shield":
			return {
				"hp_add": 30.0 * float(level),
				"block_add": 0.03 * float(level),
				"defense": 0.03 * float(level),
			}
	return {}

static func total_upgrade_mods(upgrades: Dictionary) -> Dictionary:
	var out := {}
	for slot in SLOTS:
		var lvl: int = int(upgrades.get(slot, 0))
		if lvl > 0:
			out = Stats.merge(out, upgrade_mods(slot, lvl))
	return out

static func can_upgrade_slot(slot: String, current_level: int, gold: int, junk: Dictionary) -> bool:
	if current_level >= MAX_UPGRADE_LEVEL:
		return false
	var next_lvl := current_level + 1
	var cost: Dictionary = UPGRADE_COSTS[next_lvl]
	if gold < int(cost["gold"]):
		return false
	var mat: String = cost["material"]
	if int(junk.get(mat, 0)) < int(cost["count"]):
		return false
	return true


# --- Special Forging Recipes (Monster Drops & Island Minerals) ---
const FORGE_RECIPES := {
	"forge_orc_cleaver": {
		"id": "forge_orc_cleaver",
		"gear_id": "weapon_orc_cleaver",
		"name": "Ορκικός Μπαλτάς του Πολέμαρχου",
		"slot": "weapon",
		"icon": "sword",
		"tier": 7,
		"level": 25,
		"cost": {
			"gold": 1200,
			"ingredients": {
				"iron_scrap": 10,
				"bone_shard": 8,
			}
		},
		"desc": "Βαριά ορκική λεπίδα σφυρηλατημένη με θραύσματα από το φρούριο του Γκρομ'γκαρ. Συντρίβει οστά με απίστευτη δύναμη.",
	},
	"forge_wolf_bow": {
		"id": "forge_wolf_bow",
		"gear_id": "bow_wolf_stalker",
		"name": "Τόξο του Κυνηγού των Λύκων",
		"slot": "weapon",
		"icon": "arrow",
		"tier": 6,
		"level": 22,
		"cost": {
			"gold": 950,
			"ingredients": {
				"reed": 8,
				"bone_shard": 6,
				"iron_scrap": 4,
			}
		},
		"desc": "Εύκαμπτο και θανατηφόρο τόξο από καλάμια ποταμού και σκληρυμένα κόκαλα λύκων. Εξαιρετική ταχύτητα και κρίσιμα χτυπήματα.",
	},
	"forge_corsair_mail": {
		"id": "forge_corsair_mail",
		"gear_id": "armor_corsair_mail",
		"name": "Ενισχυμένος Θώρακας του Κουρσάρου",
		"slot": "armor",
		"icon": "armor",
		"tier": 7,
		"level": 25,
		"cost": {
			"gold": 1400,
			"ingredients": {
				"iron_scrap": 12,
				"waterlily": 6,
				"mountain_herb": 5,
			}
		},
		"desc": "Ατσάλινη πανοπλία με θαλασσινά καρφιά και ενισχυμένες πλάκες. Προστατεύει από τα πιο σφοδρά χτυπήματα.",
	},
	"forge_bulwark": {
		"id": "forge_bulwark",
		"gear_id": "shield_bulwark",
		"name": "Απόρθητο Προπύργιο των Κορυφών",
		"slot": "shield",
		"icon": "shield",
		"tier": 7,
		"level": 25,
		"cost": {
			"gold": 1100,
			"ingredients": {
				"iron_scrap": 8,
				"mountain_herb": 6,
				"autumn_cone": 4,
			}
		},
		"desc": "Βαριά ασπίδα από σίδηρο και σκληρά πετρώματα των ορεινών πλαγιών. Καμία λόγχη δεν την τρυπά.",
	},
}

static func can_forge(recipe_id: String, gold: int, junk: Dictionary, gear_owned: Array) -> bool:
	if not FORGE_RECIPES.has(recipe_id):
		return false
	var recipe: Dictionary = FORGE_RECIPES[recipe_id]
	var gear_id: String = recipe.get("gear_id", "")
	if gear_owned.has(gear_id):
		return false
	var cost: Dictionary = recipe.get("cost", {})
	if gold < int(cost.get("gold", 0)):
		return false
	var ingredients: Dictionary = cost.get("ingredients", {})
	for ing in ingredients:
		var needed: int = int(ingredients[ing])
		if int(junk.get(ing, 0)) < needed:
			return false
	return true

static func forge_recipe(recipe_id: String, player: Player) -> bool:
	if not FORGE_RECIPES.has(recipe_id) or player == null:
		return false
	var recipe: Dictionary = FORGE_RECIPES[recipe_id]
	var gear_id: String = recipe.get("gear_id", "")
	if not can_forge(recipe_id, player.gold, player.junk, player.gear_owned):
		return false
	var cost: Dictionary = recipe.get("cost", {})
	var gold_cost: int = int(cost.get("gold", 0))
	player.gold -= gold_cost
	var ingredients: Dictionary = cost.get("ingredients", {})
	for ing in ingredients:
		var needed: int = int(ingredients[ing])
		player.junk[ing] = int(player.junk.get(ing, 0)) - needed
		if int(player.junk[ing]) <= 0:
			player.junk.erase(ing)

	player.gear_owned.append(gear_id)
	player.inventory_changed.emit(player.gold, player.potions)
	player.gear_changed.emit()
	return true



static func can_brew(recipe_id: String, gold: int, junk: Dictionary) -> bool:
	if not ALCHEMY_RECIPES.has(recipe_id):
		return false
	var recipe: Dictionary = ALCHEMY_RECIPES[recipe_id]
	var cost: Dictionary = recipe.get("cost", {})
	if gold < int(cost.get("gold", 0)):
		return false
	var ingredients: Dictionary = cost.get("ingredients", {})
	for ing in ingredients:
		var needed: int = int(ingredients[ing])
		if int(junk.get(ing, 0)) < needed:
			return false
	return true


static func brew_recipe(recipe_id: String, player: Player) -> bool:
	if not ALCHEMY_RECIPES.has(recipe_id) or player == null:
		return false
	var recipe: Dictionary = ALCHEMY_RECIPES[recipe_id]
	if not can_brew(recipe_id, player.gold, player.junk):
		return false
	var cost: Dictionary = recipe.get("cost", {})
	var gold_cost: int = int(cost.get("gold", 0))
	player.gold -= gold_cost
	var ingredients: Dictionary = cost.get("ingredients", {})
	for ing in ingredients:
		var needed: int = int(ingredients[ing])
		player.junk[ing] = int(player.junk.get(ing, 0)) - needed
		if int(player.junk[ing]) <= 0:
			player.junk.erase(ing)

	var duration: float = float(recipe.get("duration", 300.0))
	var cat: String = recipe.get("category", "")
	if cat == "coating":
		var c_type: String = recipe.get("coating_type", recipe_id)
		var c_dmg: float = float(recipe.get("coating_damage", 6.0))
		var mods: Dictionary = recipe.get("mods", {})
		player.apply_blade_coating(c_type, duration, c_dmg, mods)
	elif cat == "elixir":
		var mods: Dictionary = recipe.get("mods", {})
		player.apply_elixir(recipe_id, duration, mods)

	player.inventory_changed.emit(player.gold, player.potions)
	return true

