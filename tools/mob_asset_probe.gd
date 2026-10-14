extends SceneTree
## Lists, for every character model in the project, its weapon/prop nodes and the animations a mob would need:
##   godot --path . --headless --script tools/mob_asset_probe.gd
const MODELS := [
	"res://assets/characters/Knight.glb", "res://assets/characters/Barbarian.glb", "res://assets/characters/Mage.glb",
	"res://assets/characters/Rogue.glb", "res://assets/characters/Rogue_Hooded.glb",
	"res://assets/characters/Skeleton_Warrior.glb", "res://assets/characters/Skeleton_Minion.glb",
	"res://assets/characters/Skeleton_Rogue.glb", "res://assets/characters/Skeleton_Mage.glb",
]
const NEEDED := ["Idle", "Walking_D_Skeletons", "Running_A", "Walking_Backwards", "Hit_A", "Death_A", "Death_B",
		"1H_Melee_Attack_Chop", "1H_Melee_Attack_Slice_Horizontal", "2H_Melee_Attack_Chop", "2H_Melee_Attack_Spin",
		"1H_Ranged_Shoot", "Spellcast_Shoot", "Spellcast_Raise"]


func _initialize() -> void:
	for path in MODELS:
		var inst := (load(path) as PackedScene).instantiate() as Node3D
		root.add_child(inst)
		var props: Array[String] = []
		for n in inst.find_children("*", "Node3D", true, false):
			if n is MeshInstance3D and (n.get_parent() is BoneAttachment3D or n.name.begins_with("1H_") or n.name.begins_with("2H_") or n.name in ["Mug", "Barbarian_Hat", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "Badge_Shield", "Knife", "Knife_Offhand", "Throwable"]):
				props.append(n.name)
		var skel := inst.find_child("Skeleton3D", true, false) as Skeleton3D
		var anim := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var have: Array[String] = []
		var missing: Array[String] = []
		for a in NEEDED:
			if anim != null and anim.has_animation(a):
				have.append(a)
			else:
				missing.append(a)
		print("== ", path.get_file(), "  animations: ", anim.get_animation_list().size() if anim else 0,
				"  handslots: ", skel != null and skel.find_bone("handslot.r") >= 0)
		print("   props: ", ", ".join(props))
		print("   missing of the mob set: ", ", ".join(missing))
		inst.queue_free()
	quit()
