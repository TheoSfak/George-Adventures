# Bounty Board & Hunting Contracts — Design

Date: 2026-10-17. Feature: Interactive Village Bounty Board outside the Tavern with repeatable hunting contracts, hunter ranks, and rewards.

## Goal
Provide George with repeatable, dynamic hunting contracts and bounties on the island's wildlife and enemy factions, accessible directly from a rustic wooden notice board outside the Tavern in Agios Vlasis.

## 3D Notice Board Prop (`bounty_board.gd`)
- Positioned on the front terrace / cobblestone path of the Tavern at `Vector3(-53.5, 0.0, -12.5)`, yaw 1.45 rad facing the village square and road.
- Two heavy dark timber posts with stone footers, dark shingled gabled canopy, weathered notice backboard with 3 pinned aged parchment sheets and crimson wax seal dots.
- Hanging brass lantern with warm golden `OmniLight3D` casting atmospheric illumination at dusk and night.
- Group: `"interactables"`, `"bounty_board"`. Prompt: `[R] Πίνακας Επικηρύξεων & Συμβόλαια`, range 3.6m.

## Hunting Contracts Data (`bounty_data.gd`)
3 Difficulty Tiers with distinct colors and reward scales:
1. **Bronze (Χάλκινο):**
   - «Εξόντωσε το Alpha Wolf στα Χρυσά Πεύκα» (4 Wolves, 450g, 380 XP, 2x bone_shard)
   - «Καθάρισε τη Φωλιά των Αραχνών» (5 Spiders, 480g, 400 XP, 1x iron_scrap, 2x potions)
2. **Silver (Ασημένιο):**
   - «Ανάκτησε τα Κλεμμένα Εφόδια του Εμπόρου» (5 Bandits, 650g, 520 XP, 2x iron_scrap)
   - «Εξαγνισμός των Ακοίμητων Σκελετών» (8 Skeletons, 580g, 460 XP, 3x bone_shard)
   - «Εμπροσθοφυλακή των Όρκ» (4 Orcs, 750g, 580 XP, 2x iron_scrap, 1x lava_ember)
3. **Gold (Χρυσό):**
   - «Επικήρυξη: Αρχηγός των Ληστών» (1 Bandit Chief, 950g, 750 XP, 3x iron_scrap, 3x potions)
   - «Ο Τρόμος της Στάχτης: Magma Golem» (2 Magma Golems, 1,100g, 850 XP, 2x lava_ember)
   - «Επικήρυξη Warlord: Γκρομ'γκαρ» (1 Orc Warlord, 1,400g, 1,100 XP, 3x lava_ember)

## Hunter Ranks (`BountyData.HUNTER_RANKS`)
- Rank 1 (0+ bounties): «Μισθοφόρος του Χωριού» ⚔️
- Rank 2 (3+ bounties): «Ιχνηλάτης Αγρίων Θηρίων» 🐾
- Rank 3 (6+ bounties): «Κυνηγός Επικηρυγμένων» 🎯
- Rank 4 (10+ bounties): «Προστάτης του Αγίου Βλάση» 🛡️
- Rank 5 (15+ bounties): «Θρυλικός Εκτελεστής» 👑

## Central Controller & Kill Routing (`bounty_manager.gd`)
- Node in group `"bounty_manager"`.
- Tracks `available_bounties` (3 board contracts) and `active_bounties`.
- Hooks into `quests.gd` and `enemies.gd` kill events to automatically increment matching contract progress.
- Floating HUD announcements on kill progress, contract completion, and rank promotions.
- Claiming rewards gives gold, XP, and materials directly to George, and refills available contracts.

## Interactive UI Window (`bounty_window.gd`)
- Dark glass panel with gold accents matching `UiKit`.
- Displays Hunter Rank header badge and total completed bounties.
- 3 side-by-side parchment-style cards with colored tier tags, target info, narrative description, live progress bar, reward pills, and action button («Ανάληψη Συμβολαίου», «Σε Εξέλιξη», «Είσπραξη Αμοιβής»).
- Closeable with [Esc], [R] or close button.

## Map & Persistence
- Minimap and Big Map (M) landmark registration: `bounty_board` outside the Tavern.
- Saved in `savegame.json` under `"bounties"`.
