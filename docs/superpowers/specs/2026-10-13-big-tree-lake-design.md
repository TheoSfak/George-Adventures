# The Great Tree and its lake: a walkable showcase area (design)

Date: 2026-10-13. A new place in the east of the village map, inspired by a picture Theodore showed (a stylised fantasy world: a giant tree with a treehouse village on a rock island, mossy plateaus, wooden rope bridges, hot-air balloons, turquoise water). Approved by Theodore in chat ("egrino proxora").

## Goal

One memorable, beautiful place to walk through: a turquoise lake with a central rock island carrying a giant tree and two small houses, four smaller islands, wooden bridges with rails and ropes, a stone ramp up to the central plateau, umbrella trees, flowers, one chest, and hot-air balloons drifting overhead. **No new gameplay systems.** It must look good in the game's own low-poly style and keep 60 fps.

**Honest limit:** the picture is a high-end render (lighting, detail). The aim is the same *composition and mood* in the KayKit style with code-built pieces, not a copy.

## Decisions already made (do not ask again)

- Role: a **walkable showcase place** (bridges, islands, the tree, balloons, a chest, small points of interest). No NPCs, quests or rideable balloon now (possible later).
- Place: **east of the village, centre (172, -40)**, between the watchtower (95, -79) and the lumber mill (95, 39).
- Height: **plateaus in a lake** reached by **stairs (ramps) and bridges**, up to about 8 m. The player is a plain `CharacterBody3D` (floor angle 45 degrees) so nothing changes in the controls. The lake is shallow wading water (visual only, like the pond): no swimming, drowning or falling out of the world.
- Technique: **hybrid**: islands, great tree, bridges and balloons are built in code (flat-shaded, vertex colours, KayKit-like palette), dressed with KayKit houses, trees and rocks.
- Names (Greek, changeable): map label **"Η Λίμνη του Αιωνόβιου"**, signpost **"Το Μεγάλο Δέντρο  →"**.

## Layout (world metres, `C` = (172, -40), y up, 0 = ground)

> The exact numbers were refined in the plan (`docs/superpowers/plans/2026-10-13-big-tree-lake.md`): islands spaced further apart so every bridge has a usable length, a lake of 36 x 30 m, the ramp built as a stone causeway around the central island, the moored balloon on the entry island. The plan's table is the one the code uses.

| Piece | Where (from C) | Size / height |
|---|---|---|
| Lake | centre C | water disc radius 28 m (slightly oval), surface y 0.10 |
| Central island | (0, 0) | radius 14 m, plateau top y 7.0 |
| Great tree | on the central island, offset (2, -1) | trunk radius 3.2 m, height 22 m; canopy radius 16 m at y 21 to 31 |
| Two houses | on a wooden deck around the trunk | KayKit `building_home_*` at scale 0.5, doors toward the west |
| Island 1 | (-22, 6), the entry island | radius 6, top y 2.6 |
| Island 2 | (-8, 24) | radius 5, top y 4.2, umbrella tree, **chest** |
| Island 3 | (20, 20) | radius 5.5, top y 5.0, bench and flowers |
| Island 4 | (22, -18) | radius 5, top y 3.4, umbrella trees |
| Shore bridge | west shore (-30, 5) -> island 1 | the way in from the village side |
| Bridges | island 1 -> central ramp foot, island 2 -> central, island 3 -> central, island 4 -> island 3, island 1 -> island 2 | width 2.2 m, sagging, plank deck, rope rails |
| Stone ramp | winds half a turn around the central island from its south-west foot to the top | width 2.6 m, slope about 8 degrees, banded like steps |
| Balloons | 4 drifting on slow ellipses 25 to 45 m high, 1 moored at the central plateau | envelope striped in 2 colours, basket |
| Surroundings | ring 28 to 44 m | flowers, KayKit rocks and trees as dressing; the mountain border ring behind (x > 215) is the backdrop |

The area is registered as occupied (`Village._occupy(172, -40, 44)`) so grass, flowers, forests and rocks are not scattered inside it.

## Pieces and how they are built

New script `scripts/great_tree.gd` (`class_name GreatTree`, `extends Node3D`), added by `Village._ready` like `VillageSquare`; data (centres, radii, heights, bridge endpoints) are constants at its top, the geometry is built in `_ready`.

- **Island** (`_build_island(center, radius, top_y)`): one `ArrayMesh`: a top disc whose rim is wobbled by noise (32 segments), a cliff wall of 3 rings down to y -1.6 (slight bulge, ragged), flat shading, **vertex colours**: moss green top with lighter patches, a lip of grass, brown-grey rock bands, moss streaks hanging from the rim. A trimesh collider (`ArrayMesh.create_trimesh_shape()`) on a `StaticBody3D`, layer 1.
- **Ramp** (`_build_ramp`): a ribbon mesh along a spiral path from a start point on the ground to the plateau, with step bands as colour/geometry notches and low walls; collision as one trimesh.
- **Great tree** (`_build_tree`): trunk = tapered 12-sided cylinder with bark bands and 6 root flares (curved cones) at the base; 3 thick limbs; canopy = 8 to 10 overlapping low-poly leaf blobs (sphere meshes, 10 x 6 segments, scaled, 3 greens, darker underside); hanging vines (thin double-sided quads). Collision: a cylinder around the trunk only (the canopy is far above).
- **Umbrella trees** (`_build_umbrella_tree`): thin bent trunk + flat canopy from 3 flattened spheres (the picture's mushroom-like trees). 5 to 6 of them.
- **Bridge** (`_build_bridge(a, b)`): endpoints are 3D points; the deck follows a shallow parabola sag; planks are one `MultiMeshInstance3D` (one draw call), two rope rails as thin ribbon meshes with posts at both ends. Collision: one `BoxShape3D` per 2.5 m of deck following the slope, plus two invisible rail boxes so George cannot fall off.
- **Houses and deck**: KayKit buildings via the Village `_place` helper, a ring-shaped wooden deck around the trunk (planks as a MultiMesh), lantern posts with emissive material (no real light).
- **Lake**: a cylinder water mesh with the existing `shaders/water.gdshader` and a more turquoise parameter set (deep `(0.05, 0.45, 0.55)`, shallow `(0.20, 0.80, 0.75)`) at y 0.10, a sandy `Terrain.add_patch` ring under it, reeds, lily pads and flowers like the pond (`Terrain.add_pond` style).
- **Balloons** (`scripts/balloon.gd`, `class_name Balloon`, `extends Node3D`): envelope = squashed-sphere mesh with a tiny stripe shader (`fract(UV.x * 8)` mixes two colours), basket box, four rope lines. `_process` moves it on an ellipse around C with a slow bob and turn (4 of them: negligible cost). One moored balloon sits still at the central plateau.
- **Chest**: one `Chest` on island 2 at its top height (`Chest.position.y = 4.2`); opened chests are already saved by their x, z.
- **Dressing**: KayKit `rock_single_*`, `tree_single_*`, flowers via `Terrain.add_flower`, `waterlily_*`, `waterplant_*` on the shore ring.

## Walking and collisions

Everything walkable has a collider on layer 1. Ramp and bridge slopes stay below 15 degrees. The player needs no code change. The lake water has no collider (George wades through it, as in the pond). Enemies: **no skeleton spawn within 44 m of C** (see the next section).

## Integration with the existing map

- **Spawns and the keg:** the quest barrel `["keg", 143.0, -29.0]` in `Village.QUEST_ITEMS` and the two spawns around it in `Enemies.SPAWNS` (`["minion", 138.0, -22.0]`, `["warrior", 148.0, -36.0]`) lie inside the area. They move west together: keg to `(124.0, -26.0)`, spawns to `(120.0, -18.0)` and `(130.0, -34.0)` (49 m or more from C). `Quests`/`QuestData` refer to the barrels by type, not by coordinate; `BOSS_AREAS` and other tables are not affected.
- **Signpost:** `Village.SIGNPOSTS` gets `["Το Μεγάλο Δέντρο  →", 112.0, -44.0, 270]` (on the way east of the market; the exact spot and rotation are fixed by a screenshot).
- **Big map:** `Minimap.PLACES` gets `["bigtree", 172.0, -40.0]` and `Strings.MAP_PLACES["bigtree"] = "Η Λίμνη του Αιωνόβιου"`.
- **Sound** (no new sounds): `SoundManager._ready` adds two positional loops, `water_loop` at `(172, 0.5, -40)` (range 10 to 50) and `wind_loop` at `(172, 22, -40)` high in the tree.
- **Day, night, weather:** nothing special is needed; the lake is an ordinary mesh. At night the lantern posts glow through emissive materials, plus at most **3 real lights** (the houses' doors and the central deck): the night budget is about 50 lights and each costs about 1 fps.
- **Save:** nothing new except the opened chest through the existing mechanism.

## Performance

Target 58 or more fps (60 expected) with `perftest` at the area by day and by night. Budget: 5 island meshes (about 1.5 k triangles each), the tree (about 6 k), bridges and decks as MultiMeshes (about 6 draw calls), balloons (5 meshes), dressing from the existing batched helpers. Rough total under 150 extra draw calls. If the frame rate drops, reduce the canopy blobs and vines first.

## Tests

- **`great_tree_test` (headless):** the area exists; the island colliders exist and a downward ray at each island centre hits at its `top_y`; **a path from the west shore to the central plateau exists**: a walker test moves a probe `CharacterBody3D` (capsule like George) with `move_and_slide` along the waypoints (shore bridge, ramp, plateau) and checks it arrives within 1.5 m of the tree foot without falling below y -0.5; the bridge rails block sideways movement; the chest is at island 2's height and opens; no `Enemies.SPAWNS` entry within 44 m of C; the quest barrel and its two spawns moved; the signpost and map place exist; no tree, rock or flower scattered inside the area (`_is_occupied`).
- **`greattreeshot` (windowed):** screenshots (the approach from the village, the shore bridge, the central island, from the tree top, the balloons, a view over the lake, night, rain) and `PERF` lines; run its parts as separate processes if the GPU is shared.
- **Regression:** `perftest` day and night, `questtest` (barrels), `sidequesttest`, `eventtest`, `minimaptest`, `savetest`, `keepertest`.

## Risks and how they are handled

- **Look** (islands look like blobs, the tree too small or too thin, bridges floaty): the screenshot task looks at every picture and tunes the numbers (profile of the cliff, colours, tree proportions); if something cannot be fixed it is reported to Theodore with the paths.
- **Walking over procedural colliders** (snagging on the lip of a plateau, steep ramp): the walker test catches stuck cases; the ramp slope is a constant that can be lowered.
- **Frame rate:** see Performance.
- **GPU memory on this PC is shared with other programs:** long windowed runs can crash; the shot driver is split in parts.

## Out of scope

A rideable or flyable balloon, NPCs, quests or a story for the place, swimming and diving, fish in this lake (the fishing spot stays at the pond), moving platforms, real floating islands high in the air, destructible parts.
