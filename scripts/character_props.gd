class_name CharacterProps
## The KayKit Adventurers models (Knight, Barbarian, Mage, Rogue, Rogue_Hooded) ship with every weapon,
## shield and accessory visible. NPCs and human enemies show only the ones they use.

const NODES: Array[String] = [
	"1H_Axe", "1H_Axe_Offhand", "2H_Axe", "Barbarian_Round_Shield", "Mug", "Barbarian_Hat",
	"Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff",
	"Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable",
	"1H_Sword", "1H_Sword_Offhand", "2H_Sword", "Badge_Shield", "Rectangle_Shield", "Spike_Shield",
]


## Hides every prop of the model that is not in `show` (names of nodes, e.g. ["1H_Axe", "Barbarian_Round_Shield"]).
static func apply(model: Node3D, show: Array) -> void:
	for n in model.find_children("*", "Node3D", true, false):
		if n.name in NODES:
			n.visible = n.name in show
