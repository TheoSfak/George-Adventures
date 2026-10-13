# Horse / mount — design

Date: 2026-10-13. Backlog item D: George rides a horse on the big map.

## Goal
Crossing the ~200 m map on foot is slow. Give George a horse that makes travel faster, without touching combat balance.

## Decisions (made with Theodore)
- **Unlock:** George buys the horse from a stable keeper for gold (no quest).
- **Summon anywhere (WoW style):** one key mounts and dismounts; the horse appears under George. There is no horse to walk back to.
- **Travel only:** a hit on George, or an attack or skill key, dismounts him; he cannot mount while a skeleton is chasing him. Combat is unchanged.
- **Model:** the free CC0 low-poly horse of Quaternius' "Farm Animals Animated" pack (itch.io "LowPoly Animated Animals", file "Farm Animals Animated by Quaternius.zip", 6.6 MB, CC0), animations Idle, Walk, WalkSlow, Run, Jump, Death. Downloaded on 2026-10-13 with Theodore's approval; only `Horse.fbx` goes into the project.

## Design

### Rules (`scripts/mount_rules.gd`, `class_name MountRules`)
Pure functions, no scene access (tests type-reference it).
- `SPEED_FACTOR := 1.8`, `PRICE := 350`, `MIN_LEVEL := 5`.
- `can_buy(level, gold, owned) -> bool`.
- `block_reason(owned, indoors, busy, dead, stunned, chased) -> String`: `""` when George may mount, else a short id (`"not_owned"`, `"indoors"`, `"busy"`, `"dead"`, `"stunned"`, `"chased"`) that the caller maps to a Greek message.
- `chased(states: Array, distances: Array) -> bool`: true when a hostile skeleton within 30 m is in the CHASE or ATTACK state.

### Riding (`scripts/player.gd`, new `scripts/horse.gd`)
- `Player.horse_owned: bool` (saved as `player.horse_owned`), `Player.mounted: bool` (not saved), `Player.toggle_mount()`, `Player.mount()`, `Player.dismount(reason := "")`, signal `mount_changed(mounted)`.
- New input action `mount`, key G by default (checked free in `inputs.gd`; rebindable in the settings page; listed in `Strings.CONTROLS_HELP`; gamepad: none).
- `Horse` (`horse.gd`, a `Node3D`) instances `assets/animals/Horse.fbx`, scales it to a believable size (about 2.3 m long), plays Idle, Walk or Run by the speed it is given, Jump while George is in the air. It is a child of the player's model root so it follows his heading; George's model plays `Sit_Chair_Idle` and is lifted to sit on its back.
- While mounted: `speed *= MountRules.SPEED_FACTOR` in `_physics_process`, camera height + 0.6 m, footsteps use `footstep_hoof` instead of the ground sound.
- Dismount triggers: the key; `Player.take_damage` (any hit that reaches George); the `attack` action, any `slot_N` action and `block` (the press only dismounts); `Interiors.enter`/`enter_region` and a catacombs entry (via `Player.busy`/the interiors node calling `dismount`); death; `busy` becoming true (dialogue, shop, fishing).
- Mounting is refused (Greek message from `Strings`) by `MountRules.block_reason`.
- Allowed in the open village, the Frontier and during invasions.

### Stable and keeper
- `Village._build_stable()`: a small stable yard on open ground near the village (position found with a probe like `passgateprobe`, registered with `_occupy`), made from the existing props (crates, pallets, barrels, sacks) in a paddock shape with the real horse standing in it (Idle).
- NPC **Μανώλης ο Ιπποκόμος** (`QuestData.NPCS["manolis"]`, model `Barbarian.glb`, `"shop": "stable"`, no quests), standing at the stable gate (outdoors, so he is placed by `village.gd`, not by `interiors.gd`).
- `ShopData.SHOPS["stable"]`: title "Στάβλος", greeting in Greek, one stock entry `{"type": "mount", "price": MountRules.PRICE, "level": MountRules.MIN_LEVEL}`, `"buys": ""`. `shop_window.gd` shows it as a row "Άλογο" with the price, and as "Έχεις ήδη άλογο" once `horse_owned` (a small new item type `mount`; buying calls `Player.spend_gold` and sets `horse_owned`).
- The big map names the place (`Strings`, `minimap.gd` place list).

### Sound
Two new synthesized sounds in `tools/audio/sfx.py`: `footstep_hoof` (3 variants) and `horse_whinny`; regenerate with `python tools/gen_audio.py sfx`, then `godot --headless --import`. Hoofbeats play as footsteps while mounted; the whinny plays on mounting. Verified numerically only (nobody has heard them).

### Credits
A line for the Quaternius pack (CC0, itch.io URL) in `THIRD_PARTY_NOTICES.md`.

### Out of scope
Fighting mounted, stamina, horse colours or upgrades, a horse that stays where it was left, the other animals of the pack (kept in the zip, unused: a possible later idea for ambient animals).

## Strings (Greek, `strings_el.gd`)
Messages for the six block reasons, "Ανέβηκες στο άλογο" / "Κατέβηκες από το άλογο", purchase message, the stable name for the map, the controls-help line for the mount key, the shop row texts.

## Testing
- `mount_rules_test` (headless, pure): price/level/gold, each block reason, `chased`.
- `mount_world_test` (headless, real world): buy the horse at the stable shop, mount, speed factor, each dismount trigger (key, hit, attack, door, death), each block reason (indoors, chased, busy), saving keeps `horse_owned` and not `mounted`.
- `mountshot` (windowed): screenshots of the stable, George riding, and a gallop, fps.
- Re-run `savetest`, `shoptest`, `keepertest`, `eventtest`, `perftest`.
