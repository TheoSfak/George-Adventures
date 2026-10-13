class_name Strings
## Every player-facing UI text of the game, in Greek.
## (Quests, lore and NPC dialogue live in quest_data.gd.)

const TITLE := "Οι Περιπέτειες του Γιώργου στον Άγιο Βλάση"
const CONTROLS_1 := "Δεξί κλικ: κοίτα και κατεύθυνε   Αριστερό κλικ: κάμερα   Και τα δύο: τρέξε μπροστά   Ροδέλα: ζουμ"
const CONTROLS_2 := "W S μπρος/πίσω   A D στροφή   Q E πλάγια   Shift τρέξιμο   Space άλμα   F ή κλικ: επίθεση   K άμυνα   H φίλτρο   R δράση"

const HERO := "Γιώργος"
const LEVEL_SHORT := "Επ."
const FALLEN := "Ο Γιώργος έπεσε…"
const LEVEL_UP := "ΑΝΕΒΗΚΕΣ ΕΠΙΠΕΔΟ!  Επίπεδο %d"
const GOLD := "Χρυσά"
const POTIONS := "Φίλτρα"

const MSG_XP := "+%d εμπειρία"
const MSG_GOLD := "+%d χρυσά"
const MSG_POTION := "Φίλτρο Υγείας"
const MSG_POTIONS := "%d Φίλτρα Υγείας"
const MSG_POTION_USED := "Ήπιες φίλτρο (+%d ζωή)"
const MSG_DAMAGE_UP := "Το σπαθί σου δυνάμωσε (+%d ζημιά)"
const MSG_CHEST_EMPTY := "Το σεντούκι είναι άδειο"

const PROMPT_TALK := "[R] Μίλα: %s"
const PROMPT_ENTER := "[R] Είσοδος: %s"
const PROMPT_EXIT := "[R] Έξοδος"
const PROMPT_OPEN := "[R] Άνοιγμα σεντουκιού"
const PROMPT_CONTINUE := "[R] ή κλικ: συνέχεια"

const QUESTS_HEADER := "Αποστολές"
const QUEST_NEW := "Νέα αποστολή: %s"
const QUEST_READY := "Ολοκληρώθηκε: %s"
const QUEST_DONE := "Αποστολή ολοκληρώθηκε: %s"
const RETURN_TO := "Μίλα ξανά με: %s"
const TO_BE_CONTINUED := "Συνεχίζεται…"

const NARRATOR := "Αφηγητής"

const COOLDOWN := "Αναμονή"
const SKILL_LOCKED := "Ξεκλειδώνεται στο επίπεδο %d"
const SKILL_UNLOCKED := "Νέα ικανότητα: %s"
const SKILLBOOK := "Ικανότητες"
const SKILLBOOK_ITEMS := "Αντικείμενα"
const SKILLBOOK_HINT := "Σύρε μια ικανότητα ή ένα φίλτρο στη μπάρα κάτω.  Δεξί κλικ σε θέση: άδειασμα."
const SKILLBOOK_KEY := "[P] Ικανότητες   [T] Ταλέντα   [I] Εξοπλισμός   [M] Χάρτης"
const HINT_TALENT_POINTS := "   ★ Πόντοι ταλέντων: %d"
const BUFF_POWER := "Δύναμη"
const BUFF_SPEED := "Ταχύτητα"
const BUFF_GUARD := "Ασπίδα"
const MSG_POTION_POWER := "Φίλτρο Δύναμης"
const MSG_POTION_SPEED := "Φίλτρο Ταχύτητας"
const MSG_POWER_ON := "Δύναμη! (+60% ζημιά)"
const MSG_SPEED_ON := "Ταχύτητα! (+40% ταχύτητα)"
const MSG_PRAYER := "Ευχή του Αγίου: +%d ζωή"
const MSG_GUARD := "Η Ασπίδα του Αγίου σε προστατεύει"


# --- combat feedback, talents, skills from the talent tree
const MSG_CRIT := "Κρίσιμο χτύπημα!"
const MSG_REBIRTH := "Ανάσταση! Ο Άγιος σε σηκώνει ξανά"
const MSG_TALENT_POINT := "Νέος πόντος ταλέντου!  [T]"
const MSG_TAUNT := "Κραυγή Πρόκλησης! Οι εχθροί παγώνουν"
const MSG_WALL := "Τείχος! Είσαι άτρωτος"
const MSG_FRENZY := "Αιματηρή Μανία!"
const MSG_FLAME := "Θεία Φλόγα: +%d ζωή"
const MSG_SANCTUARY := "Ιερός Κύκλος: στάσου μέσα του"
const MSG_JUNK := "Βρήκες: %s"
const MSG_NO_GOLD := "Δεν έχεις αρκετά χρυσά"
const MSG_EQUIPPED := "Φόρεσες: %s"
const MSG_RESPEC_NONE := "Δεν έχεις ταλέντα για να αναδιανείμεις"
const MSG_RESPEC_DONE := "Οι πόντοι ταλέντων επέστρεψαν"
const SKILL_NEEDS_TALENT := "Μαθαίνεται από το δέντρο ταλέντων  [T]"
const BUFF_FRENZY := "Μανία"
const BUFF_SHOUT := "Κραυγή"
const BUFF_WALL := "Τείχος"

# --- heroes window (P / T / I)
const HERO_TAB_SKILLS := "Ικανότητες"
const HERO_TAB_TALENTS := "Ταλέντα"
const HERO_TAB_GEAR := "Εξοπλισμός"
const TALENT_POINTS := "Πόντοι ταλέντων: %d"
const TALENT_RANK := "Βαθμίδα %d / %d"
const TALENT_PER_RANK := "Ανά βαθμίδα: %s"
const TALENT_SKILL := "Ικανότητα  (Αναμονή %d δ)"
const TALENT_HINT := "Κλικ σε ταλέντο: μαθαίνεται.  Σύρε τις ικανότητες στη μπάρα.  Κάθε επίπεδο δίνει 1 πόντο."
const TALENT_RESPEC_HINT := "Αναδιανομή πόντων: προσευχή στην εκκλησία (%d χρυσά)."
const PROMPT_RESPEC := "[R] Αναδιανομή ταλέντων (%d χρυσά)"
const GEAR_EQUIPPED := "Φοράς"
const GEAR_EMPTY := "Δικός σου εξοπλισμός"
const GEAR_OWNED := "Στην τσάντα σου"
const GEAR_NONE := "Δεν έχεις άλλον εξοπλισμό. Επισκέψου το σιδηρουργείο."
const GEAR_WEAR := "Φόρεσε"
const GEAR_TAKE_OFF := "Βγάλε"
const STATS_HEADER := "Στατιστικά"
const STAT_DAMAGE := "Ζημιά"
const STAT_HEALTH := "Ζωή"
const STAT_DEFENSE := "Άμυνα"
const STAT_CRIT := "Κρίσιμο"

# --- shops
const PROMPT_TRADE := "[R] Συναλλαγή: %s"
const SHOP_BUY := "Αγορά"
const SHOP_SELL := "Πώληση"
const SHOP_CLOSE := "Κλείσιμο  [Esc]"
const SHOP_PRICE := "%d χρ."
const SHOP_BUY_BUTTON := "Αγόρασε"
const SHOP_SELL_BUTTON := "Πούλησε"
const SHOP_OWNED := "Το έχεις"
const SHOP_LEVEL_NEEDED := "Επ. %d"
const SHOP_NOTHING_TO_SELL := "Δεν έχεις τίποτα να πουλήσεις εδώ."
const SHOP_HAVE := "Έχεις: %d"
const SHOP_BOUGHT := "Αγόρασες: %s"
const SHOP_SOLD := "Πούλησες: %s  (+%d χρυσά)"

const BUILDING_NAMES := {
	"church": "Εκκλησία",
	"tavern": "Ταβέρνα",
	"blacksmith": "Σιδηρουργείο",
	"market": "Παζάρι",
	"home": "Σπίτι",
	"catacombs": "Κατακόμβη",
}

const CATACOMBS_SEALED := "Σφραγισμένη πύλη"
const MSG_CATACOMBS_SEALED := "Η πύλη είναι σφραγισμένη με τις σφραγίδες του Αγίου. Μίλησε πρώτα με τον Παπά-Σταύρο."
const PROMPT_GATE_SEALED := "Η πύλη του Ηγουμένου"
const MSG_GATE_SEALED := "Η πύλη ανοίγει μόνο όταν πέσουν οι τρεις Φύλακες των Σφραγίδων."
const MSG_GATE_OPEN := "Οι σφραγίδες έσβησαν. Η πύλη του Ηγουμένου άνοιξε!"

const DAY_WORD := "Ημέρα"

const DUSK_FALLS := "Σουρουπώνει… οι χωρικοί μπαίνουν στα σπίτια τους."
const INVASION_BANNER := "ΕΙΣΒΟΛΗ!  Οι νεκροί πλησιάζουν το χωριό!"
const INVASION_WAVE_BANNER := "Κύμα %d!"
const INVASION_WAVE := "Κύμα %d/%d — Σκελετοί: %d"
const INVASION_SAFETY := "Ασφάλεια χωριού"
const INVASION_WON := "Το χωριό σώθηκε!"
const INVASION_LOST := "Το πηγάδι έπεσε! Οι νεκροί λεηλάτησαν το χωριό…"
const INVASION_LOST_GOLD := "Έχασες %d χρυσά"
const INVASION_DAWN := "Χάραξε… οι νεκροί γύρισαν στα χώματα."

const MAP_TITLE := "Χάρτης του Αγίου Βλάση"
const MAP_LEGEND := "!  νέα αποστολή     ?  παράδοση     ◆  στόχος     ●  εχθρός     [M] ή [Esc] ή ✕ κλείσιμο"
const MAP_PLACES := {
	"church": "Εκκλησία", "tavern": "Ταβέρνα", "market": "Παζάρι", "smith": "Σιδηρουργείο",
	"mill": "Πριονιστήριο", "windmill": "Μύλος", "tower": "Πύργος Φρουράς", "well": "Πηγάδι",
	"camp": "Δυτικό Στρατόπεδο", "quarry": "Λατομείο", "crypt": "Παλιά Κρύπτη",
}

const MUSIC_ON := "Μουσική: ενεργή  [F7]"
const MUSIC_OFF := "Μουσική: σίγαση  [F7]"
const SFX_ON := "Ήχοι: ενεργοί  [F8]"
const SFX_OFF := "Ήχοι: σίγαση  [F8]"

const AUDIO_DEVICE := "Συσκευή ήχου: %s  [F9]"

const LEVEL_WORD := "Επίπεδο"
const SAVED := "Το παιχνίδι αποθηκεύτηκε"
const SAVE_FAILED := "Η αποθήκευση απέτυχε!"
const MENU_CONTINUE := "Συνέχεια"
const MENU_RESUME := "Επιστροφή στο παιχνίδι"
const MENU_NEW := "Νέο παιχνίδι"
const MENU_NEW_SURE := "Θα διαγραφεί η αποθηκευμένη πρόοδος. Σίγουρα;"
const MENU_YES := "Ναι, νέο παιχνίδι"
const MENU_NO := "Όχι"
const MENU_SAVE := "Αποθήκευση"
const MENU_SETTINGS := "Ρυθμίσεις"
const MENU_TITLE_SCREEN := "Κεντρικό μενού"
const MENU_QUIT := "Έξοδος"
const MENU_BACK := "Πίσω"
const MENU_CONTROLS := "Χειριστήρια"
const HELP_TOOLTIP := "Χειριστήρια  [F1]"
## [key, what it does] for the controls help page (the "i" button, F1, Esc menu)
const CONTROLS_HELP: Array = [
	["W / S", "Μπρος / πίσω"], ["A / D", "Στροφή"], ["Q / E", "Πλάγια κίνηση"], ["Shift", "Τρέξιμο"],
	["Space", "Άλμα"], ["Δεξί κλικ", "Κοίτα και κατεύθυνε"], ["Αριστερό κλικ", "Κάμερα"], ["Και τα δύο", "Τρέξε μπροστά"],
	["Ροδέλα", "Ζουμ κάμερας"], ["F ή κλικ", "Επίθεση"], ["K", "Άμυνα"], ["H", "Φίλτρο υγείας"],
	["R / Enter", "Δράση, συνομιλία"], ["1 – 8", "Ικανότητες και φίλτρα"], ["P", "Ικανότητες"], ["T", "Ταλέντα"],
	["I", "Εξοπλισμός"], ["M", "Χάρτης"], ["+ / −", "Ζουμ μικρού χάρτη"], ["F11", "Πλήρης οθόνη"],
	["Esc", "Μενού"], ["F1", "Αυτή η σελίδα"],
]
const MENU_PAUSED := "Παύση"
const SET_VOLUMES := "Ένταση ήχου"
const SET_MASTER := "Γενική"
const SET_MUSIC := "Μουσική"
const SET_SFX := "Εφέ"
const SET_AMBIENT := "Περιβάλλον"
const SET_DEVICE := "Συσκευή ήχου"
const SET_KEYS := "Πλήκτρα  (κλικ σε ένα πλήκτρο και μετά πάτα το νέο)"
const SET_PRESS := "Πάτα πλήκτρο…"
const SET_RESET_KEYS := "Επαναφορά πλήκτρων"
const SET_DEFAULT_DEVICE := "Προεπιλογή συστήματος"

const TOTEM_NAME := "Οστέινο Τοτέμ"

const GUARD_NAME := "Φρουρός"
const GUARDS_ARRIVE := "Οι φρουροί του Βασίλη φτάνουν στο πηγάδι (%d)"
