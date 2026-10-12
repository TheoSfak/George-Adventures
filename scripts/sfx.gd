class_name Sfx
## One-line sound effects from anywhere:   Sfx.play("sword_swing")   or at a place in the
## world:   Sfx.play("skel_hurt", global_position)
## Names are the files in assets/audio/sfx (see scripts/sfx_ids.gd; sounds with several
## variants pick one at random). Does nothing when no SoundManager exists (tests, tools).


static func play(id: String, at: Vector3 = Vector3.INF, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var manager := tree.get_first_node_in_group("sound_manager")
	if manager != null:
		manager.play(id, at, volume_db, pitch)


## Interface sounds: no pitch variation, always centred.
static func ui(id: String, volume_db: float = 0.0) -> void:
	play(id, Vector3.INF, volume_db, -1.0)
