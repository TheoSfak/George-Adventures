class_name BestiaryData
extends RefCounted
## Comprehensive Bestiary (Τερατολόγιο) data definitions for George Adventures.
## Contains 40+ creatures categorized by faction, complete with Greek lore,
## tactical weaknesses, combat stats, loot drop tables, and 3D preview configurations.

const CATEGORIES := {
	"all": "Όλα τα Πλάσματα",
	"skeletons": "💀 Οστέινος Στρατός",
	"orcs": "🪓 Φυλή των Όρκ",
	"bandits": "🏴‍☠️ Ληστές & Κουρσάροι",
	"ash_valley": "🌋 Πλάσματα της Στάχτης",
	"beasts": "🐺 Άγρια Θηρία & Σκιές",
	"arena": "🏟️ Μονομάχοι Αρένας",
}

const TIER_UNKNOWN := 0
const TIER_DISCOVERED := 1
const TIER_STUDIED := 2
const TIER_MASTERED := 3

const ENTRIES: Array[Dictionary] = [
	# -------------------------------------------------------------------------
	# 1. Οστέινος Στρατός (Skeletons & Undead)
	# -------------------------------------------------------------------------
	{
		"kind_id": "minion",
		"name": "Σκελετός Υπηρέτης",
		"category": "skeletons",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Minion.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Axe.gltf",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Εύθραυστοι αλλά πολυάριθμοι σκελετοί που αναστήθηκαν από τη σκοτεινή κατάρα της αρχαίας κρύπτης. Κινούνται σε ομάδες και κραδαίνουν σκουριασμένους πελέκεις, αναζητώντας ζωντανή σάρκα στα περίχωρα του Αγίου Βλάση.",
		"weakness": "Ευάλωτοι σε βαριά χτυπήματα και περιστροφικές επιθέσεις (Whirlwind). Η χαμηλή τους ζωή τους καθιστά εύκολους στόχους για γρήγορους συνδυασμούς πληγμάτων.",
		"stats": {"hp": 28, "damage": 8, "speed": 5.0, "style": "Εγγύς Μάχη (Τσεκούρι)", "defense": "Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (1-4)", "chance": "100%"},
			{"item": "Θραύσμα Οστών", "chance": "42%"},
			{"item": "Σκουριασμένο Σίδερο", "chance": "16%"},
			{"item": "Φίλτρο Υγείας", "chance": "20%"}
		]
	},
	{
		"kind_id": "warrior",
		"name": "Σκελετός Πολεμιστής",
		"category": "skeletons",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Small_A.gltf",
		"model_scale": 1.0,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Παλαιοί φρουροί του βασιλείου που έπεσαν στη μάχη πριν από αιώνες. Φέρουν κοφτερά σπαθιά και μικρές ασπίδες, διατηρώντας ακόμη τις βασικές πολεμικές τους συνήθειες.",
		"weakness": "Μπλοκάρουν μετωπικά χτυπήματα. Χρησιμοποίησε κλωτσιά (C) για να σπάσεις τη στάση τους ή κύλισε πίσω τους (V) για κρίσιμα χτυπήματα στην πλάτη.",
		"stats": {"hp": 45, "damage": 12, "speed": 4.2, "style": "Σπαθί & Ασπίδα", "defense": "Μέτρια"},
		"drops": [
			{"item": "Χρυσός (3-9)", "chance": "100%"},
			{"item": "Θραύσμα Οστών", "chance": "42%"},
			{"item": "Κομμάτι Σιδήρου", "chance": "25%"},
			{"item": "Φίλτρο Υγείας", "chance": "35%"}
		]
	},
	{
		"kind_id": "rogue",
		"name": "Σκελετός Τοξότης",
		"category": "skeletons",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Rogue.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Crossbow.gltf",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0.35, 0.8, 0.3, 0.22),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Υπούλοι σκοπευτές που παραμονεύουν ανάμεσα στα δέντρα και τα βράχια. Εκτοξεύουν αθόρυβα φαρμακερά βέλη από απόσταση, προσπαθώντας να διατηρούν συνεχή απόσταση ασφαλείας.",
		"weakness": "Εξαιρετικά ευάλωτοι μόλις κλείσεις την απόσταση. Χρησιμοποίησε Dash ή δικό σου τόξο για να διακόψεις τον πυροβολισμό τους.",
		"stats": {"hp": 26, "damage": 9, "speed": 4.6, "style": "Βαλλίστρα Εξ Αποστάσεως", "defense": "Πολύ Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (2-6)", "chance": "100%"},
			{"item": "Θραύσμα Οστών", "chance": "42%"},
			{"item": "Φίλτρο Υγείας", "chance": "25%"}
		]
	},
	{
		"kind_id": "mage",
		"name": "Σκελετός Μάγος",
		"category": "skeletons",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Mage.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Staff.gltf",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0.55, 0.35, 0.95, 0.28),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Αρχαίοι νεκρομάντεις που συνεχίζουν να αντλούν ενέργεια από το υπερπέραν. Εξαπολύουν αργές αλλά καταστροφικές σφαίρες σκοτεινής μαγείας που προκαλούν μεγάλη ζημιά αν δεν αποφευχθούν.",
		"weakness": "Οι μαγικές τους σφαίρες κινούνται αργά και μπορούν εύκολα να αποφευχθούν με πλευρική κίνηση ή κύλιση (V). Στο κοντινό melee είναι εντελώς ανυπεράσπιστοι.",
		"stats": {"hp": 24, "damage": 14, "speed": 3.8, "style": "Σκοτεινή Μαγεία", "defense": "Ελάχιστη"},
		"drops": [
			{"item": "Χρυσός (3-8)", "chance": "100%"},
			{"item": "Μαγικό Φυλαχτό", "chance": "15%"},
			{"item": "Φίλτρο Υγείας", "chance": "30%"}
		]
	},
	{
		"kind_id": "brute",
		"name": "Σκελετός Βάρβαρος",
		"category": "skeletons",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Axe.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Large_A.gltf",
		"model_scale": 1.4,
		"tint_color": Color(0.75, 0.15, 0.12, 0.30),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Επιβλητικοί οστέινοι γίγαντες με τεράστιους πελέκεις και βαριές ασπίδες. Τα χτυπήματά τους μπορούν να σπάσουν την άμυνα ακόμα και του πιο έμπειρου ιππότη.",
		"weakness": "Αργός χρόνος προετοιμασίας επιθέσεων (windup). Απόφυγε το βαρύ χτύπημα με κύλιση και ανταπόδωσε με ταχύτατες αντεπιθέσεις.",
		"stats": {"hp": 130, "damage": 22, "speed": 3.3, "style": "Βαρύς Πέλεκυς & Ασπίδα", "defense": "Υψηλή"},
		"drops": [
			{"item": "Χρυσός (8-18)", "chance": "100%"},
			{"item": "Κομμάτι Σιδήρου", "chance": "45%"},
			{"item": "Θραύσμα Οστών", "chance": "70%"},
			{"item": "Φίλτρο Υγείας", "chance": "50%"}
		]
	},
	{
		"kind_id": "captain",
		"name": "Λοχαγός των Νεκρών",
		"category": "skeletons",
		"is_boss": true,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Small_A.gltf",
		"model_scale": 1.6,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο διοικητής του οστέινου αποσπάσματος που κατέλαβε το παλιό λατομείο του Αγίου Βλάση. Επιθετικός, ασταμάτητος και αποφασισμένος να συντρίψει όποιον πλησιάσει τα λάφυρά του.",
		"weakness": "Κράτησε την ασπίδα σηκωμένη (K) για να απορροφήσεις το combo του και αντεπίτεθε με Shield Bash. Ευάλωτος σε δεξιότητες κεραυνού.",
		"stats": {"hp": 220, "damage": 18, "speed": 4.3, "style": "Πολεμικό Σπαθί & Ασπίδα", "defense": "Βαριά"},
		"drops": [
			{"item": "Χρυσός (40-60)", "chance": "100%"},
			{"item": "Μαγικό Φυλαχτό", "chance": "100%"},
			{"item": "Φίλτρο Δύναμης", "chance": "100%"},
			{"item": "Φίλτρο Ταχύτητας", "chance": "100%"}
		]
	},
	{
		"kind_id": "king",
		"name": "Βασιλιάς των Οστών",
		"category": "skeletons",
		"is_boss": true,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Small_A.gltf",
		"model_scale": 2.3,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο αρχαίος ηγεμόνας της κρύπτης, του οποίου η αφύπνιση σκόρπισε τον τρόμο στο χωριό. Το πελώριο ανάστημά του και η άσβεστη δίψα του για κυριαρχία τον καθιστούν έναν από τους πιο θρυλικούς εχθρούς του νησιού.",
		"weakness": "Η μεγάλη εμβέλεια των χτυπημάτων του απαιτεί προσεκτικό συγχρονισμό κύλισης. Εκμεταλλεύσου την καθυστέρηση μετά το βαρύ χτύπημα εδάφους για πλήρη combo.",
		"stats": {"hp": 520, "damage": 26, "speed": 4.4, "style": "Βασιλική Σπάθη", "defense": "Επική"},
		"drops": [
			{"item": "Χρυσός (100-140)", "chance": "100%"},
			{"item": "Μαγικό Φυλαχτό", "chance": "100%"},
			{"item": "Φίλτρο Δύναμης", "chance": "100%"},
			{"item": "Φίλτρο Υγείας x2", "chance": "100%"}
		]
	},

	# -------------------------------------------------------------------------
	# 2. Φυλή των Όρκ (Orc Warband)
	# -------------------------------------------------------------------------
	{
		"kind_id": "orc_warrior",
		"name": "Ορκ Πολεμιστής",
		"category": "orcs",
		"is_boss": false,
		"model_path": "res://assets/characters/Orc.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 0.78,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "CharacterArmature|Idle",
		"lore": "Άγριοι και μυώδεις πολεμιστές της πολεμικής ορδής που έχουν οχυρωθεί στο Ερειπωμένο Κάστρο. Επιτίθενται με μανία και δεν γνωρίζουν τι σημαίνει υποχώρηση.",
		"weakness": "Ευάλωτοι σε αντεπιθέσεις μετά από αποτυχημένη επίθεσή τους. Η τοξοβολία και το Power Shot προκαλούν επιπλέον stagger.",
		"stats": {"hp": 85, "damage": 16, "speed": 4.5, "style": "Βαρύς Πέλεκυς", "defense": "Μέτρια-Βαριά"},
		"drops": [
			{"item": "Χρυσός (6-14)", "chance": "100%"},
			{"item": "Κομμάτι Σιδήρου", "chance": "35%"},
			{"item": "Θραύσμα Οστών", "chance": "30%"},
			{"item": "Φίλτρο Υγείας", "chance": "35%"}
		]
	},
	{
		"kind_id": "orc_berserker",
		"name": "Ορκ Berserker",
		"category": "orcs",
		"is_boss": false,
		"model_path": "res://assets/characters/Orc.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 0.88,
		"tint_color": Color(0.85, 0.20, 0.10, 0.25),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "CharacterArmature|Idle",
		"lore": "Αιμοδιψείς γίγαντες των Ορκ που μάχονται με γυμνές γροθιές και αλυσίδες. Όταν πληγωθούν, η ταχύτητά τους αυξάνεται δραματικά λόγω ανεξέλεγκτης οργής.",
		"weakness": "Απόφυγε τις μετωπικές γροθιές. Χρησιμοποίησε stun δεξιότητες (Thunder Strike / Shield Bash) για να ανακόψεις το frenzy τους.",
		"stats": {"hp": 150, "damage": 23, "speed": 4.9, "style": "Γροθιές Οργής", "defense": "Βαριά"},
		"drops": [
			{"item": "Χρυσός (12-24)", "chance": "100%"},
			{"item": "Κομμάτι Σιδήρου", "chance": "50%"},
			{"item": "Φίλτρο Υγείας", "chance": "50%"}
		]
	},
	{
		"kind_id": "orc_warlord",
		"name": "Πολέμαρχος Γκρομ'γκαρ",
		"category": "orcs",
		"is_boss": true,
		"model_path": "res://assets/characters/Orc.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.05,
		"tint_color": Color(0.95, 0.15, 0.05, 0.35),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "CharacterArmature|Idle",
		"lore": "Ο πανίσχυρος ηγέτης της επιδρομής των Ορκ στον Άγιο Βλάση. Κυβερνά από το κατεστραμμένο ακροπύργιο και καλεί ενισχύσεις πολεμιστών όταν η ζωή του πέσει κάτω από το μισό.",
		"weakness": "Όταν εξαπολύει την πολεμική κραυγή του, επικεντρώσου στην εξόντωση των υποτακτικών του προτού συνεχίσεις το duel μαζί του.",
		"stats": {"hp": 580, "damage": 28, "speed": 4.4, "style": "Πολέμαρχος Μάχης", "defense": "Θρυλική"},
		"drops": [
			{"item": "Χρυσός (80-140)", "chance": "100%"},
			{"item": "Κομμάτι Σιδήρου x3", "chance": "100%"},
			{"item": "Φίλτρο Δύναμης", "chance": "100%"},
			{"item": "Φίλτρο Υγείας x2", "chance": "100%"}
		]
	},

	# -------------------------------------------------------------------------
	# 3. Ληστές & Κουρσάροι (Bandits & Pirates)
	# -------------------------------------------------------------------------
	{
		"kind_id": "bandit_thug",
		"name": "Ληστής Ροπαλοφόρος",
		"category": "bandits",
		"is_boss": false,
		"model_path": "res://assets/characters/Barbarian.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0.55, 0.28, 0.12, 0.40),
		"show_nodes": ["1H_Axe", "Barbarian_Round_Shield"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Αδίστακτοι παράνομοι που λυμαίνονται τα ορεινά μονοπάτια. Επιτίθενται σε εμπορικά καραβάνια και ταξιδιώτες για χρυσό και τρόφιμα.",
		"weakness": "Απρόσεκτοι στην άμυνά τους. Ένα καλό parry ή stun τους αφήνει εντελώς εκτεθειμένους.",
		"stats": {"hp": 60, "damage": 14, "speed": 4.0, "style": "Τσεκούρι & Στρογγυλή Ασπίδα", "defense": "Μέτρια"},
		"drops": [
			{"item": "Χρυσός (8-18)", "chance": "100%"},
			{"item": "Κομμάτι Σιδήρου", "chance": "25%"},
			{"item": "Φίλτρο Υγείας", "chance": "35%"}
		]
	},
	{
		"kind_id": "bandit_chief",
		"name": "Αρχηγός των Ληστών",
		"category": "bandits",
		"is_boss": true,
		"model_path": "res://assets/characters/Barbarian.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.7,
		"tint_color": Color(0.45, 0.10, 0.10, 0.30),
		"show_nodes": ["2H_Axe"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο αδίστακτος εγκέφαλος πίσω από τις επιδρομές στους δρόμους του χωριού. Κραδαίνει ένα γιγάντιο δίχειρο τσεκούρι που μπορεί να διαπεράσει ακόμα και ατσάλινες πανοπλίες.",
		"weakness": "Οι επιθέσεις του είναι αργές. Κύλισε κάτω από το τσεκούρι του και χτύπα τον στα πλευρά.",
		"stats": {"hp": 450, "damage": 24, "speed": 4.2, "style": "Δίχειρο Τσεκούρι", "defense": "Βαριά"},
		"drops": [
			{"item": "Χρυσός (100-150)", "chance": "100%"},
			{"item": "Μαγικό Φυλαχτό", "chance": "100%"},
			{"item": "Φίλτρο Δύναμης", "chance": "100%"}
		]
	},
	{
		"kind_id": "pirate_corsair",
		"name": "Πειρατής Κουρσάρος",
		"category": "bandits",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Rogue.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0.85, 0.30, 0.15, 0.35),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Καταραμένοι ναυτικοί που ναυάγησαν στις ακτές του Ηφαιστείου. Φυλάνε με φανατισμό τους κρυμμένους θησαυρούς και τα λαθραία βαρέλια του Μαυροδόντη.",
		"weakness": "Γρήγοροι στις κινήσεις τους αλλά με χαμηλή αντοχή. Η απόκρουση με ασπίδα τους προκαλεί άμεση ανισορροπία.",
		"stats": {"hp": 65, "damage": 14, "speed": 4.8, "style": "Κυρτή Σπάθη", "defense": "Μέτρια"},
		"drops": [
			{"item": "Χρυσός (10-22)", "chance": "100%"},
			{"item": "Θραύσμα Οστών", "chance": "40%"},
			{"item": "Φίλτρο Υγείας", "chance": "40%"}
		]
	},
	{
		"kind_id": "pirate_captain",
		"name": "Αρχικουρσάρος Μαυροδόντης",
		"category": "bandits",
		"is_boss": true,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Small_A.gltf",
		"model_scale": 2.0,
		"tint_color": Color(1.0, 0.22, 0.08, 0.45),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο θρυλικός καπετάνιος των πειρατών που κυβέρνησε τις νότιες θάλασσες. Ακόμα και μετά το θάνατό του, το πνεύμα του φρουρεί την καλντέρα και τον καταραμένο θησαυρό του ηφαιστείου.",
		"weakness": "Ευάλωτος σε δεξιότητες ψύχους και ιερού φωτός. Απόφυγε τη φλογερή του αύρα μένοντας σε κίνηση.",
		"stats": {"hp": 380, "damage": 24, "speed": 4.4, "style": "Πύρινη Σπάθη & Ασπίδα", "defense": "Επική"},
		"drops": [
			{"item": "Χρυσός (70-120)", "chance": "100%"},
			{"item": "Μαγικό Φυλαχτό", "chance": "100%"},
			{"item": "Φίλτρο Ταχύτητας", "chance": "100%"}
		]
	},

	# -------------------------------------------------------------------------
	# 4. Πλάσματα της Στάχτης (Ash & Flame)
	# -------------------------------------------------------------------------
	{
		"kind_id": "ember_skeleton",
		"name": "Φλογοσκελετός",
		"category": "ash_valley",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Small_A.gltf",
		"model_scale": 1.0,
		"tint_color": Color(1.0, 0.38, 0.05, 0.36),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Σκελετοί εμποτισμένοι με τη φωτιά του ηφαιστείου. Τα κόκαλά τους καίνε σαν πυρωμένο κάρβουνο και κάθε τους χτύπημα αφήνει εγκαύματα.",
		"weakness": "Ανθεκτικοί στη φωτιά αλλά εξαιρετικά ευάλωτοι σε ατσάλινο βαρύ χτύπημα και επιθέσεις νερού.",
		"stats": {"hp": 300, "damage": 34, "speed": 5.0, "style": "Πύρινο Σπαθί", "defense": "Βαριά"},
		"drops": [
			{"item": "Χρυσός (15-32)", "chance": "100%"},
			{"item": "Ηφαιστειακό Κάρβουνο", "chance": "40%"},
			{"item": "Φίλτρο Υγείας", "chance": "50%"}
		]
	},
	{
		"kind_id": "ash_caster",
		"name": "Στάχτινος Μάγος",
		"category": "ash_valley",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Mage.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Staff.gltf",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(1.0, 0.50, 0.10, 0.34),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Σκοτεινοί ιερείς της λάβας που εξαπολύουν βολίδες συμπυκνωμένης φωτιάς. Μπορούν να ανάψουν το έδαφος κάτω από τα πόδια του στόχου τους.",
		"weakness": "Διατήρησε συνεχή κίνηση για να αποφεύγεις τις βολίδες. Μετά την εκτόξευση χρειάζονται 2.4 δευτερόλεπτα για να επαναφορτίσουν.",
		"stats": {"hp": 160, "damage": 30, "speed": 3.9, "style": "Πύρινες Βολίδες", "defense": "Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (15-32)", "chance": "100%"},
			{"item": "Ηφαιστειακό Κάρβουνο", "chance": "40%"},
			{"item": "Φίλτρο Υγείας", "chance": "50%"}
		]
	},
	{
		"kind_id": "pyrforos",
		"name": "Πυρφόρος, ο Φύλακας της Φλόγας",
		"category": "ash_valley",
		"is_boss": true,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Axe.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Large_A.gltf",
		"model_scale": 2.8,
		"tint_color": Color(1.0, 0.30, 0.04, 0.46),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο κολοσσιαίος φύλακας του Ναού της Φλόγας. Το σώμα του εκπέμπει αφόρητη θερμότητα και όταν νιώσει κίνδυνο καλεί φλογοσκελετούς για βοήθεια.",
		"weakness": "Μην μένεις ποτέ μπροστά στο βαρύ του τσεκούρι. Χρησιμοποίησε dodge roll ακριβώς τη στιγμή του κατεβάσματος για αποφυγή του ωστικού κύματος.",
		"stats": {"hp": 6000, "damage": 55, "speed": 4.2, "style": "Κολοσσιαίος Πέλεκυς", "defense": "Μυθική"},
		"drops": [
			{"item": "Χρυσός (400-700)", "chance": "100%"},
			{"item": "Ηφαιστειακό Κάρβουνο x3", "chance": "100%"},
			{"item": "Μαγικό Φυλαχτό", "chance": "100%"}
		]
	},

	# -------------------------------------------------------------------------
	# 5. Άγρια Θηρία & Σκιές (Beasts & Curiosities)
	# -------------------------------------------------------------------------
	{
		"kind_id": "wolf",
		"name": "Άγριος Λύκος των Δασών",
		"category": "beasts",
		"is_boss": false,
		"model_path": "res://assets/characters/Wolf.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 0.82,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "AnimalArmature|Idle",
		"lore": "Επικίνδυνοι θηρευτές των Χρυσών Πεύκων. Επιτίθενται με εξαιρετική ταχύτητα και αστραπιαία άλματα, περικυκλώνοντας το θήραμά τους.",
		"weakness": "Χρησιμοποίησε την ασπίδα σου για να μπλοκάρεις το άλμα τους. Μόλις χτυπήσουν πάνω στην ασπίδα, ζαλίζονται για ένα δευτερόλεπτο.",
		"stats": {"hp": 65, "damage": 15, "speed": 6.2, "style": "Δάγκωμα & Άλμα", "defense": "Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (3-8)", "chance": "100%"},
			{"item": "Θραύσμα Οστών", "chance": "60%"},
			{"item": "Φίλτρο Υγείας", "chance": "25%"}
		]
	},
	{
		"kind_id": "spider",
		"name": "Σπηλαιόβια Αράχνη",
		"category": "beasts",
		"is_boss": false,
		"model_path": "res://assets/characters/Spider.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 0.52,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "SpiderArmature|Spider_Idle",
		"lore": "Γιγάντια αραχνοειδή που κατοικούν σε σκοτεινά σπήλαια και σχισμές βράχων. Το δηλητήριό τους προκαλεί επιβράδυνση της κίνησης του θύματος.",
		"weakness": "Ευάλωτη σε φωτιά και πλατιές επιθέσεις σπαθιού. Κράτησε απόσταση για να μην σε επιβραδύνει ο ιστός της.",
		"stats": {"hp": 50, "damage": 13, "speed": 4.8, "style": "Δηλητήριο & Ιστός", "defense": "Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (3-7)", "chance": "100%"},
			{"item": "Φίλτρο Υγείας", "chance": "30%"}
		]
	},
	{
		"kind_id": "dark_knight",
		"name": "Σκοτεινός Ιππότης",
		"category": "beasts",
		"is_boss": false,
		"model_path": "res://assets/characters/Knight.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.25,
		"tint_color": Color(0.15, 0.08, 0.22, 0.80),
		"show_nodes": ["2H_Sword", "Knight_Helmet", "Knight_Cape"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Έκπτωτοι ιππότες που ορκίστηκαν πίστη στις σκοτεινές δυνάμεις. Φέρουν μαύρη ατσάλινη πανοπλία και δίχειρα σπαθιά που κόβουν με τρομακτική δύναμη.",
		"weakness": "Βαριά πανοπλία που τους κάνει αργούς στις στροφές. Κινήσου κυκλικά γύρω τους και χτύπα τα ακάλυπτα σημεία.",
		"stats": {"hp": 170, "damage": 25, "speed": 3.8, "style": "Δίχειρο Σπαθί", "defense": "Πολύ Υψηλή"},
		"drops": [
			{"item": "Χρυσός (18-40)", "chance": "100%"},
			{"item": "Κομμάτι Σιδήρου", "chance": "60%"},
			{"item": "Φίλτρο Υγείας", "chance": "50%"}
		]
	},
	{
		"kind_id": "malakar",
		"name": "Μαλάκαρ ο Σκοτεινός Άρχοντας",
		"category": "beasts",
		"is_boss": true,
		"model_path": "res://assets/characters/Skeleton_Mage.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Staff.gltf",
		"offhand_path": "",
		"model_scale": 2.5,
		"tint_color": Color(0.45, 0.10, 0.70, 0.36),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο ανώτατος άρχοντας του Σκότους στα Σύνορα. Ελέγχει τις σκιές και καλεί στρατιές από μαύρους ιππότες όταν απειληθεί η ύπαρξή του.",
		"weakness": "Ιερά ξόρκια και ευλογημένα όπλα. Καθάρισε πρώτα τους ιππότες που καλεί για να μην σε υπερκεράσουν.",
		"stats": {"hp": 3200, "damage": 36, "speed": 4.4, "style": "Σκοτεινή Καταιγίδα", "defense": "Μυθική"},
		"drops": [
			{"item": "Χρυσός (300-380)", "chance": "100%"},
			{"item": "Μαγικό Φυλαχτό x2", "chance": "100%"},
			{"item": "Φίλτρο Δύναμης", "chance": "100%"}
		]
	},

	# -------------------------------------------------------------------------
	# 6. Μονομάχοι Αρένας (Arena Gladiators & Champions)
	# -------------------------------------------------------------------------
	{
		"kind_id": "gladiator_recruit",
		"name": "Εκπαιδευόμενος Μονομάχος",
		"category": "arena",
		"is_boss": false,
		"model_path": "res://assets/characters/Barbarian.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": ["1H_Axe"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Νέοι μαχητές που μπαίνουν στην Αρένα για να αποδείξουν την αξία τους. Παρά την απειρία τους, διαθέτουν υψηλή ενεργητικότητα και επιμονή.",
		"weakness": "Εύκολα προβλέψιμες επιθέσεις. Χρησιμοποίησε βασικά combos για γρήγορη εξουδετέρωση.",
		"stats": {"hp": 95, "damage": 14, "speed": 4.3, "style": "Πέλεκυς Μονομάχου", "defense": "Μέτρια"},
		"drops": [
			{"item": "Χρυσός (8-18)", "chance": "100%"},
			{"item": "Φίλτρο Υγείας", "chance": "40%"}
		]
	},
	{
		"kind_id": "arena_gorgor",
		"name": "Γκόργκορ «ο Βράχος»",
		"category": "arena",
		"is_boss": true,
		"model_path": "res://assets/characters/Barbarian.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.45,
		"tint_color": Color(0.70, 0.45, 0.20, 0.35),
		"show_nodes": ["1H_Axe", "Barbarian_Round_Shield"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο πρώτος μεγάλος πρωταθλητής της Χάλκινης Δοκιμασίας. Ένας αλύγιστος βάρβαρος με βαριά ασπίδα και τεράστια μυϊκή μάζα.",
		"weakness": "Η ασπίδα του μπλοκάρει τις περισσότερες μετωπικές επιθέσεις. Σπάσε το μπλοκ με Front Kick (C) και χτύπα όσο παραπατάει.",
		"stats": {"hp": 340, "damage": 22, "speed": 4.1, "style": "Βαρύς Μπαλτάς & Ασπίδα", "defense": "Βαριά"},
		"drops": [
			{"item": "Χρυσός (180)", "chance": "100%"},
			{"item": "Χάλκινο Τρόπαιο Αρένας", "chance": "100%"}
		]
	},
	{
		"kind_id": "arena_drake",
		"name": "Αρχικουρσάρος Ντρέικ",
		"category": "arena",
		"is_boss": true,
		"model_path": "res://assets/characters/Rogue_Hooded.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.4,
		"tint_color": Color(0.20, 0.50, 0.85, 0.40),
		"show_nodes": ["Knife", "Knife_Offhand"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο θρυλικός Σιδηρόχερος κουρσάρος που κυριαρχεί στην Ασημένια Δοκιμασία. Χρησιμοποιεί δίδυμα μαχαίρια και κινείται με εκτυφλωτική ταχύτητα.",
		"weakness": "Η ταχύτητά του είναι το όπλο του αλλά στερείται βαριάς πανοπλίας. Χρησιμοποίησε Whirlwind ή Thunder Strike για να τον ακινητοποιήσεις.",
		"stats": {"hp": 520, "damage": 25, "speed": 5.4, "style": "Δίδυμες Λεπίδες", "defense": "Μέτρια"},
		"drops": [
			{"item": "Χρυσός (450)", "chance": "100%"},
			{"item": "Ασημένιο Τρόπαιο Αρένας", "chance": "100%"}
		]
	},
	{
		"kind_id": "arena_vorgthul",
		"name": "Ορκ Μονομάχος Βοργκ'θουλ",
		"category": "arena",
		"is_boss": true,
		"model_path": "res://assets/characters/Orc.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.25,
		"tint_color": Color(0.95, 0.25, 0.05, 0.45),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "CharacterArmature|Idle",
		"lore": "Ο τρομερός εκτελεστής των Ορκ στην Χρυσή Δοκιμασία. Κραδαίνει έναν πελώριο διπλό πέλεκυ και κάθε του χτύπημα τραντάζει την άμμο της αρένας.",
		"weakness": "Αργά sweeps με μεγάλη εμβέλεια. Κύλισε προς τα εμπρός κάτω από το τσεκούρι του για να βρεθείς στην πλάτη του.",
		"stats": {"hp": 780, "damage": 34, "speed": 4.5, "style": "Πελώριος Διπλός Πέλεκυς", "defense": "Επική"},
		"drops": [
			{"item": "Χρυσός (950)", "chance": "100%"},
			{"item": "Χρυσό Τρόπαιο Αρένας", "chance": "100%"}
		]
	},
	{
		"kind_id": "arena_titan",
		"name": "Σκελετός Τιτάνας",
		"category": "arena",
		"is_boss": true,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Axe.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Large_A.gltf",
		"model_scale": 2.2,
		"tint_color": Color(0.30, 0.15, 0.50, 0.45),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο πανύψηλος υπερασπιστής της Ηρωικής Δοκιμασίας. Ένας τιτάνας των οστών του οποίου τα βήματα προκαλούν ρωγμές στο έδαφος και σεισμικά κύματα.",
		"weakness": "Το Stomp του επιβραδύνει. Πήδα (Space) ή κύλισε μακριά όταν σηκώνει το πόδι του και επιτέσου από απόσταση με τόξο.",
		"stats": {"hp": 1150, "damage": 42, "speed": 3.8, "style": "Σεισμικός Πέλεκυς & Ασπίδα", "defense": "Μυθική"},
		"drops": [
			{"item": "Χρυσός (2000)", "chance": "100%"},
			{"item": "Ηρωικό Τρόπαιο Αρένας", "chance": "100%"}
		]
	},
	{
		"kind_id": "arena_balthazar",
		"name": "Ανώτατος Πρωταθλητής Βαλτάσαρ",
		"category": "arena",
		"is_boss": true,
		"model_path": "res://assets/characters/Knight.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.85,
		"tint_color": Color(1.0, 0.85, 0.20, 0.65),
		"show_nodes": ["2H_Sword", "Knight_Helmet", "Knight_Cape"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο απόλυτος πρωταθλητής όλων των εποχών στην Αρένα του Αγίου Βλάση. Περιβάλλεται από μία χρυσή αύρα μεγαλείου και χειρίζεται το δίχειρο σπαθί του με υπερφυσική χάρη.",
		"weakness": "Ο πιο επικίνδυνος μονομάχος. Χρειάζεται πλήρης εξοπλισμός +5, χρήση φίλτρων δύναμης και άψογος συνδυασμός block και αποφυγών.",
		"stats": {"hp": 1600, "damage": 50, "speed": 4.8, "style": "Χρυσή Σπάθη Πρωταθλητή", "defense": "Απόλυτη"},
		"drops": [
			{"item": "Χρυσός (5000)", "chance": "100%"},
			{"item": "Μυθικό Τρόπαιο Αρένας", "chance": "100%"},
			{"item": "Θώρακας Πρωταθλητή (Tier 10)", "chance": "100%"}
		]
	},

	# -------------------------------------------------------------------------
	# 7. Φύλακες των Κατακομβών & Νυχτερινές Επιδρομές (Catacombs & Night)
	# -------------------------------------------------------------------------
	{
		"kind_id": "cguard",
		"name": "Φρουρός των Κατακομβών",
		"category": "skeletons",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Large_A.gltf",
		"model_scale": 1.15,
		"tint_color": Color(0.30, 0.70, 0.85, 0.26),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Αρχαίοι φρουροί που περιπολούν στους υγρούς διαδρόμους των κατακομβών κάτω από την παλιά κρύπτη. Φέρουν βαριές σιδερένιες ασπίδες.",
		"weakness": "Η βαριά ασπίδα τους σπάει με ισχυρό Shield Bash ή επίθεση άλματος.",
		"stats": {"hp": 85, "damage": 16, "speed": 4.0, "style": "Σπαθί & Μεγάλη Ασπίδα", "defense": "Υψηλή"},
		"drops": [
			{"item": "Χρυσός (6-14)", "chance": "100%"},
			{"item": "Αρχαίο Νόμισμα", "chance": "35%"},
			{"item": "Φίλτρο Υγείας", "chance": "40%"}
		]
	},
	{
		"kind_id": "acolyte",
		"name": "Ακόλουθος του Σκότους",
		"category": "skeletons",
		"is_boss": false,
		"model_path": "res://assets/characters/Skeleton_Mage.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Staff.gltf",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0.85, 0.15, 0.30, 0.30),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Σκελετοί μάγοι που εξασκούνται στη μαύρη μαγεία βαθιά στις κατακόμβες. Εξαπολύουν ενεργειακές σφαίρες που επιβραδύνουν τον στόχο τους.",
		"weakness": "Ευάλωτοι σε εγγύς επιθέσεις. Κλείστε γρήγορα την απόσταση πριν εξαπολύσουν τα ξόρκια τους.",
		"stats": {"hp": 40, "damage": 18, "speed": 3.9, "style": "Μαύρη Μαγεία (Ραβδί)", "defense": "Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (6-14)", "chance": "100%"},
			{"item": "Μαγική Σκόνη", "chance": "45%"},
			{"item": "Φίλτρο Μάνας", "chance": "35%"}
		]
	},
	{
		"kind_id": "warden_bone",
		"name": "Φύλακας των Οστών",
		"category": "skeletons",
		"is_boss": true,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Axe.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Large_A.gltf",
		"model_scale": 2.1,
		"tint_color": Color(0.85, 0.90, 1.0, 0.20),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ένας από τους τρεις Τιτάνες Φύλακες των Κατακομβών. Κρατά έναν τεράστιο πέλεκυ που μπορεί να συντρίψει οποιαδήποτε πανοπλία.",
		"weakness": "Οι επιθέσεις του έχουν μεγάλη καθυστέρηση. Αποφύγετε το τσεκούρι και χτυπήστε τον στα πλευρά.",
		"stats": {"hp": 640, "damage": 26, "speed": 3.9, "style": "Βαρύς Πέλεκυς", "defense": "Πολύ Υψηλή"},
		"drops": [
			{"item": "Χρυσός (70-110)", "chance": "100%"},
			{"item": "Κλείδα των Κατακομβών", "chance": "100%"},
			{"item": "Οστέινο Περιδέραιο", "chance": "50%"}
		]
	},
	{
		"kind_id": "warlord",
		"name": "Οστέινος Πολέμαρχος",
		"category": "skeletons",
		"is_boss": true,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Large_A.gltf",
		"model_scale": 1.9,
		"tint_color": Color(0.9, 0.3, 0.1, 0.3),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ηγείται των νυχτερινών επιδρομών ενάντια στο χωριό. Περιβάλλεται από κόκκινη αύρα μίσους και ενισχύει τους κοντινούς συμμάχους του.",
		"weakness": "Εξοντώστε πρώτα τους υπηρέτες του για να επικεντρωθείτε στη μονομαχία μαζί του.",
		"stats": {"hp": 300, "damage": 20, "speed": 4.0, "style": "Σπάθη & Ασπίδα", "defense": "Υψηλή"},
		"drops": [
			{"item": "Χρυσός (40-70)", "chance": "100%"},
			{"item": "Λάβαρο του Πολέμαρχου", "chance": "60%"},
			{"item": "Φίλτρο Υγείας", "chance": "100%"}
		]
	},
	{
		"kind_id": "night_lord",
		"name": "Άρχοντας της Νύχτας",
		"category": "skeletons",
		"is_boss": true,
		"model_path": "res://assets/characters/Skeleton_Warrior.glb",
		"weapon_path": "res://assets/characters/skeleton_weapons/Skeleton_Blade.gltf",
		"offhand_path": "res://assets/characters/skeleton_weapons/Skeleton_Shield_Large_A.gltf",
		"model_scale": 2.4,
		"tint_color": Color(0.25, 0.20, 0.65, 0.34),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Εμφανίζεται κάθε πέμπτη νύχτα κατά τη διάρκεια των μεγάλων επιδρομών. Ένα κολοσσιαίο σκοτεινό ον που επικαλείται κύματα σκελετών.",
		"weakness": "Όταν πέσει κάτω από το 50% HP εισέρχεται σε φάση έξαψης (Enrage). Κρατήστε τα μεγάλα cooldowns για αυτή τη φάση.",
		"stats": {"hp": 900, "damage": 28, "speed": 4.0, "style": "Τιτάνιο Ξίφος Σκότους", "defense": "Κολοσσιαία"},
		"drops": [
			{"item": "Χρυσός (120-160)", "chance": "100%"},
			{"item": "Σκοτεινό Πετράδι της Νύχτας", "chance": "100%"},
			{"item": "Ελιξίριο της Σελήνης", "chance": "100%"}
		]
	},

	# -------------------------------------------------------------------------
	# 8. Περιπλανώμενοι & Μυστικιστικά Όντα (Wanderers & Curiosities)
	# -------------------------------------------------------------------------
	{
		"kind_id": "shadow_knight",
		"name": "Ιππότης των Σκιών",
		"category": "beasts",
		"is_boss": false,
		"model_path": "res://assets/characters/Knight.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.25,
		"tint_color": Color(0.12, 0.05, 0.28, 0.85),
		"show_nodes": ["2H_Sword", "Knight_Helmet", "Knight_Cape"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Φαντάσματα παλιών πολεμιστών που υπηρετούν στις νυχτερινές επιδρομές. Εμφανίζονται από το πουθενά μέσα στις σκιές.",
		"weakness": "Είναι βαριοί και αργοί στις στροφές. Κινηθείτε γύρω τους για χτυπήματα στην πλάτη.",
		"stats": {"hp": 180, "damage": 26, "speed": 3.8, "style": "Σκιώδες Δίχειρο Σπαθί", "defense": "Πολύ Υψηλή"},
		"drops": [
			{"item": "Χρυσός (18-40)", "chance": "100%"},
			{"item": "Μαύρος Σίδηρος", "chance": "50%"},
			{"item": "Φίλτρο Υγείας", "chance": "50%"}
		]
	},
	{
		"kind_id": "witch",
		"name": "Μάγισσα των Σκιών",
		"category": "beasts",
		"is_boss": false,
		"model_path": "res://assets/characters/Mage.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0.28, 0.05, 0.42, 0.72),
		"show_nodes": ["Spellbook", "Mage_Hat", "Mage_Cape"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Εξασκεί τη μαγεία των καταραμένων βοτάνων στις σκοτεινές άκρες του δάσους. Εκτοξεύει δηλητηριώδη ξόρκια.",
		"weakness": "Εξαιρετικά χαμηλή ζωή. Αποφύγετε τα βλήματά της και εξοντώστε την σε δευτερόλεπτα.",
		"stats": {"hp": 80, "damage": 18, "speed": 4.0, "style": "Ξόρκια Σκιάς", "defense": "Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (14-30)", "chance": "100%"},
			{"item": "Δηλητηριώδες Βότανο", "chance": "60%"},
			{"item": "Φίλτρο Μάνας", "chance": "45%"}
		]
	},
	{
		"kind_id": "thief",
		"name": "Άπληστος Κλέφτης",
		"category": "bandits",
		"is_boss": false,
		"model_path": "res://assets/characters/Rogue_Hooded.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0.18, 0.26, 0.18, 0.65),
		"show_nodes": ["Knife", "Knife_Offhand", "Rogue_Cape"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ταχύτατοι απατεώνες που παραμονεύουν στα μονοπάτια και προσπαθούν να κλέψουν χρυσό από τους ταξιδιώτες κατά το χτύπημα.",
		"weakness": "Αντιδρούν άσχημα σε stun ή knockdown επιθέσεις όπως το Shield Bash.",
		"stats": {"hp": 55, "damage": 11, "speed": 5.4, "style": "Διπλά Εγχειρίδια", "defense": "Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (20-45)", "chance": "100%"},
			{"item": "Κλεμμένο Πουγκί", "chance": "40%"},
			{"item": "Ελαφρύ Εγχειρίδιο", "chance": "20%"}
		]
	},
	{
		"kind_id": "raider",
		"name": "Άγριος Επιδρομέας",
		"category": "bandits",
		"is_boss": false,
		"model_path": "res://assets/characters/Barbarian.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.2,
		"tint_color": Color(0.50, 0.15, 0.08, 0.58),
		"show_nodes": ["2H_Axe", "Barbarian_Hat", "Barbarian_Cape"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Βάρβαροι επιδρομείς που λεηλατούν απομακρυσμένες φάρμες. Επιτίθενται με μανιώδεις κατακόρυφες πελεκιές.",
		"weakness": "Η επίθεσή τους τους αφήνει εκτεθειμένους για αντεπίθεση.",
		"stats": {"hp": 135, "damage": 22, "speed": 4.5, "style": "Βαρύ Τσεκούρι", "defense": "Μέτρια"},
		"drops": [
			{"item": "Χρυσός (14-28)", "chance": "100%"},
			{"item": "Δέρμα Ζώου", "chance": "50%"},
			{"item": "Φίλτρο Υγείας", "chance": "45%"}
		]
	},
	{
		"kind_id": "pumpkin",
		"name": "Κολοκυθένιο Τέρας",
		"category": "beasts",
		"is_boss": false,
		"model_path": "res://assets/graveyard/pumpkin_orange_jackolantern.gltf",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(1.0, 0.55, 0.15, 0.6),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Μια μαγική κολοκύθα που ζωντάνεψε από απαγορευμένη νεκρομαντεία. Αναπηδά με ταχύτητα και δαγκώνει απρόσεκτους περαστικούς.",
		"weakness": "Εξαιρετικά εύθραυστο κέλυφος. Ένα χτύπημα με σπαθί ή βέλος αρκεί για να το διαλύσει.",
		"stats": {"hp": 42, "damage": 10, "speed": 5.2, "style": "Αναπήδηση & Δάγκωμα", "defense": "Πολύ Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (3-8)", "chance": "100%"},
			{"item": "Κολοκυθόσποροι", "chance": "70%"},
			{"item": "Φίλτρο Υγείας", "chance": "30%"}
		]
	},
	{
		"kind_id": "haunted_tree",
		"name": "Στοιχειωμένο Δέντρο",
		"category": "beasts",
		"is_boss": false,
		"model_path": "res://assets/graveyard/tree_dead_medium.gltf",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ένα ξερό δέντρο του νεκροταφείου που κινεί τα αγκαθωτά κλαδιά του όταν πλησιάζει ζωντανός. Δεν μπορεί να μετακινηθεί αλλά έχει τεράστια εμβέλεια.",
		"weakness": "Δεν μετακινείται. Επιτεθείτε του από απόσταση με τόξο χωρίς να δεχτείτε χτύπημα.",
		"stats": {"hp": 170, "damage": 15, "speed": 0.0, "style": "Αγκαθωτά Κλαδιά", "defense": "Υψηλή"},
		"drops": [
			{"item": "Χρυσός (6-14)", "chance": "100%"},
			{"item": "Στοιχειωμένη Ξυλεία", "chance": "80%"},
			{"item": "Φίλτρο Υγείας", "chance": "40%"}
		]
	},
	{
		"kind_id": "golem",
		"name": "Πέτρινος Γίγαντας",
		"category": "beasts",
		"is_boss": true,
		"model_path": "",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.8,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Μοιάζει με έναν αθώο σωρό από γρανιτένιους βράχους, αλλά όταν πλησιάσεις σηκώνεται ως πανύψηλος γίγαντας και συντρίβει το έδαφος.",
		"weakness": "Πολύ αργή κίνηση. Χτυπήστε και απομακρυνθείτε πριν ολοκληρώσει το χτύπημα των χεριών του.",
		"stats": {"hp": 260, "damage": 24, "speed": 2.6, "style": "Συντριβή Βράχων", "defense": "Απόλυτη"},
		"drops": [
			{"item": "Χρυσός (12-26)", "chance": "100%"},
			{"item": "Καρδιά Γρανίτη", "chance": "60%"},
			{"item": "Φίλτρο Υγείας", "chance": "60%"}
		]
	},
	{
		"kind_id": "mimic",
		"name": "Μίμικ (Παγιδευμένο Σεντούκι)",
		"category": "beasts",
		"is_boss": false,
		"model_path": "res://assets/items/chest.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.25,
		"tint_color": Color(0, 0, 0, 0),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ένα παραπλανητικό τέρας που παίρνει τη μορφή ενός χρυσού ή ξύλινου σεντούκου. Όταν ο απρόσεκτος ήρωας πάει να το ανοίξει, αποκαλύπτει κοφτερά σαγόνια.",
		"weakness": "Κυλήστε πίσω αμέσως μόλις ανοίξετε το σεντούκι και επιτεθείτε με Whirlwind.",
		"stats": {"hp": 90, "damage": 14, "speed": 4.6, "style": "Αιφνιδιαστικό Δάγκωμα", "defense": "Μέτρια"},
		"drops": [
			{"item": "Χρυσός (40-90)", "chance": "100%"},
			{"item": "Πολύτιμος Λίθος", "chance": "50%"},
			{"item": "Φίλτρο Υγείας", "chance": "50%"}
		]
	},
	{
		"kind_id": "cultist",
		"name": "Οπαδός της Σέκτας",
		"category": "beasts",
		"is_boss": false,
		"model_path": "res://assets/characters/Rogue_Hooded.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.0,
		"tint_color": Color(0.55, 0.04, 0.12, 0.62),
		"show_nodes": [],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Φανατικοί λάτρεις του Σκοτεινού Άρχοντα που συγκεντρώνονται στον τελετουργικό κύκλο του βορειοδυτικού δάσους. Εκτοξεύουν σκοτεινές σφαίρες.",
		"weakness": "Χαμηλή ζωή, διακόπτονται εύκολα όταν δέχονται σωματικά χτυπήματα.",
		"stats": {"hp": 55, "damage": 11, "speed": 4.0, "style": "Σφαίρες Κατάρας", "defense": "Χαμηλή"},
		"drops": [
			{"item": "Χρυσός (8-18)", "chance": "100%"},
			{"item": "Τελετουργικό Κερί", "chance": "40%"},
			{"item": "Φίλτρο Μάνας", "chance": "40%"}
		]
	},
	{
		"kind_id": "cult_priest",
		"name": "Αρχιερέας της Σέκτας",
		"category": "bosses",
		"is_boss": true,
		"model_path": "res://assets/characters/Mage.glb",
		"weapon_path": "",
		"offhand_path": "",
		"model_scale": 1.6,
		"tint_color": Color(0.30, 0.02, 0.07, 0.70),
		"show_nodes": ["2H_Staff"],
		"parts": [],
		"anim_idle": "Idle",
		"lore": "Ο επικεφαλής του σκοτεινού τελετουργικού κύκλου. Καθοδηγεί τις θυσίες και καλεί οπαδούς για να τον προστατεύσουν κατά τη μάχη.",
		"weakness": "Στο 50% HP καλεί επιπλέον σκελετούς. Χρησιμοποιήστε περιοχικές επιθέσεις για να καθαρίσετε το πεδίο.",
		"stats": {"hp": 520, "damage": 20, "speed": 4.4, "style": "Τελετουργικό Ραβδί & Κατάρες", "defense": "Υψηλή"},
		"drops": [
			{"item": "Χρυσός (120-200)", "chance": "100%"},
			{"item": "Βιβλίο Μαύρων Τελετών", "chance": "100%"},
			{"item": "Φίλτρο Υγείας", "chance": "100%"}
		]
	},
]

static func get_entry(kind_id: String) -> Dictionary:
	for e in ENTRIES:
		if e["kind_id"] == kind_id:
			return e
	return {}

static func get_by_category(category: String) -> Array[Dictionary]:
	if category == "all" or category.is_empty():
		return ENTRIES.duplicate()
	var res: Array[Dictionary] = []
	for e in ENTRIES:
		if e.get("category") == category:
			res.append(e)
	return res

## Returns knowledge unlock level (0 = unknown, 1 = discovered, 2 = studied stats & drops, 3 = mastered lore & weakness).
static func get_unlock_tier(kills: int, is_boss: bool) -> int:
	if is_boss:
		return 3 if kills >= 1 else 0
	if kills >= 15:
		return 3
	elif kills >= 5:
		return 2
	elif kills >= 1:
		return 1
	return 0
