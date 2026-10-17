class_name Interiors
extends Node3D
## Building interiors. The houses of the village are solid models, so going inside
## teleports George to a furnished room far outside the map. Rooms are built on first
## use from the DEFS below (edit them to rearrange furniture). Everything is metres,
## (0, 0) = room centre, -Z = back wall, the door is on the +Z wall.

const FAR_AWAY := Vector3(2000.0, 0.0, 2000.0)
const ROOM_SPACING := 90.0
const WALL_THICKNESS := 0.6

const F := "res://assets/furniture/"
const I := "res://assets/items/"
const G := "res://assets/graveyard/"
const P := "res://assets/world/decoration/props/"
const C := "res://assets/characters/"

# furniture entry: [model, x, z, rotation in degrees, scale, height above floor (optional)]
# rotation 0 = faces +Z (toward the door); 90 faces +X; 180 faces the back wall; 270 faces -X.
# chest entry: [x, z, rotation, golden, gold_min, gold_max, potions]
const DEFS := {
	"george_cottage": {
		"size": Vector2(16, 13), "height": 4.5,
		"furniture": [
			[F + "bed_double_A.gltf", -5.2, -3.8, 0, 1.0],
			[F + "table_medium.gltf", 2.5, 0.5, 0, 1.0],
			[F + "chair_A_wood.gltf", 2.5, 2.4, 180, 1.0],
			[F + "chair_A_wood.gltf", 0.5, 0.5, 90, 1.0],
			[F + "cabinet_medium_decorated.gltf", 5.2, -1.8, 270, 1.0],
			[F + "shelf_B_large_decorated.gltf", 0.0, -6.1, 0, 1.0, 2.0],
			[F + "couch.gltf", -5.4, 2.2, 90, 1.0],
			[F + "rug_rectangle_A.gltf", 0.0, 1.8, 0, 1.5],
			[F + "lamp_standing.gltf", -6.8, -5.4, 0, 1.0],
			[I + "candle_lit.gltf.glb", 2.5, 0.5, 0, 1.0, 1.0],
			[P + "weaponrack.gltf", -6.6, -0.8, 90, 1.2],
		],
		"chests": [],
	},
	"home": {
		"size": Vector2(14, 12), "height": 4.2,
		"furniture": [
			[F + "bed_double_A.gltf", -4.6, -3.6, 0, 1.0],
			[F + "cabinet_medium_decorated.gltf", 1.5, -5.2, 0, 1.0],
			[F + "cabinet_small.gltf", 4.2, -5.4, 0, 1.0],
			[F + "table_medium.gltf", 3.2, 0.8, 0, 1.0],
			[F + "chair_A_wood.gltf", 3.2, 2.9, 180, 1.0],
			[F + "chair_A_wood.gltf", 5.4, 0.8, 270, 1.0],
			[F + "chair_A_wood.gltf", 1.0, 0.8, 90, 1.0],
			[F + "rug_rectangle_A.gltf", -1.0, 1.5, 0, 1.4],
			[F + "couch.gltf", -5.2, 2.6, 90, 1.0],
			[F + "lamp_standing.gltf", -6.2, -5.2, 0, 1.0],
			[F + "pictureframe_large_A.gltf", -2.0, -5.9, 0, 1.0, 2.2],
			[I + "candle_lit.gltf.glb", 3.2, 0.8, 0, 1.0, 1.0],
		],
		"chests": [[5.9, -2.6, 270, false, 6, 16, 0]],
	},
	"tavern": {
		"size": Vector2(22, 16), "height": 4.8,
		"furniture": [
			[F + "cabinet_medium.gltf", -4.0, -6.4, 0, 1.0],
			[F + "cabinet_medium.gltf", -2.0, -6.4, 0, 1.0],
			[F + "cabinet_medium.gltf", 0.0, -6.4, 0, 1.0],
			[F + "cabinet_medium.gltf", 2.0, -6.4, 0, 1.0],
			[F + "cabinet_medium.gltf", 4.0, -6.4, 0, 1.0],
			[F + "shelf_B_large_decorated.gltf", -3.0, -7.4, 0, 1.0, 2.0],
			[F + "shelf_B_large_decorated.gltf", 1.0, -7.4, 0, 1.0, 2.0],
			[F + "shelf_B_large.gltf", 4.0, -7.4, 0, 1.0, 2.3],
			[I + "keg_decorated.gltf.glb", -9.4, -6.6, 0, 0.55],
			[I + "keg.gltf.glb", -9.4, -4.6, 0, 0.55],
			[I + "keg.gltf.glb", -7.6, -6.9, 0, 0.55],
			[I + "barrel_large.gltf.glb", -9.6, -2.4, 0, 0.6],
			[F + "table_medium_long.gltf", -5.5, 0.5, 0, 1.0],
			[F + "table_medium_long.gltf", 5.5, 0.5, 0, 1.0],
			[F + "table_medium_long.gltf", -5.5, 5.0, 0, 1.0],
			[F + "table_medium_long.gltf", 5.5, 5.0, 0, 1.0],
			[F + "chair_stool_wood.gltf", -6.5, -1.4, 0, 1.0],
			[F + "chair_stool_wood.gltf", -4.5, -1.4, 0, 1.0],
			[F + "chair_stool_wood.gltf", -6.5, 2.4, 180, 1.0],
			[F + "chair_stool_wood.gltf", -4.5, 2.4, 180, 1.0],
			[F + "chair_stool_wood.gltf", 4.5, -1.4, 0, 1.0],
			[F + "chair_stool_wood.gltf", 6.5, -1.4, 0, 1.0],
			[F + "chair_stool_wood.gltf", 4.5, 2.4, 180, 1.0],
			[F + "chair_stool_wood.gltf", 6.5, 2.4, 180, 1.0],
			[F + "chair_B_wood.gltf", -5.5, 3.4, 0, 1.0],
			[F + "chair_B_wood.gltf", 5.5, 3.4, 0, 1.0],
			[F + "chair_B_wood.gltf", -5.5, 6.9, 180, 1.0],
			[F + "chair_B_wood.gltf", 5.5, 6.9, 180, 1.0],
			[F + "rug_rectangle_stripes_A.gltf", 0.0, 3.0, 0, 1.6],
			[I + "candle_lit.gltf.glb", -5.5, 0.5, 0, 1.0, 1.0],
			[I + "candle_lit.gltf.glb", 5.5, 0.5, 0, 1.0, 1.0],
			[C + "mug_full.gltf", -6.4, 0.2, 40, 0.8, 1.0],
			[C + "mug_full.gltf", -4.6, 0.9, 200, 0.8, 1.0],
			[C + "mug_full.gltf", 4.6, 0.2, 100, 0.8, 1.0],
			[C + "mug_full.gltf", 6.3, 0.8, 300, 0.8, 1.0],
			[C + "mug_full.gltf", -5.8, 5.3, 60, 0.8, 1.0],
			[C + "mug_full.gltf", 5.0, 4.7, 10, 0.8, 1.0],
			[C + "mug_full.gltf", -1.5, -6.0, 0, 0.8, 1.0],
			[C + "mug_full.gltf", 2.5, -6.0, 0, 0.8, 1.0],
			[I + "torch_mounted.gltf.glb", -10.6, -1.0, 90, 1.6, 2.6],
			[I + "torch_mounted.gltf.glb", 10.6, -1.0, 270, 1.6, 2.6],
		],
		"chests": [[9.4, -6.6, 270, false, 10, 25, 1]],
		# The cook behind the bar (the shopkeeper pattern of the market): [npc id, x, z, yaw in degrees]
		"shopkeeper": ["thanasis", 0.4, -5.3, 0],
		# Regulars: [model, x, z, yaw in degrees, "sit" | "stand"]. They drink beer and talk.
		"npcs": [
			[C + "Barbarian.glb", -6.5, -1.4, 0, "sit"],
			[C + "Rogue_Hooded.glb", -4.5, 2.4, 180, "sit"],
			[C + "Knight.glb", 4.5, -1.4, 0, "sit"],
			[C + "Rogue.glb", 6.5, 2.4, 180, "sit"],
			[C + "Barbarian.glb", 2.5, -4.9, 180, "stand"],
			[C + "Rogue.glb", -1.8, -4.9, 180, "stand"],
		],
		# Standing pairs that chat with each other: [[model, x, z, yaw], [model, x, z, yaw]]
		"pairs": [
			[[C + "Knight.glb", -0.9, 0.9, 90], [C + "Barbarian.glb", 0.9, 0.9, 270]],
		],
	},
	"church": {
		"size": Vector2(18, 26), "height": 7.5,
		"furniture": [
			[G + "shrine_candles.gltf", 0.0, -10.4, 0, 2.2],
			[G + "candle_triple.gltf", -3.2, -10.6, 0, 2.0],
			[G + "candle_triple.gltf", 3.2, -10.6, 0, 2.0],
			[I + "banner_blue.gltf.glb", -4.5, -12.4, 0, 1.4, 1.0],
			[I + "banner_red.gltf.glb", 4.5, -12.4, 0, 1.4, 1.0],
			[I + "column.gltf.glb", -7.6, -7.0, 0, 2.4],
			[I + "column.gltf.glb", 7.6, -7.0, 0, 2.4],
			[I + "column.gltf.glb", -7.6, 1.0, 0, 2.4],
			[I + "column.gltf.glb", 7.6, 1.0, 0, 2.4],
			[I + "column.gltf.glb", -7.6, 9.0, 0, 2.4],
			[I + "column.gltf.glb", 7.6, 9.0, 0, 2.4],
			[G + "bench.gltf", -3.4, -3.0, 0, 1.4],
			[G + "bench.gltf", 3.4, -3.0, 0, 1.4],
			[G + "bench.gltf", -3.4, 0.6, 0, 1.4],
			[G + "bench.gltf", 3.4, 0.6, 0, 1.4],
			[G + "bench.gltf", -3.4, 4.2, 0, 1.4],
			[G + "bench.gltf", 3.4, 4.2, 0, 1.4],
			[G + "bench.gltf", -3.4, 7.8, 0, 1.4],
			[G + "bench.gltf", 3.4, 7.8, 0, 1.4],
			[F + "rug_rectangle_stripes_B.gltf", 0.0, 1.0, 0, 2.2],
			[I + "torch_mounted.gltf.glb", -8.6, -4.0, 90, 2.0, 3.0],
			[I + "torch_mounted.gltf.glb", 8.6, -4.0, 270, 2.0, 3.0],
		],
		"chests": [[6.2, -10.8, 270, true, 20, 40, 1]],
		"respec": [0.0, -8.4],
	},
	"blacksmith": {
		"size": Vector2(16, 14), "height": 4.6,
		"furniture": [
			[P + "weaponrack.gltf", -5.8, -5.8, 0, 1.6],
			[P + "weaponrack.gltf", -2.8, -5.8, 0, 1.6],
			[P + "target.gltf", 6.0, -3.0, 270, 1.4],
			[F + "table_medium_long.gltf", 3.0, -5.2, 0, 1.0],
			[F + "table_medium_long.gltf", 0.0, 1.5, 0, 1.0],
			[I + "crates_stacked.gltf.glb", -6.5, -2.0, 90, 0.9],
			[I + "barrel_large.gltf.glb", -6.8, 2.0, 0, 0.6],
			[I + "barrel_large.gltf.glb", -6.8, 4.0, 0, 0.6],
			[I + "keg.gltf.glb", 6.4, 3.4, 0, 0.55],
			[P + "bucket_water.gltf", 4.5, 0.6, 0, 1.4],
			[P + "resource_stone.gltf", 3.0, 3.5, 0, 1.2],
			[I + "torch_mounted.gltf.glb", -7.6, 0.0, 90, 1.8, 2.6],
			[I + "torch_mounted.gltf.glb", 7.6, -6.0, 270, 1.8, 2.6],
		],
		"chests": [[6.8, -5.8, 270, false, 12, 28, 1]],
		"shopkeeper": ["nikitas_forge", 0.0, -0.9, 0],
	},
	"market": {
		"size": Vector2(20, 14), "height": 4.6,
		"furniture": [
			[F + "cabinet_medium_decorated.gltf", -6.0, -5.9, 0, 1.0],
			[F + "cabinet_medium.gltf", -4.0, -5.9, 0, 1.0],
			[F + "cabinet_small_decorated.gltf", -2.0, -5.9, 0, 1.0],
			[F + "shelf_A_big.gltf", 2.0, -6.7, 0, 1.0, 2.0],
			[F + "shelf_B_large_decorated.gltf", 5.0, -6.7, 0, 1.0, 2.0],
			[F + "table_medium_long.gltf", -3.0, 0.5, 0, 1.0],
			[F + "table_medium_long.gltf", 3.5, 0.5, 0, 1.0],
			[I + "crates_stacked.gltf.glb", 8.4, -4.8, 270, 0.9],
			[I + "crates_stacked.gltf.glb", 8.4, -2.2, 270, 0.9],
			[I + "keg.gltf.glb", -8.6, 3.0, 0, 0.55],
			[I + "keg_decorated.gltf.glb", -8.6, 5.0, 0, 0.55],
			[P + "sack.gltf", 7.8, 4.2, 40, 1.4],
			[P + "sack.gltf", 8.4, 5.2, 110, 1.4],
			[I + "candle_lit.gltf.glb", -3.0, 0.5, 0, 1.0, 1.0],
			[I + "torch_mounted.gltf.glb", -9.6, -2.0, 90, 1.8, 2.6],
		],
		"chests": [[-8.4, -5.8, 0, false, 15, 30, 0]],
		"shopkeeper": ["elena", 0.5, -2.2, 0],
	},
	"tower": {
		"size": Vector2(20, 18), "height": 5.8,
		"floor_color": Color(0.35, 0.37, 0.40), "wall_color": Color(0.48, 0.50, 0.54),
		"trim_color": Color(0.24, 0.25, 0.28), "ceiling_color": Color(0.20, 0.16, 0.12),
		"light_color": Color(1.0, 0.88, 0.65), "light_energy": 3.0,
		"furniture": [
			[I + "column.gltf.glb", -6.0, -4.0, 0, 2.4],
			[I + "column.gltf.glb", 6.0, -4.0, 0, 2.4],
			[I + "column.gltf.glb", -6.0, 3.0, 0, 2.4],
			[I + "column.gltf.glb", 6.0, 3.0, 0, 2.4],
			[I + "banner_blue.gltf.glb", -4.0, -8.6, 0, 1.8, 1.5],
			[I + "banner_blue.gltf.glb", 4.0, -8.6, 0, 1.8, 1.5],
			[F + "table_medium_long.gltf", 0.0, -3.5, 0, 1.3],
			[F + "chair_B_wood.gltf", 0.0, -5.2, 0, 1.2],
			[F + "book_set.gltf", 0.6, -3.5, 30, 1.0, 1.1],
			[I + "candle_lit.gltf.glb", -1.0, -3.5, 0, 1.0, 1.1],
			[F + "rug_rectangle_stripes_A.gltf", 0.0, 1.5, 0, 2.2],
			[P + "weaponrack.gltf", -8.4, -6.5, 90, 1.6],
			[P + "weaponrack.gltf", -8.4, -2.5, 90, 1.6],
			[P + "target.gltf", -8.4, 4.5, 90, 1.5],
			[P + "bucket_arrows.gltf", -7.5, 3.0, 0, 1.4],
			[F + "bed_single_B.gltf", 7.8, -6.5, 270, 1.1],
			[F + "cabinet_medium_decorated.gltf", 8.4, -2.5, 270, 1.1],
			[F + "shelf_B_large_decorated.gltf", 8.4, 2.0, 270, 1.1, 1.8],
			[I + "crates_stacked.gltf.glb", 7.8, 6.0, 180, 1.1],
			[I + "barrel_large.gltf.glb", -7.8, 6.5, 0, 0.7],
			[I + "torch_mounted.gltf.glb", -9.6, -1.0, 90, 2.0, 2.8],
			[I + "torch_mounted.gltf.glb", 9.6, -1.0, 270, 2.0, 2.8],
			[I + "torch_mounted.gltf.glb", -4.0, 8.6, 180, 2.0, 2.8],
			[I + "torch_mounted.gltf.glb", 4.0, 8.6, 180, 2.0, 2.8],
		],
		"chests": [[8.2, -4.5, 270, true, 80, 160, 2]],
		"npcs": [[C + "Knight.glb", 0.0, -1.8, 180, "stand"]],
	},
	"orc_castle": {
		"size": Vector2(26, 20), "height": 6.2,
		"floor_color": Color(0.24, 0.22, 0.21), "wall_color": Color(0.30, 0.28, 0.28),
		"trim_color": Color(0.18, 0.16, 0.15), "ceiling_color": Color(0.14, 0.11, 0.10),
		"light_color": Color(1.0, 0.50, 0.20), "light_energy": 3.2,
		"furniture": [
			[I + "column.gltf.glb", -7.5, -5.0, 0, 2.6],
			[I + "column.gltf.glb", 7.5, -5.0, 0, 2.6],
			[I + "column.gltf.glb", -7.5, 3.5, 0, 2.6],
			[I + "column.gltf.glb", 7.5, 3.5, 0, 2.6],
			[G + "bench_decorated.gltf", 0.0, -8.2, 0, 1.8],
			[I + "banner_red.gltf.glb", -3.5, -9.6, 0, 2.2, 1.2],
			[I + "banner_red.gltf.glb", 3.5, -9.6, 0, 2.2, 1.2],
			[G + "post_skull.gltf", -2.8, -7.5, 0, 1.6],
			[G + "post_skull.gltf", 2.8, -7.5, 0, 1.6],
			[F + "table_medium_long.gltf", 0.0, -1.0, 0, 1.4],
			[G + "skull_candle.gltf", 0.0, -1.0, 0, 1.3, 1.1],
			[F + "chair_A_wood.gltf", -2.5, -1.0, 90, 1.2],
			[F + "chair_A_wood.gltf", 2.5, -1.0, 270, 1.2],
			[F + "rug_rectangle_B.gltf", 0.0, -4.5, 0, 2.2],
			[I + "crates_stacked.gltf.glb", -11.2, -6.5, 90, 1.2],
			[I + "barrel_large.gltf.glb", -11.5, -3.5, 0, 0.8],
			[I + "keg_decorated.gltf.glb", -10.0, -1.5, 45, 0.7],
			[P + "weaponrack.gltf", 11.4, -6.5, 270, 1.8],
			[P + "weaponrack.gltf", 11.4, -2.5, 270, 1.8],
			[P + "resource_stone.gltf", 10.5, 6.0, 0, 1.5],
			[G + "skull.gltf", -5.0, 5.0, 45, 1.5],
			[G + "ribcage.gltf", 5.5, 5.5, 120, 1.4],
			[G + "bone_A.gltf", -6.5, 6.5, 30, 1.5],
			[I + "torch_mounted.gltf.glb", -12.6, -2.0, 90, 2.2, 3.0],
			[I + "torch_mounted.gltf.glb", 12.6, -2.0, 270, 2.2, 3.0],
			[I + "torch_mounted.gltf.glb", -6.0, 9.6, 180, 2.2, 3.0],
			[I + "torch_mounted.gltf.glb", 6.0, 9.6, 180, 2.2, 3.0],
		],
		"chests": [
			[11.0, -8.2, 270, true, 250, 450, 3],
			[-11.2, 5.0, 90, false, 60, 130, 1],
		],
	},
	"shadow_castle": {
		"size": Vector2(28, 22), "height": 7.2,
		"floor_color": Color(0.15, 0.14, 0.18), "wall_color": Color(0.20, 0.18, 0.25),
		"trim_color": Color(0.12, 0.10, 0.15), "ceiling_color": Color(0.10, 0.08, 0.12),
		"light_color": Color(0.72, 0.48, 0.95), "light_energy": 3.2,
		"furniture": [
			[I + "column.gltf.glb", -8.5, -6.0, 0, 3.0],
			[I + "column.gltf.glb", 8.5, -6.0, 0, 3.0],
			[I + "column.gltf.glb", -8.5, 0.0, 0, 3.0],
			[I + "column.gltf.glb", 8.5, 0.0, 0, 3.0],
			[I + "column.gltf.glb", -8.5, 6.0, 0, 3.0],
			[I + "column.gltf.glb", 8.5, 6.0, 0, 3.0],
			[G + "bench_decorated.gltf", 0.0, -9.5, 0, 2.0],
			[G + "shrine_candles.gltf", 0.0, -10.5, 0, 2.4],
			[G + "candle_triple.gltf", -4.0, -9.8, 0, 2.2],
			[G + "candle_triple.gltf", 4.0, -9.8, 0, 2.2],
			[I + "banner_red.gltf.glb", -6.5, -10.5, 0, 2.4, 1.5],
			[I + "banner_red.gltf.glb", 6.5, -10.5, 0, 2.4, 1.5],
			[G + "coffin_decorated.gltf", -11.8, -5.0, 90, 1.5],
			[G + "coffin_decorated.gltf", 11.8, -5.0, 270, 1.5],
			[G + "shrine.gltf", -11.8, 3.0, 90, 1.8],
			[G + "shrine.gltf", 11.8, 3.0, 270, 1.8],
			[G + "skull_candle.gltf", -11.8, 3.0, 90, 1.5, 1.2],
			[G + "skull_candle.gltf", 11.8, 3.0, 270, 1.5, 1.2],
			[F + "rug_rectangle_stripes_B.gltf", 0.0, 0.0, 0, 2.8],
			[I + "torch_mounted.gltf.glb", -13.6, 0.0, 90, 2.4, 3.5],
			[I + "torch_mounted.gltf.glb", 13.6, 0.0, 270, 2.4, 3.5],
			[I + "torch_mounted.gltf.glb", -7.0, 10.6, 180, 2.4, 3.5],
			[I + "torch_mounted.gltf.glb", 7.0, 10.6, 180, 2.4, 3.5],
		],
		"chests": [[0.0, -7.2, 180, true, 350, 650, 4]],
	},
}

var _rooms := {}          # door id -> {"origin": Vector3, "size": Vector2}
var _count := 0
var _saved_env := {}
var _inside := false
var current_door := ""         # id of the door George went through, "" outside
var current_kind := ""        # kind of the room George is in ("tavern", "church"...), "" outside
var _saved_zoom := 7.0
const REGION_IDS: Array[String] = ["frontier", "ashvalley", "temple"]
var _in_region := false            # George is in a region (the Frontier or the Ash Valley: outdoors, far away from the village)
var _region_outside := {}          # {"pos": Vector3, "heading": float} where the way back leads
var _regions := {}                 # region id -> the region node, built on the first visit


func _ready() -> void:
	add_to_group("interiors")
	_hook_player.call_deferred()


## When George dies in the catacombs he wakes up in the village: put the outdoor light back.
func _hook_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.respawned.connect(_on_player_respawned.bind(player))


func _on_player_respawned(player: Player) -> void:
	if _in_region:                    # died in a region: he wakes in the village, nothing else to restore
		_in_region = false
		current_kind = ""
		return
	if not _inside:
		return
	_set_indoor_light(false)
	player.get_node("CameraRig/SpringArm3D").spring_length = _saved_zoom
	_inside = false
	current_kind = ""
	current_door = ""


func is_inside() -> bool:
	return _inside


## True while George is in an outdoor region (the Frontier or the Ash Valley; current_kind says which). It is outdoors (sun, sky and clock keep running),
## so is_inside() stays false there; ask in_region() for the few things that differ.
func in_region() -> bool:
	return _in_region


## Where the door of the current room leads outside (used by the save game).
func exit_position() -> Vector3:
	return _rooms[current_door]["outside_pos"] if _rooms.has(current_door) else Vector3(0, 0.05, 16)


## Called from a door outside. outside_pos / outside_heading is where George stands
## again when he comes back out.
func enter(door_id: String, kind: String, outside_pos: Vector3, outside_heading: float, player: Player) -> void:
	if player.busy:
		return
	player.busy = true
	var hud := get_tree().get_first_node_in_group("hud")
	Sfx.ui("door_open")
	await hud.fade_out(0.3)
	if not _rooms.has(door_id):
		if kind == "catacombs":
			await _build_catacombs(door_id, outside_pos, outside_heading)
		else:
			_build_room(door_id, kind, outside_pos, outside_heading)
	var room: Dictionary = _rooms[door_id]
	var size: Vector2 = room["size"]
	_set_indoor_light(true, kind)
	player.teleport(room["spawn"] if room.has("spawn") else room["origin"] + Vector3(0, 0.05, size.y / 2.0 - 4.4), PI)
	_saved_zoom = player.get_node("CameraRig/SpringArm3D").spring_length
	player.get_node("CameraRig/SpringArm3D").spring_length = 6.2 if kind == "catacombs" else (6.5 if (kind in ["tower", "orc_castle", "shadow_castle"]) else 4.6)   # castles are grand halls
	_rooms[door_id]["region"] = current_kind if _in_region else ""
	_inside = true
	current_kind = kind
	current_door = door_id
	await hud.fade_in(0.3)
	player.busy = false
	if kind == "catacombs":
		_report_reach("catacombs")

func _report_reach(place: String) -> void:
	var q: Node = get_tree().root.get_node_or_null("Quests")
	if q != null and q.has_method("report_reach"):
		q.call("report_reach", place)


## The node of a region that is built on the first visit ("frontier", "ashvalley").
func _new_region(region_id: String) -> Node3D:
	match region_id:
		"frontier":
			return Frontier.new()
		"ashvalley":
			return AshValley.new()
		"temple":
			return (load("res://scripts/temple_interior.gd") as GDScript).new()
	return null


## Where the stone arch of a region stands in Agios Vlasis (the save game puts George back there).
static func region_gate(region_id: String) -> Vector3:
	match region_id:
		"frontier":
			return Frontier.VILLAGE_GATE
		"ashvalley":
			return AshValley.VILLAGE_GATE
		"temple":
			return AshValley.wp(0.0, -196.0)
	return Vector3.ZERO


## Teleports George to a far-away outdoor region ("frontier" or "ashvalley") with a fade. Unlike
## enter() it leaves the light alone. outside_pos / outside_heading is where he stands again when
## he comes back; spawn_override / spawn_heading place him somewhere else than the entry (loading a save).
func enter_region(region_id: String, outside_pos: Vector3, outside_heading: float, player: Player, spawn_override: Vector3 = Vector3.INF, spawn_heading: float = PI) -> void:
	if player.busy or not region_id in REGION_IDS:
		return
	player.busy = true
	var hud := get_tree().get_first_node_in_group("hud")
	Sfx.ui("door_open")
	await hud.fade_out(0.3)
	if not _regions.has(region_id):
		var region := _new_region(region_id)
		match region_id:
			"frontier": region.name = "Frontier"
			"ashvalley": region.name = "AshValley"
			"temple": region.name = "TempleSanctum"
		region.exit_action = func(p): exit_region(p)
		add_child(region)
		_regions[region_id] = region
		await region.build()
	var built: Node3D = _regions[region_id]
	_region_outside[region_id] = {"pos": outside_pos, "heading": outside_heading}
	player.teleport(built.spawn_point() if spawn_override == Vector3.INF else spawn_override, spawn_heading)
	_in_region = true
	current_kind = region_id
	await hud.fade_in(0.3)
	player.busy = false
	_report_reach(region_id)


func exit_region(player: Player) -> void:
	if player.busy:
		return
	if not _in_region:
		if current_kind != "":
			_in_region = true
		else:
			for r_id in REGION_IDS:
				var r: Node3D = _regions.get(r_id)
				if r != null and is_instance_valid(r) and player.global_position.distance_to(r.global_position) < 3000.0:
					current_kind = r_id
					_in_region = true
					break
	if not _in_region:
		return
	player.busy = true
	var hud := get_tree().get_first_node_in_group("hud")
	Sfx.ui("door_close")
	await hud.fade_out(0.3)
	var prev_kind := current_kind
	var out_info: Dictionary = _region_outside.get(prev_kind, {})
	var target_pos: Vector3 = out_info.get("pos", Vector3.ZERO)
	var target_heading: float = float(out_info.get("heading", 0.0))
	if target_pos == Vector3.ZERO:
		if prev_kind == "temple":
			target_pos = AshValley.wp(0.0, -195.0, 0.05)
		elif prev_kind == "ashvalley":
			target_pos = AshValley.VILLAGE_GATE + Vector3(0, 0.05, 5.0)
		elif prev_kind == "frontier":
			target_pos = Frontier.VILLAGE_GATE + Vector3(0, 0.05, 5.0)
	player.teleport(target_pos + Vector3(0, 0.05, 0), target_heading)
	if prev_kind == "temple":
		_in_region = true
		current_kind = "ashvalley"
		_report_reach("ashvalley")
	else:
		_in_region = false
		current_kind = ""
		_report_reach("village")
	await hud.fade_in(0.3)
	player.busy = false


func _exit_room(door_id: String, player: Player) -> void:
	if player.busy:
		return
	player.busy = true
	var hud := get_tree().get_first_node_in_group("hud")
	Sfx.ui("door_close")
	await hud.fade_out(0.3)
	var room: Dictionary = _rooms[door_id]
	_set_indoor_light(false)
	player.get_node("CameraRig/SpringArm3D").spring_length = _saved_zoom
	player.teleport(room["outside_pos"] + Vector3(0, 0.05, 0), room["outside_heading"])
	_inside = false
	current_door = ""
	if room.get("region", "") != "":
		_in_region = true
		current_kind = room["region"]
		_report_reach(current_kind)
	else:
		_in_region = false
		current_kind = ""
	await hud.fade_in(0.3)
	player.busy = false


## Indoors: no sun, no fog, warm dim ambient light. Restored when going back out.
func _set_indoor_light(indoor: bool, kind: String = "") -> void:
	var world_env := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	var sun := get_tree().root.find_child("Sun", true, false) as Light3D
	if world_env == null:
		return
	var env := world_env.environment
	if indoor:
		_saved_env = {
			"source": env.ambient_light_source, "color": env.ambient_light_color,
			"energy": env.ambient_light_energy, "fog": env.fog_enabled, "bg": env.background_mode,
		}
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.05, 0.04, 0.03)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.85, 0.72, 0.58)
		env.ambient_light_energy = 0.85
		if kind == "catacombs":                  # cold, dark stone lit by torches
			env.background_color = Color(0.01, 0.01, 0.02)
			env.ambient_light_color = Color(0.42, 0.48, 0.70)
			env.ambient_light_energy = 0.55
		elif kind == "orc_castle":
			env.background_color = Color(0.03, 0.02, 0.01)
			env.ambient_light_color = Color(0.75, 0.45, 0.25)
			env.ambient_light_energy = 0.75
		elif kind == "shadow_castle":
			env.background_color = Color(0.02, 0.01, 0.03)
			env.ambient_light_color = Color(0.55, 0.35, 0.75)
			env.ambient_light_energy = 0.65
		elif kind == "tower":
			env.background_color = Color(0.04, 0.03, 0.03)
			env.ambient_light_color = Color(0.78, 0.72, 0.62)
			env.ambient_light_energy = 0.80
		env.fog_enabled = false
		if sun:
			sun.visible = false
	elif not _saved_env.is_empty():
		env.background_mode = _saved_env["bg"]
		env.ambient_light_source = _saved_env["source"]
		env.ambient_light_color = _saved_env["color"]
		env.ambient_light_energy = _saved_env["energy"]
		env.fog_enabled = _saved_env["fog"]
		if sun:
			sun.visible = true


# ----------------------------------------------------------------- building ----

## Every room stands at a fixed place that comes from its door id ("home_3" is building 3), not from the order in
## which the doors were opened: the save game remembers an opened chest by its position, so the position of a
## chest inside a house must be the same in every session.
func _slot_for(door_id: String) -> int:
	if door_id.begins_with("george_cottage"):
		return 50
	if door_id.begins_with("orc_castle"):
		return 51
	if door_id.begins_with("shadow_castle"):
		return 52
	if door_id.begins_with("tower"):
		return 53
	var tail := door_id.get_slice("_", door_id.get_slice_count("_") - 1)
	if tail.is_valid_int():
		return int(tail)
	_count += 1                         # an id without a number (none today): behind the fixed rooms, in order
	return 1000 + _count


func _build_room(door_id: String, kind: String, outside_pos: Vector3, outside_heading: float) -> void:
	var def: Dictionary = DEFS[kind]
	var size: Vector2 = def["size"]
	var h: float = def["height"]
	var origin := FAR_AWAY + Vector3(ROOM_SPACING * _slot_for(door_id), 0.0, 0.0)
	_rooms[door_id] = {"origin": origin, "size": size, "outside_pos": outside_pos, "outside_heading": outside_heading}

	var root := Node3D.new()
	root.name = "Room_" + door_id
	add_child(root)

	var floor_col: Color = def.get("floor_color", Color(0.64, 0.46, 0.29))
	var wall_col: Color = def.get("wall_color", Color(0.88, 0.80, 0.64))
	var trim_col: Color = def.get("trim_color", Color(0.40, 0.27, 0.16))
	var ceiling_col: Color = def.get("ceiling_color", Color(0.36, 0.25, 0.16))

	var floor_mat := _material(floor_col, def.get("floor_roughness", 0.85))
	var wall_mat := _material(wall_col, def.get("wall_roughness", 0.95))
	var trim_mat := _material(trim_col, def.get("trim_roughness", 0.8))
	var ceiling_mat := _material(ceiling_col, def.get("ceiling_roughness", 0.9))

	# Floor, ceiling and the four walls are solid (the spring-arm camera stays inside too).
	_box(root, origin + Vector3(0, -0.25, 0), Vector3(size.x + 2, 0.5, size.y + 2), floor_mat, true)
	_box(root, origin + Vector3(0, h + 0.25, 0), Vector3(size.x + 2, 0.5, size.y + 2), ceiling_mat, true)
	var t := WALL_THICKNESS
	_box(root, origin + Vector3(0, h / 2, -size.y / 2 - t / 2), Vector3(size.x + 2 * t, h, t), wall_mat, true)
	_box(root, origin + Vector3(0, h / 2, size.y / 2 + t / 2), Vector3(size.x + 2 * t, h, t), wall_mat, true)
	_box(root, origin + Vector3(-size.x / 2 - t / 2, h / 2, 0), Vector3(t, h, size.y), wall_mat, true)
	_box(root, origin + Vector3(size.x / 2 + t / 2, h / 2, 0), Vector3(t, h, size.y), wall_mat, true)
	# Wooden panelling along the lower wall and ceiling beams for a cosy look.
	var pan := 1.1
	_box(root, origin + Vector3(0, pan / 2, -size.y / 2 + 0.1), Vector3(size.x, pan, 0.2), trim_mat, false)
	_box(root, origin + Vector3(0, pan / 2, size.y / 2 - 0.1), Vector3(size.x, pan, 0.2), trim_mat, false)
	_box(root, origin + Vector3(-size.x / 2 + 0.1, pan / 2, 0), Vector3(0.2, pan, size.y), trim_mat, false)
	_box(root, origin + Vector3(size.x / 2 - 0.1, pan / 2, 0), Vector3(0.2, pan, size.y), trim_mat, false)
	var beams := int(size.y / 4.0)
	for i in beams:
		var z := -size.y / 2 + (i + 0.5) * size.y / beams
		_box(root, origin + Vector3(0, h - 0.2, z), Vector3(size.x, 0.4, 0.5), trim_mat, false)

	# Lights
	var cols := maxi(1, int(size.x / 8.0))
	var rows := maxi(1, int(size.y / 8.0))
	for cx in cols:
		for cz in rows:
			var light := OmniLight3D.new()
			light.light_color = def.get("light_color", Color(1.0, 0.82, 0.55))
			light.light_energy = def.get("light_energy", 2.8)
			light.omni_range = maxf(size.x, size.y) * 0.6
			light.position = origin + Vector3(-size.x / 2 + (cx + 0.5) * size.x / cols, h - 0.9, -size.y / 2 + (cz + 0.5) * size.y / rows)
			root.add_child(light)

	# Furniture
	for f in def["furniture"]:
		var pos := origin + Vector3(f[1], f[5] if f.size() > 5 else 0.0, f[2])
		var model := (load(f[0]) as PackedScene).instantiate() as Node3D
		model.position = pos
		model.rotation_degrees.y = f[3]
		model.scale = Vector3.ONE * f[4]
		root.add_child(model)
		if (f.size() <= 5) and not (f[0] as String).contains("rug") and not (f[0] as String).contains("candle"):
			collider_for(model)

	# Tavern regulars
	for n in def.get("npcs", []):
		_make_regular(root, origin, n[0], n[1], n[2], n[3], Villager.Mode.SIT if n[4] == "sit" else Villager.Mode.STAND)
	for pair in def.get("pairs", []):
		var a := _make_regular(root, origin, pair[0][0], pair[0][1], pair[0][2], pair[0][3], Villager.Mode.CHAT)
		var b := _make_regular(root, origin, pair[1][0], pair[1][1], pair[1][2], pair[1][3], Villager.Mode.CHAT)
		for v in [a, b]:
			v.conversations = VillagerData.TAVERN_CONVERSATIONS
		a.partner = b
		b.partner = a
		a.lead = true

	# Shopkeeper: [npc id from quest_data.gd, x, z, yaw in degrees]
	if def.has("shopkeeper"):
		var k: Array = def["shopkeeper"]
		var keeper := Npc.new()
		keeper.npc_id = k[0]
		keeper.rest_yaw = deg_to_rad(k[3])
		keeper.position = origin + Vector3(k[1], 0.05, k[2])
		root.add_child(keeper)

	# Prayer spot where George can take his talent points back: [x, z]
	if def.has("respec"):
		var spot := InteractSpot.make("", func(p): p.respec(), 3.0)
		spot.prompt_func = func():
			var pl := get_tree().get_first_node_in_group("player") as Player
			return Strings.PROMPT_RESPEC % (pl.respec_cost() if pl else 0)
		spot.position = origin + Vector3(def["respec"][0], 0.0, def["respec"][1])
		root.add_child(spot)

	# Chests
	for c in def["chests"]:
		var chest := Chest.new()
		chest.golden = c[3]
		chest.gold_min = c[4]
		chest.gold_max = c[5]
		chest.potions = c[6]
		chest.position = origin + Vector3(c[0], 0, c[1])
		chest.rotation_degrees.y = c[2]
		root.add_child(chest)
		if SaveGame.opened_chests.has(SaveGame.key_for(chest.position)):
			chest.mark_opened()                  # opened in an earlier session

	if kind == "george_cottage":
		var stash_script = load("res://scripts/personal_stash.gd")
		var stash_node: Node3D = stash_script.new()
		stash_node.position = origin + Vector3(5.2, 0.0, -4.5)
		stash_node.rotation_degrees.y = 180.0
		root.add_child(stash_node)

		var trophy_script = load("res://scripts/trophy_wall.gd")
		var trophy_node: Node3D = trophy_script.new()
		trophy_node.position = origin + Vector3(0.0, 1.8, -size.y / 2.0 + 0.15)
		root.add_child(trophy_node)

		var bed_spot := InteractSpot.make(
			"[R] Ανάπαυση & Ύπνος (Πλήρης Θεραπεία)",
			func(p: Player):
				p.health = p.max_health
				var daynight := get_tree().get_first_node_in_group("daynight") as DayNight
				if daynight != null:
					daynight.time_of_day = 8.0
				p.message.emit("Ξεκουράστηκες στο κρεβάτι σου! Η υγεία σου αποκαταστάθηκε πλήρως.")
				Sfx.ui("quest_complete"),
			3.2
		)
		bed_spot.position = origin + Vector3(-5.2, 0.5, -3.8)
		root.add_child(bed_spot)

	# The way out
	var door_z := size.y / 2
	_box(root, origin + Vector3(0, 1.7, door_z - 0.15), Vector3(2.6, 3.4, 0.3), _material(Color(0.30, 0.18, 0.09), 0.8), false)
	_box(root, origin + Vector3(0, 3.55, door_z - 0.15), Vector3(3.2, 0.3, 0.4), trim_mat, false)
	_box(root, origin + Vector3(-1.45, 1.75, door_z - 0.15), Vector3(0.3, 3.5, 0.4), trim_mat, false)
	_box(root, origin + Vector3(1.45, 1.75, door_z - 0.15), Vector3(0.3, 3.5, 0.4), trim_mat, false)
	var exit_spot := InteractSpot.make(Strings.PROMPT_EXIT, func(p): _exit_room(door_id, p), 2.4)
	exit_spot.position = origin + Vector3(0, 0, door_z - 0.6)
	root.add_child(exit_spot)


## The catacombs below the old crypt: one big level built from catacombs.gd on the first visit.
func _build_catacombs(door_id: String, outside_pos: Vector3, outside_heading: float) -> void:
	var level := Catacombs.new()
	level.name = "Catacombs"
	level.exit_action = func(p): _exit_room(door_id, p)
	add_child(level)
	_rooms[door_id] = {
		"origin": Catacombs.ORIGIN, "size": Vector2(Catacombs.GRID) * Catacombs.CELL,
		"outside_pos": outside_pos, "outside_heading": outside_heading, "spawn": level.spawn_point(),
	}
	await level.build()


var _regulars := 0


func _make_regular(parent: Node, origin: Vector3, model: String, x: float, z: float, yaw_deg: float, mode: int) -> Villager:
	var v := Villager.new()
	v.model_path = model
	v.mode = mode
	v.holds_mug = true
	v.rest_yaw = deg_to_rad(yaw_deg)
	v.display_name = VillagerData.name_for(model, _regulars * 5 + 3)
	v.bubble_lines = VillagerData.DRINK_LINES
	v.talk_lines = VillagerData.DRINK_LINES + [VillagerData.GOSSIP[(_regulars * 3) % VillagerData.GOSSIP.size()]]
	_regulars += 1
	v.position = origin + Vector3(x, 0.05, z)
	parent.add_child(v)
	return v


func _material(color: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func _box(parent: Node, pos: Vector3, size: Vector3, mat: Material, solid: bool) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		mi.add_child(body)


## A box collider around a furniture model so George cannot walk through it.
## The body is a child of the model, so it inherits the model's scale and rotation.
static func collider_for(model: Node3D) -> void:
	var have := false
	var box := AABB()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var t := Transform3D.IDENTITY   # mesh -> model-local space
		var n: Node = mi
		while n != model and n != null:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		var a: AABB = t * mi.get_aabb()
		box = a if not have else box.merge(a)
		have = true
	if not have or box.size.y < 0.3:
		return
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = box.size * 0.9
	shape.shape = bs
	body.add_child(shape)
	body.position = box.get_center()
	model.add_child(body)
