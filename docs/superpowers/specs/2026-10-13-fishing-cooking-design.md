# Fishing at the pond and food buffs in the tavern (design)

Date: 2026-10-13. Target release: 0.14-beta. Backlog item B of `HANDOVER.md`. Status: approved by Theodore in chat (mini-game, 13 fish, journal, cook NPC, meals).

## Goal
George can fish at the village pond with a one-button timing mini-game, collect 13 species, sell them at the market or cook them with the new tavern cook **Θανάσης ο Μάγειρας** into meals that give timed buffs. All in-game text is Greek; code, comments and file names are English.

## Decisions
- **Mini-game:** a timing bar, one input only (R, Enter, Space or left click) so it works over AnyDesk, where only digits, Space, arrows and Enter arrive reliably.
- **Fish use:** raw material for cooking; also sold at the market (the existing junk sell tab).
- **Cook:** a new NPC inside the tavern, not Κυρά-Μαρία (she keeps the keg quests).
- **Meals:** eaten at the counter, the buff starts at once; one meal at a time (a new one replaces the old); not saved (like potion buffs).
- **Journal:** the save stores which species were caught; the hero window shows "Ψάρια: n/13".
- **Out of scope (YAGNI):** rod and bait, other lakes, carrying meals on the action bar, fishing quests.

## Fishing
- **Spot:** a small wooden dock on the shore of the pond (`Village._build_terrain_details`, `add_pond` at (-70, 108)), a bucket, and an `InteractSpot` "[R] Ψάρεμα". One spot.
- **Flow** (`scripts/fishing.gd`, class `Fishing`, a HUD overlay; George is `busy` meanwhile):
  1. Press R: the line is cast (animation, splash sound).
  2. Wait 2 to 6 s (random); the float bobs slightly.
  3. Bite: the float dips and the catch bar appears (capsule bar in the `FancyBar` look): a green zone and a marker that moves back and forth. Press the button while the marker is in the zone.
  4. Hit: the fish is caught ("Έπιασες: Πέρκα"; first time of a species: "Νέο είδος!"). Miss, or no press within 2.5 s of the bite: "Το ψάρι ξέφυγε". Esc cancels at any time.
- No cooldown.
- **Species** (data in `ShopData.JUNK` as `fish_*` entries with `rarity`, `zone` (share of the bar), `speed` (marker speed), `weight` (draw weight), optional `only` = "day" | "night"):

| Rarity | Fish | Zone | Sell price |
|---|---|---|---|
| common (5) | Γοβιός, Πέρκα, Σαζάνι, Κυπρίνος, Γριβάδι | wide (about 0.30) | 6 / 8 / 10 / 12 / 14 |
| uncommon (4) | Πέστροφα, Χέλι, Γλάνος, Λούτσος | medium (about 0.20) | 20 / 25 / 30 / 35 |
| rare (3) | Ηλιόψαρο (day only), Φεγγαρόψαρο (night only), Χρυσόψαρο του Αγίου | narrow (about 0.12) | 50 / 55 / 70 |
| legendary (1) | Ο Βασιλιάς της Λίμνης | very narrow (about 0.07), fast marker | 150 |

  Draw weights make common fish frequent and the legendary one very rare; day-only and night-only fish are skipped outside their hours (`DayNight` darkness).
- **Storage:** fish live in `Player.junk` (already saved); the market buys them automatically through the existing junk sell tab. New icon `fish` in `icons.gd`.

## The cook and the meals
- **NPC:** `QuestData.NPCS["thanasis"]` (Barbarian model, holds a mug) with `"shop": "kitchen"`, placed behind the counter in the tavern (`interiors.gd` DEFS `shopkeeper` entry); `ShopData.SHOPS["kitchen"]` (type `kitchen`, Greek greeting).
- **Window:** `ShopWindow` supports a `kitchen` shop: tab **Φαγητά** (buy with gold) and tab **Μαγείρεμα** (cook from fish). No sell tab.
- **Meals** (duration 10 minutes = one game day, the legendary one 15; all data in `ShopData.MEALS`):

| Meal | Cost | Buff (`Stats` keys) |
|---|---|---|
| Φασολάδα | 25 gold | hp_add +30 |
| Τυρόπιτα | 30 gold | speed_mult +0.08 |
| Κρέας με Πατάτες | 40 gold | damage_mult +0.10 |
| Τηγανητά Ψαράκια | 3 common fish + 5 gold | hp_add +50, regen +1 |
| Ψαρόσουπα | 2 uncommon fish + 8 gold | hp_add +80, regen +2, defense +0.05 |
| Ψητό του Αγίου | 1 rare fish + 10 gold | damage_mult +0.15, crit +0.10, speed_mult +0.10 |
| Γιορτινό του Βασιλιά | the legendary fish + 20 gold | damage_mult +0.20, defense +0.12, hp_add +100, crit +0.08, lifesteal +0.03 |

- Ingredients are by **rarity**, not species; cooking consumes the **cheapest** matching fish automatically so a valuable one is not lost by accident.

## Buff system
- `Player.food` = {"id", "time"} (empty when none); `Player.eat(meal_id)` sets it (replaces an existing meal, message in Greek) and calls `_recalc()`.
- `_recalc()` adds `stats.set_source("food", mods)` (empty dictionary when no meal) so the effects use the same path as equipment and talents (`max_health`, `sword_damage` and the keys read where used).
- The timer ticks in `_physics_process`; on expiry the source is cleared, `_recalc()` runs and a message tells the buff ended.
- `Player.buff_time("food")` returns the seconds left; the HUD shows a pill like the other buffs, labelled with the meal name.
- Not saved (like potion buffs).

## Journal
- `SaveGame` stores `fish_seen` (array of species ids) in the player block; loading restores it (missing key = empty, old saves work).
- The hero window (equipment tab) shows "Ψάρια: n/13".

## Audio
New recipes in `tools/audio/sfx.py`: `fish_cast`, `fish_bite`, `fish_catch`, `fish_escape`, `eat` (regenerated with `python tools/gen_audio.py sfx fish eat`, then `godot --headless --import`).

## Tests
- `tools/fishing_test.gd` (headless): species draw respects day and night; every species has a price, rarity, zone; the bar hit/miss decision; a full cast to catch flow driven through the `Fishing` API; the journal fills.
- `tools/kitchen_test.gd` (headless): cooking consumes the right fish (cheapest first) and gold; gold meals work; a meal changes `max_health` / `sword_damage` / stats and expires; a second meal replaces the first; `fish_seen` survives a save and load (real save and `.bak` backed up and restored).
- `tools/fishshot.gd` (windowed): screenshots of the dock, the bar and the cook's window, and an fps check.
- Existing regression drivers (`part3test`, `savetest`, `shoptest`, `keepertest`, `perftest`) still pass.

## Open risks
- The dock and the catch bar must reach the visual bar (stylised KayKit); if not, say so before continuing.
- The cook must stand where the tavern furniture leaves room (regulars stand at (2.5, -4.9) and (-1.8, -4.9)); verify by screenshot.
