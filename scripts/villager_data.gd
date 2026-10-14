class_name VillagerData
## Everything the ambient villagers say (Greek): names, what they tell George,
## the little conversations between two villagers, and the tavern chatter.

const MODELS: Array[String] = [
	"res://assets/characters/Barbarian.glb",
	"res://assets/characters/Rogue.glb",
	"res://assets/characters/Rogue_Hooded.glb",
	"res://assets/characters/Knight.glb",
	"res://assets/characters/Mage.glb",
]

## Names of the ambient villagers by gender. Names of story NPCs and stall owners (Ελένη, Στέλιος,
## Θανάσης, Σήφης...) are left out so nobody is a namesake of someone with a quest or a shop.
const NAMES_MALE: Array[String] = [
	"Δημήτρης", "Κώστας", "Βαγγέλης", "Μιχάλης", "Αντώνης", "Παναγιώτης", "Λευτέρης", "Γρηγόρης",
]
const NAMES_FEMALE: Array[String] = [
	"Αγγελική", "Σοφία", "Κατερίνα", "Μαρίνα", "Δέσποινα", "Ζωή", "Ειρήνη", "Χρυσούλα", "Νίκη",
]

## How each model reads: the Barbarian (beard) and the Knight (helmet) are men, the braided Rogue is a
## woman; the Mage and the hooded Rogue can be either (story NPCs of both genders use them).
const MODEL_GENDER := {
	"Barbarian": "m", "Knight": "m", "Rogue": "f", "Mage": "any", "Rogue_Hooded": "any",
}


## A villager name that fits the model's gender; `index` picks within the allowed names.
static func name_for(model_path: String, index: int) -> String:
	var gender: String = MODEL_GENDER.get(model_path.get_file().get_basename(), "any")
	var pool: Array[String] = []
	if gender == "m":
		pool = NAMES_MALE
	elif gender == "f":
		pool = NAMES_FEMALE
	else:
		pool = NAMES_MALE + NAMES_FEMALE
	return pool[index % pool.size()]

## The people of the village square, by name: "f" or "m" (the voice follows the gender; their models agree, see gender_test).
const SQUARE_SPEAKERS := {
	"Κυρά-Βούλα": "f", "Μπάρμπα-Θόδωρος": "m", "Αδελφή Αρετή": "f", "Σήφης ο Κρασάς": "m",
	"Αρετούσα η Τραγουδίστρια": "f", "Μπάρμπα-Σπύρος ο Βιολιτζής": "m",
}

## What each stall vendor calls out first when George talks to them (the first bubble line of the stall in square.gd).
const VENDOR_CALLOUT := {
	"Κυρά-Βούλα": "Φρέσκα λαχανικά από τον κήπο μου!",
	"Μπάρμπα-Θόδωρος": "Ζεστό ψωμί, ζεστό ψωμί!",
	"Αδελφή Αρετή": "Βότανα και φίλτρα από το βουνό!",
	"Σήφης ο Κρασάς": "Κρασί από τον κάμπο, όσο θέλετε!",
}
## ...and what every vendor may answer besides.
const VENDOR_TALK: Array[String] = [
	"Έλα να δεις, Γιώργο! Ό,τι χρειάζεσαι, το έχουμε.",
	"Τα πράγματα δεν είναι εύκολα, αλλά το παζάρι μας δεν κλείνει ποτέ.",
]
## What the two musicians on the stage answer.
const MUSICIAN_TALK: Array[String] = [
	"Το βράδυ φοβόμαστε, μα η μουσική μας δίνει κουράγιο, Γιώργο.",
	"Όταν τελειώσεις με τους σκελετούς, θα τραγουδήσουμε για σένα!",
]


## Everything a stall vendor says to George.
static func vendor_talk(vendor_name: String) -> Array:
	return [VENDOR_CALLOUT[vendor_name]] + VENDOR_TALK


## What a villager answers when George talks to them (each picks a few).
const GOSSIP: Array[String] = [
	"Καλημέρα, Γιώργο! Άκουσα πως ο Παπά-Σταύρος σε ψάχνει.",
	"Η καμπάνα ράγισε χθες βράδυ και από τότε οι νεκροί δεν ησυχάζουν.",
	"Η Κυρά-Μαρία έχει την πιο δροσερή μπίρα του χωριού. Πέρνα από την ταβέρνα!",
	"Λένε πως οι σκελετοί φοβούνται τη φωτιά και το φως των κεριών.",
	"Πρόσεχε στο λατομείο. Έχω ακούσει πως έναν τεράστιο σκελετό τον φωνάζουν Λοχαγό.",
	"Μη βγεις στο δάσος χωρίς φίλτρα υγείας, παλικάρι μου.",
	"Η Παλιά Κρύπτη είναι κλειστή εδώ και αιώνες. Ποτέ δεν φοβήθηκα… μέχρι απόψε.",
	"Τα κοτόπουλά μου πάψανε να γεννάνε από τότε που ράγισε η καμπάνα.",
	"Ο Νικήτας ο σιδεράς φτιάχνει τα καλύτερα σπαθιά. Δες αν έχει κάτι για σένα.",
	"Στα σεντούκια που βρίσκεις εδώ κι εκεί κρύβονται θησαυροί. Άνοιξέ τα!",
	"Ο Γέρο-Γιάννης ξέρει το δάσος καλύτερα από όλους μας.",
	"Τα λουλούδια φέτος άνθισαν πιο νωρίς. Σαν να ήξεραν ότι θα χρειαστούμε χαρά.",
	"Αν ανέβεις επίπεδο, θα μάθεις καινούργιες ικανότητες. Πάτα το P για να τις δεις!",
	"Έχω ένα βαρέλι κρασί στο κελάρι και κανένα σκελετό να το πιει. Ευτυχώς.",
]

## Little conversations between two villagers. They speak in turns: A, B, A, B...
const CONVERSATIONS: Array = [
	["Άκουσες την καμπάνα χθες βράδυ;", "Πώς να μην την άκουγα! Μου κόπηκε ο ύπνος.", "Λένε πως ξύπνησαν οι νεκροί…", "Ο Άγιος να μας φυλάει."],
	["Φέτος οι ντομάτες μου έγιναν τεράστιες!", "Τις ποτίζεις με κρασί, ντε;", "Χα χα! Μυστικό του παππού μου.", "Φέρε μου μία για το τραπέζι."],
	["Είδες τον Γιώργο; Πάλι με το σπαθί στο χέρι.", "Είναι παλικάρι. Θα μας σώσει όλους.", "Μακάρι… αλλά είναι πολλοί οι σκελετοί.", "Εγώ λέω να του φτιάξω ένα καλό φαγητό."],
	["Το πριονιστήριο δεν σταμάτησε ούτε μια μέρα.", "Ο Γέρο-Γιάννης είναι από σίδερο.", "Από σίδερο και από πείσμα, θα έλεγα.", "Και τα δύο χρειάζονται αυτές τις μέρες."],
	["Η Κυρά-Μαρία έχασε τα βαρέλια της.", "Τι λες! Τα πήραν οι σκελετοί;", "Έτσι λέει. Τα πέταξαν στα χωράφια.", "Φοβερό πράγμα. Καλά που έχουμε τον Γιώργο."],
	["Θα βρέξει αύριο, το νιώθω στο γόνατο.", "Το γόνατό σου προβλέπει βροχή από το '78.", "Και πάντα έχει δίκιο!", "Αν πεις… Εγώ θα μαζέψω τα ρούχα."],
	["Πήγες στην εκκλησία σήμερα;", "Ναι, ο Παπά-Σταύρος ήταν πολύ ανήσυχος.", "Κι εγώ το πρόσεξα. Κάτι ξέρει.", "Ο Άγιος να βάλει το χέρι του."],
	["Τα παιδιά θέλουν να παίξουν έξω.", "Ούτε να το σκέφτεσαι! Όχι μέχρι να φύγουν οι σκελετοί.", "Έχεις δίκιο. Θα τα κλείσω στο σπίτι.", "Καλύτερα να κλαίνε παρά να κινδυνεύουν."],
]

## What the tavern regulars say (they pick one every now and then).
const DRINK_LINES: Array[String] = [
	"Στην υγειά μας!",
	"Άλλη μία γύρα!",
	"Η μπίρα της Μαρίας δεν έχει αντίπαλο.",
	"Όσο έχουμε μπίρα, δεν φοβόμαστε σκελετούς!",
	"Γειά μας και χαρά μας!",
	"Ωραία μπίρα, ωραία παρέα.",
	"Κέρνα κι άλλη, Μαρία!",
	"Ο Γιώργος να ζήσει!",
	"Στην υγειά του Αγίου Βλάση!",
	"Εδώ μέσα δεν μας πιάνουν τα κόκαλα… ούτε οι σκελετοί.",
	"Μια μπίρα σου λύνει όλα τα προβλήματα.",
	"Τι κρίμα που δεν έχουμε και λίγο μεζέ!",
]

## Pairs of drinkers that talk to each other (A, B, A, B...).
const TAVERN_CONVERSATIONS: Array = [
	["Ρε φίλε, είδες τι έγινε με την καμπάνα;", "Ε, δεν έγινε και τίποτα. Μια ρωγμή είναι.", "Μια ρωγμή που ξύπνησε τους νεκρούς!", "Άσε, πιες την μπίρα σου και μην το σκέφτεσαι."],
	["Εγώ σου λέω, ο Γιώργος θα τους καθαρίσει όλους.", "Με ένα σπαθί μόνο του;", "Έχει και φίλτρα. Και έχει τον Άγιο μαζί του.", "Τότε στην υγειά του Αγίου!"],
	["Η Μαρία βάζει κάτι μυστικό στη μπίρα.", "Αλήθεια; Τι βάζει;", "Αν το ήξερα δεν θα ήταν μυστικό, ντε!", "Χα χα χα! Έχεις δίκιο."],
	["Θυμάσαι τότε που φοβόμασταν μόνο τον φορολογικό;", "Τι εποχές ήταν εκείνες!", "Τώρα έχουμε σκελετούς και φόρους.", "Καλύτερα να πιούμε λοιπόν."],
]
