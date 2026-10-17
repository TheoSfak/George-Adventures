class_name Strings
## Every player-facing UI text of the game, in Greek.
## (Quests, lore and NPC dialogue live in quest_data.gd.)

const TITLE := "Οι Περιπέτειες του Γιώργου στον Άγιο Βλάση"
const CONTROLS_1 := "Δεξί κλικ: κοίτα και κατεύθυνε   Γρήγορο αριστερό κλικ: επίθεση   Και τα δύο κρατημένα: τρέξε μπροστά   Ροδέλα: ζουμ"
const CONTROLS_2 := "W S μπρος/πίσω   A D στροφή   Q E πλάγια   Shift τρέξιμο   Space άλμα   F ή κλικ: επίθεση   K άμυνα   H φίλτρο   R δράση"

const HERO := "Γιώργος"
const LEVEL_SHORT := "Επ."
const FALLEN := "Ο Γιώργος έπεσε…"
const LEVEL_UP := "ΑΝΕΒΗΚΕΣ ΕΠΙΠΕΔΟ!  Επίπεδο %d"
const GOLD := "Χρυσά"
const POTIONS := "Φίλτρα"

const MSG_XP := "+%d εμπειρία"
const MSG_GOLD := "+%d χρυσά"
const MSG_GOLD_STOLEN := "Ο κλέφτης σου άρπαξε %d χρυσά!"
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
const RESCUE_TITLE := "Κίνδυνος!"
const RESCUE_TEXT := "Ο φίλος σου ο Αντρέας είναι σε κίνδυνο, ακούω τις φωνές του. Γρήγορα οι σκελετοί τον έχουν περικυκλώσει! Σώσε τον!"
const RESCUE_BUTTON := "Πάω!"
const RESCUE_LOST := "Ο Αντρέας χάθηκε…"
const RESCUE_SAVED := "Ο Αντρέας σώθηκε!"
const RESCUE_MAP_LABEL := "Ο Αντρέας κινδυνεύει!"
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
const MSG_THUNDER_STRIKE := "Κεραυνός των Αρχαίων!"
const MSG_BATTLE_CRY := "Πολεμική Κραυγή! (+30% ζημιά, +15% ταχύτητα)"
const MSG_SET_BONUS := "Ενεργοποιήθηκε το %s! (+%d Ζωή, +%d%% Άμυνα, +%d%% Ζημιά)"
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
	"george_cottage": "Το Σπίτι του Γιώργου",
	"catacombs": "Κατακόμβη",
	"frontier": "Βουνίσιο Πέρασμα", "ashvalley": "Κοιλάδα της Στάχτης", "temple": "Άδυτο της Φλόγας",
}

const CATACOMBS_SEALED := "Σφραγισμένη πύλη"
const MSG_CATACOMBS_SEALED := "Η πύλη είναι σφραγισμένη με τις σφραγίδες του Αγίου. Μίλησε πρώτα με τον Παπά-Σταύρο."
const PROMPT_GATE_SEALED := "Η πύλη του Ηγουμένου"
const MSG_GATE_SEALED := "Η πύλη ανοίγει μόνο όταν πέσουν οι τρεις Φύλακες των Σφραγίδων."
const MSG_GATE_OPEN := "Οι σφραγίδες έσβησαν. Η πύλη του Ηγουμένου άνοιξε!"

const DAY_WORD := "Ημέρα"

const DUSK_FALLS := "Σουρουπώνει… οι χωρικοί μπαίνουν στα σπίτια τους."
const INVASION_RESUMED := "Η εισβολή συνεχίζεται!"
const INVASION_BANNER := "ΕΙΣΒΟΛΗ!  Οι νεκροί πλησιάζουν το χωριό!"
const INVASION_THEME_SHADOWS := "ΕΙΣΒΟΛΗ ΣΚΙΩΝ!  Τοξότες και κλέφτες πολιορκούν το χωριό!"
const INVASION_THEME_GIANTS := "ΕΠΕΛΑΣΗ ΓΙΓΑΝΤΩΝ!  Βαριοί πολεμιστές και σκοτεινοί ιππότες πλησιάζουν!"
const INVASION_THEME_CULT := "ΝΥΧΤΑ ΑΙΡΕΤΙΚΩΝ!  Μάγοι και οπαδοί της σέκτας απειλούν το πηγάδι!"
const INVASION_REWARD_CHEST := "Το χρυσό σεντούκι της νίκης εμφανίστηκε στην πλατεία!"
const INVASION_WAVE_BANNER := "Κύμα %d!"
const INVASION_WAVE := "Κύμα %d/%d — Σκελετοί: %d"
const INVASION_SAFETY := "Ασφάλεια χωριού"
const INVASION_WON := "Το χωριό σώθηκε!"
const INVASION_BOSS_COMING := "Ο Άρχοντας της Νύχτας έρχεται!"
const INVASION_BOSS_WON := "Ο Άρχοντας της Νύχτας έπεσε! Το χωριό σώθηκε!"
const NIGHT_LORD_ENRAGE := "Ο Άρχοντας της Νύχτας καλεί τους νεκρούς!"
const BANDIT_CHIEF_ENRAGE := "Ο Αρχηγός των Ληστών φωνάζει τους άντρες του!"
const INVASION_LOST := "Το πηγάδι έπεσε! Οι νεκροί λεηλάτησαν το χωριό…"
const INVASION_LOST_GOLD := "Έχασες %d χρυσά"
const INVASION_DAWN := "Χάραξε… οι νεκροί γύρισαν στα χώματα."

const MAP_TITLE := "Χάρτης του Αγίου Βλάση"
const MAP_LEGEND := "!  νέα αποστολή     ?  παράδοση     ◆  στόχος     ●  εχθρός     [M] ή [Esc] ή ✕ κλείσιμο"
# --- the horse
const MOUNT_PILL := "Άλογο"           # the pill next to the potions once the horse is bought: [G] Άλογο
const MOUNT_PILL_OFF := "Κατέβα"        # while riding: [G] Κατέβα
const MOUNT_ON := "Ανέβηκες στο άλογο"
const MOUNT_OFF := "Κατέβηκες από το άλογο"
const MOUNT_BOUGHT := "Το άλογο είναι δικό σου! Ανέβα και κατέβα με το G."
const MOUNT_BLOCKED := {
	"not_owned": "Δεν έχεις άλογο. Ο Μανώλης ο Ιπποκόμος πουλά ένα στον στάβλο.",
	"indoors": "Δεν μπορείς να ανέβεις στο άλογο εδώ μέσα.",
	"busy": "Όχι τώρα.",
	"dead": "",
	"stunned": "Είσαι ζαλισμένος!",
	"chased": "Οι νεκροί σε κυνηγούν! Δεν προλαβαίνεις να ανέβεις.",
}
const SHOP_HORSE_TITLE := "Άλογο"
const SHOP_HORSE_DESC := "Ένα γρήγορο άλογο για τα μεγάλα ταξίδια. Ανέβα και κατέβα με το G. Αν χτυπηθείς ή επιτεθείς, κατεβαίνεις."
const SHOP_HORSE_OWNED := "Έχεις ήδη άλογο"

const MAP_PLACES := {
	"church": "Εκκλησία", "tavern": "Ταβέρνα", "market": "Παζάρι", "smith": "Σιδηρουργείο",
	"mill": "Πριονιστήριο", "windmill": "Μύλος", "tower": "Πύργος Φρουράς", "well": "Πηγάδι",
	"camp": "Δυτικό Στρατόπεδο", "quarry": "Λατομείο", "crypt": "Παλιά Κρύπτη", "bigtree": "Η Λίμνη του Αιωνόβιου",
	"stable": "Στάβλος", "bandits": "Κρησφύγετο Ληστών", "cult": "Ξέφωτο της Σέκτας",
	"lighthouse": "Πέτρινος Φάρος", "harbor": "Ψαρολίμανο", "waterfall": "Καταρράκτης Νυμφών",
	"bridge_meadow": "Πέτρινο Γεφύρι", "highlands": "Βίγλα των Αετών", "shipwreck": "Ναυάγιο της Γοργόνας",
	"cliffs": "Νότιοι Γκρεμοί", "barracks": "Στρατώνες & Τοξοβολία", "orc_stronghold": "Ερειπωμένο Οχυρό (Όρκ)",
	"golden_grove": "Χρυσό Άλσος", "grotto": "Μυστικό Σπήλαιο", "lumbermill": "Υλοτομείο Γέρο-Γιάννη",
	"bounty_board": "Πίνακας Επικηρύξεων", "george_cottage": "Το Σπίτι του Γιώργου",
	"pirate_island": "Νησί των Πειρατών (Ηφαίστειο)", "camp_babis": "Καταυλισμός Καπετάν-Μπάμπη",
	"frontier_pass": "Πέρασμα των Βουνών", "frontier_camp": "Καταυλισμός Προσφύγων",
	"frontier_road": "Δρόμος της Σκιάς", "frontier_fort": "Φρούριο της Σκιάς",
	"ash_entry": "Πύλη της Στάχτης", "ash_shelter": "Το Καταφύγιο",
	"ash_bridge": "Γέφυρα της Λάβας", "ash_temple": "Ναός της Φλόγας",
}

const MAP_REGION_VILLAGE := "Άγιος Βλάσης"
const MAP_REGION_FRONTIER := "Τα Σύνορα"
const MAP_REGION_ASHVALLEY := "Κοιλάδα της Στάχτης"

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
const MENU_UNSTUCK := "Ξεκόλλημα (Unstuck)"
const MSG_UNSTUCK := "Μεταφερθήκατε σε ασφαλές σημείο στο κέντρο του χωριού!"
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
	["Space", "Άλμα"], ["Δεξί κλικ", "Κοίτα και κατεύθυνε"], ["Αριστερό κλικ", "Κρατημένο: κάμερα"], ["Και τα δύο", "Κρατημένα: τρέξε μπροστά"],
	["Ροδέλα", "Ζουμ κάμερας"], ["F ή γρήγορο κλικ", "Επίθεση, και με δεξί κλικ κρατημένο"], ["K", "Άμυνα· με επίθεση: ασπίδα"], ["V", "Αποφυγή (κύλιση)"], ["C", "Κλωτσιά"], ["H", "Φίλτρο υγείας"],
	["R / Enter", "Δράση, συνομιλία"], ["1 – =", "Ικανότητες και φίλτρα"], ["P", "Ικανότητες"], ["T", "Ταλέντα"],
	["I", "Εξοπλισμός"], ["M", "Χάρτης"], ["+ / −", "Ζουμ μικρού χάρτη"], ["F11", "Πλήρης οθόνη"],
	["G", "Άλογο: ανέβα / κατέβα"], ["U", "Ξεκόλλημα (Unstuck)"], ["F6", "Αλλαγή καιρού"], ["Esc", "Μενού"], ["F1", "Αυτή η σελίδα"],
]
const MENU_PAUSED := "Παύση"
const MENU_CREDITS := "Συντελεστές"
const SET_UPDATES := "Έλεγχος για ενημερώσεις"
const SET_SECOND_ACTION_BAR := "Δεύτερη μπάρα δεξιοτήτων"
const SET_GRAPHICS := "Γραφικά"
const GFX_HIGH := "Υψηλά"
const GFX_MEDIUM := "Μεσαία"
const GFX_COMPAT := "Συμβατά"
const GFX_DESC_HIGH := "Πλήρης ποιότητα. Αν τα γραφικά φαίνονται μαύρα ή σπασμένα, δοκίμασε «Μεσαία»."
const GFX_DESC_MEDIUM := "Ελαφρύτερη λειτουργία, σχεδόν ίδια εικόνα. Για πιο αδύναμες ή παλιές κάρτες γραφικών."
const GFX_DESC_COMPAT := "Για πολύ παλιές κάρτες γραφικών. Τα χρώματα βγαίνουν πιο χλωμά."
const GFX_APPLY := "Εφαρμογή και επανεκκίνηση"
const GFX_ERR_EDITOR := "Η αλλαγή γραφικών λειτουργεί μόνο στο εξαγόμενο παιχνίδι (το αρχείο exe)."
const GFX_ERR_WRITE := "Ο φάκελος του παιχνιδιού δεν επιτρέπει αλλαγές. Χρησιμοποίησε το Play-Mobile-Renderer.bat."
const VERSION_LABEL := "v%s"
const CREDITS_CREATORS_LINE := "Δημιουργοί: Theodore Sfakianakis & George Sfakianakis"
const CREDITS_HEADING := "Συντελεστές"
## [heading, text] pairs of the Credits page.
const CREDITS_LINES := [
	["Δημιουργοί", "Theodore Sfakianakis & George Sfakianakis"],
	["Σχεδιασμός και προγραμματισμός", "Με τη βοήθεια τεχνητής νοημοσύνης (Claude της Anthropic)"],
	["Γραφικά", "KayKit της Kay Lousberg (CC0): Adventurers, Skeletons, Medieval Hexagon, Dungeon Remastered, Furniture Bits, Halloween Bits"],
	["Άλογο", "Quaternius, Farm Animals Animated (CC0)"],
	["Μηχανή παιχνιδιού", "Godot Engine (άδεια MIT)"],
	["Ήχοι και μουσική", "Δημιουργήθηκαν από τα δικά μας scripts (Python και numpy)"],
	["Φωνές", "Microsoft Azure AI Speech (el-GR Athina και Nestoras)"],
]
const UPDATE_AVAILABLE := "Νέα έκδοση %s διαθέσιμη"
const UPDATE_CURRENT := "Τρέχουσα έκδοση: %s"
const UPDATE_BUTTON := "Ενημέρωση"
const UPDATE_LATER := "Αργότερα"
const UPDATE_DOWNLOADING := "Λήψη… %d%%"
const UPDATE_VERIFYING := "Έλεγχος αρχείου…"
const UPDATE_INSTALLING := "Εγκατάσταση…"
const UPDATE_DONE := "Η ενημέρωση ολοκληρώθηκε. Ξεκίνα ξανά το παιχνίδι."
const UPDATE_OPEN_PAGE := "Άνοιγμα σελίδας λήψης"
const UPDATE_ERR_EDITOR := "Η ενημέρωση λειτουργεί μόνο στο εξαγόμενο παιχνίδι (το αρχείο exe)."
const UPDATE_ERR_URL := "Μη αποδεκτή διεύθυνση λήψης."
const UPDATE_ERR_SIZE := "Το αρχείο της ενημέρωσης έχει ασυνήθιστο μέγεθος."
const UPDATE_ERR_DOWNLOAD := "Η λήψη απέτυχε. Έλεγξε τη σύνδεσή σου στο internet."
const UPDATE_ERR_CHECKSUM := "Το αρχείο που κατέβηκε είναι κατεστραμμένο."
const UPDATE_ERR_FILES := "Δεν ήταν δυνατή η εγγραφή των αρχείων. Ο φάκελος του παιχνιδιού δεν επιτρέπει αλλαγές."
const UPDATE_ERR_ZIP := "Το αρχείο της ενημέρωσης δεν είναι έγκυρο."
const SET_VOLUMES := "Ένταση ήχου"
const SET_MASTER := "Γενική"
const SET_MUSIC := "Μουσική"
const SET_SFX := "Εφέ"
const SET_AMBIENT := "Περιβάλλον"
const SET_VOICE := "Φωνές"
const MIMIC_REVEAL := "Το σεντούκι ήταν Μίμικ!"
const SET_DEVICE := "Συσκευή ήχου"
const SET_KEYS := "Πλήκτρα  (κλικ σε ένα πλήκτρο και μετά πάτα το νέο)"
const SET_PRESS := "Πάτα πλήκτρο…"
const SET_RESET_KEYS := "Επαναφορά πλήκτρων"
const SET_DEFAULT_DEVICE := "Προεπιλογή συστήματος"

const TOTEM_NAME := "Οστέινο Τοτέμ"

const GUARD_NAME := "Φρουρός"
const GUARDS_ARRIVE := "Οι φρουροί του Βασίλη φτάνουν στο πηγάδι (%d)"

# --- weather (scripts/weather.gd)
const WEATHER_CLEAR := "Ο ουρανός καθαρίζει."
const WEATHER_FOG := "Η ομίχλη πέφτει πάνω στο χωριό…"
const WEATHER_RAIN := "Άρχισε να βρέχει…"
const WEATHER_STORM := "Μπουρίνι! Ακούγονται βροντές…"
## Index = Weather.State (CLEAR, FOG, RAIN, STORM).
const WEATHER_MESSAGES: Array[String] = [WEATHER_CLEAR, WEATHER_FOG, WEATHER_RAIN, WEATHER_STORM]
const WEATHER_NAMES: Array[String] = ["Καθαρός", "Ομίχλη", "Βροχή", "Καταιγίδα"]

# --- story part 3: the Frontier beyond the mountains
const FRONTIER_SEALED := "Σφραγισμένη Πύλη του Περάσματος"
const MSG_FRONTIER_SEALED := "Η Πύλη του Περάσματος είναι σφραγισμένη. Μίλησε πρώτα με τον Παπά-Σταύρο."
const PROMPT_FRONTIER_BACK := "[R] Επιστροφή στον Άγιο Βλάση"
const PROMPT_FORTRESS_GATE := "Η Πύλη του Φρουρίου"
const MSG_FORTRESS_SEALED := "Η πύλη του Φρουρίου είναι σφραγισμένη. Βρες τα τρία Σύμβολα της Σκιάς."
const MSG_FORTRESS_OPEN := "Τα Σύμβολα έσπασαν τη σφραγίδα. Η πύλη του Φρουρίου άνοιξε!"
const MSG_FRONTIER_INVASION := "Το χωριό δέχεται επίθεση! Δεν μπορείς να φύγεις τώρα."
const INVASION_SKIPPED :="Ο Παπά-Σταύρος κράτησε το χωριό χωρίς εσένα."
const MSG_SLOWED := "Η ψυχή σε βαραίνει!"
const MALAKAR_ENRAGE := "Ο Μαλάκαρ καλεί τη Σκιά!"
const PYRFOROS_ENRAGE := "Ο Πυρφόρος καλεί τη Φλόγα!"
# Part 4: the Ash Valley
const ASH_SEALED := "Σφραγισμένη Πύλη της Στάχτης"
const MSG_ASH_SEALED := "Η Πύλη της Στάχτης είναι σφραγισμένη. Μίλησε πρώτα με τον Παπά-Σταύρο."
const PROMPT_ASH_BACK := "[R] Επιστροφή στον Άγιο Βλάση"
const PROMPT_TEMPLE_GATE := "Η Πύλη του Ναού της Φλόγας"
const MSG_TEMPLE_SEALED := "Ο ναός είναι σφραγισμένος. Βρες τα τρία Θραύσματα της Φλόγας."
const MSG_TEMPLE_OPEN := "Τα Θραύσματα έσπασαν τη σφραγίδα. Ο ναός της Φλόγας άνοιξε!"
const MSG_NO_MAP := "Ο χάρτης του χωριού δεν δείχνει αυτά τα βουνά."

# --- fishing and the kitchen
const PROMPT_FISH := "[R] Ψάρεμα"
const FISH_CAST := "Ρίχνεις την πετονιά…"
const FISH_WAIT := "Περιμένεις να τσιμπήσει…"
const FISH_BITE := "Τσιμπάει! Πάτα τώρα!"
const FISH_HINT := "[R] / Space / κλικ: τράβηγμα     Esc: ακύρωση"
const MSG_FISH_CAUGHT := "Έπιασες: %s"
const MSG_FISH_NEW := "Νέο είδος! (%d/%d)"
const MSG_FISH_ESCAPED := "Το ψάρι ξέφυγε"
const MSG_FISH_EARLY := "Τράβηξες πολύ νωρίς"
const FISH_JOURNAL := "Ψάρια: %d/%d"
const KITCHEN_TAB_MEALS := "Φαγητά"
const KITCHEN_TAB_COOK := "Μαγείρεμα"
const KITCHEN_EAT := "Φάε"
const KITCHEN_NEEDS := "Χρειάζεται: %s"
const MEAL_DURATION := "Διάρκεια: %d λεπτά"
const MSG_MEAL_EATEN := "Έφαγες: %s"
const MSG_MEAL_NO_FISH := "Δεν έχεις αρκετά ψάρια"
const MSG_MEAL_OVER := "Η δύναμη του φαγητού πέρασε: %s"

# --- crafting & upgrades
const SHOP_TAB_UPGRADE := "Αναβάθμιση"
const UPGRADE_TITLE := "Σιδηρουργείο: Ενίσχυση Εξοπλισμού"
const UPGRADE_BUTTON := "Ενίσχυση (+%d)"
const UPGRADE_MAXED := "Μέγιστο Επίπεδο (+3)"
const UPGRADE_NEEDS := "Απαιτούνται: %s και %d χρυσά"
const UPGRADE_HAVE := "Διαθέτεις: %d %s, %d χρυσά"
const MSG_UPGRADED := "Το αντικείμενο αναβαθμίστηκε σε: %s!"
const MSG_NO_UPGRADE_MATS := "Δεν έχεις τα απαραίτητα υλικά για αναβάθμιση!"

# --- weapon types
const WEAPON_TYPE_1H := "Μονοχείριο"
const WEAPON_TYPE_2H := "Δίχειρο"
const WEAPON_TYPE_DUAL := "Δίδυμες Λεπίδες"
const WEAPON_TYPE_BOW := "Τόξο"
const WEAPON_TYPE_CROSSBOW := "Βαλλίστρα"
const MSG_RANGED_NEEDS_WEAPON := "Χρειάζεσαι εξοπλισμένο Τόξο ή Βαλλίστρα!"

# --- Story Part 5: Temple Sanctum
const SANCTUM_SEALED := "Σφραγισμένο Άδυτο της Φλόγας"
const MSG_SANCTUM_SEALED := "Το Άδυτο ανοίγει μόνο μετά την ήττα του Πυρφόρου."
const PROMPT_SANCTUM_ENTER := "[R] Είσοδος στο Άδυτο της Φλόγας"
const PROMPT_SANCTUM_EXIT := "[R] Έξοδος στον Ναό της Φλόγας"
const TEMPLE_VICTORY_BANNER := "ΤΟ ΝΗΣΙ ΣΩΘΗΚΕ! Ο Άρχοντας της Τέφρας ηττήθηκε!"
const PROMPT_SANCTUM_ALTAR := "[R] Βωμός της Αιώνιας Φλόγας"
const MSG_ALTAR_RESTORED := "Η Αιώνια Φλόγα εξαγνίστηκε! Το σκοτάδι υποχωρεί από τον Άγιο Βλάση."

# --- world encounters
const SCARECROW_AWAKENS := "Το Καταραμένο Σκιάχτρο ζωντανεύει!"
const PROMPT_TRAVELING_MERCHANT := "[R] %s (Πλανόδιος Έμπορος)"

# --- Village Parkour (Obby)
const PARKOUR_TITLE := "Πάρκουρ των Στεγών"
const PARKOUR_SUBTITLE := "Ακροβατική Δοκιμασία Αγίου Βλάση (Όριο: 3:00)"
const PARKOUR_START_PROMPT := "[R] Έναρξη Δοκιμασίας Πάρκουρ (3:00)"
const PARKOUR_RETRY_PROMPT := "[R] Επανεκκίνηση Πάρκουρ"
const PARKOUR_RESPAWN_PROMPT := "[R] Επαναφορά στο Checkpoint"
const PARKOUR_RESPAWN_BANNER := "Επαναφορά στο Checkpoint %d!"
const PARKOUR_CHECKPOINT_REACHED := "Σημείο Ελέγχου %d/%d!"
const PARKOUR_HUD_CP := "Checkpoint: %d/%d"
const PARKOUR_HUD_TIME := "Χρόνος: %s"
const PARKOUR_HUD_BEST := "Ρεκόρ: %s"
const PARKOUR_TIME_EXPIRED := "Έληξε ο χρόνος (3:00)! Η δοκιμασία τελείωσε. Δοκίμασε ξανά!"
const PARKOUR_FALL_MSG := "Έπεσες! Πάτησε [R] για επαναφορά στο Checkpoint."
const PARKOUR_WIN_TITLE := "ΝΙΚΗΤΗΣ ΠΑΡΚΟΥΡ!"
const PARKOUR_WIN_MSG := "Ολοκλήρωσες το Πάρκουρ των Στεγών σε %s!"
const PARKOUR_NEW_RECORD := "ΝΕΟ ΠΡΟΣΩΠΙΚΟ ΡΕΚΟΡ!"
const PARKOUR_SIGN_TEXT := "=== ΠΑΡΚΟΥΡ ΤΩΝ ΣΤΕΓΩΝ ===\nΑνέβα τις σκάλες έξω από την Ταβέρνα!\nΠέρασε τα δοκάρια, πάτα τα τραμπολίνα\nκαι φτάσε στον Ανεμόμυλο πριν λήξουν τα 3 λεπτά!\n\nΚαλύτερος Χρόνος: %s"
const PARKOUR_CHEST_TITLE := "Σεντούκι του Ακροβάτη"
const PARKOUR_NEED_FINISH := "Πάτησε πρώτα στο κέντρο του βάθρου για καταγραφή του χρόνου!"
const PARKOUR_NEED_CHEST := "Άνοιξε πρώτα το Σεντούκι του Ακροβάτη!"
const PARKOUR_PORTAL_ACTIVE := "Η πύλη επιστροφής ενεργοποιήθηκε! Πάτα στον φωτεινό κύκλο."
const PARKOUR_RETURN_SUCCESS := "Επέστρεψες στην Πλατεία του Αγίου Βλάση!"
const PARKOUR_HUD_CLOSE_TOOLTIP := "Κλείσιμο καρτέλας"
const PARKOUR_COMPLETED_STATUS := "Ολοκληρώθηκε!"



