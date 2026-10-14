class_name UpperBodyLayer
extends RefCounted
## Lets George swing his sword while he runs: a second AnimationPlayer plays copies of the swing animations
## that have no tracks for the hips, legs and feet, so the legs keep running (the base AnimationPlayer keeps
## playing the locomotion) while the spine, arms and head swing. See combat_timing.gd for the swings.

# bones of the KayKit Rig that belong to the lower body (the track path is "Rig/Skeleton3D:<bone>")
const LOWER_PREFIXES: Array[String] = ["root", "hips", "upperleg", "lowerleg", "foot", "toes", "kneeIK", "control-", "heelIK", "IK-foot"]

var player: AnimationPlayer


## True for a track that moves the hips, legs or feet.
static func is_lower_body(track_path: String) -> bool:
	if not ":" in track_path:
		return false
	var bone := track_path.get_slice(":", 1)
	for prefix in LOWER_PREFIXES:
		if bone == prefix or bone.begins_with(prefix):
			return true
	return false


## A copy of `anim` without the lower-body tracks.
static func filtered(anim: Animation) -> Animation:
	var copy := anim.duplicate() as Animation
	for i in range(copy.get_track_count() - 1, -1, -1):
		if is_lower_body(str(copy.track_get_path(i))):
			copy.remove_track(i)
	copy.loop_mode = Animation.LOOP_NONE
	return copy


## Creates the layer next to `base` with a filtered copy of every animation in `names`.
func setup(base: AnimationPlayer, names: Array) -> void:
	player = AnimationPlayer.new()
	player.name = "UpperBody"
	base.get_parent().add_child(player)      # a sibling: it is processed after the base player and so wins on its tracks
	player.root_node = base.root_node
	var lib := AnimationLibrary.new()
	for n in names:
		if base.has_animation(n):
			lib.add_animation(n, filtered(base.get_animation(n)))
	player.add_animation_library("", lib)


func has_animation(anim_name: String) -> bool:
	return player != null and player.has_animation(anim_name)


func play(anim_name: String, blend: float, speed: float) -> void:
	if has_animation(anim_name):
		player.play(anim_name, blend, speed)


func stop() -> void:
	if player != null and player.is_playing():
		player.stop()
