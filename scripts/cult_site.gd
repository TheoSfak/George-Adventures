class_name CultSite
## The cult's ritual circle in the north-west forest, between the old crypt and the bandits (see
## docs/superpowers/specs/2026-10-14-more-mobs-design.md). The circle is built by Village._build_cult_site; the creatures are
## entries of Enemies.SPAWNS (`cultist` x5 and `cult_priest`), the quest is "cult" in quest_data.gd, the golden chest is in
## Village.CHESTS. The ground was checked with tools/mob_site_probe.gd (an 18 m free disc).

const CENTER := Vector2(-80.0, -140.0)
const RADIUS := 30.0                       # nothing is scattered inside, nor do skeletons spawn there
const ALTAR := Vector2(-80.0, -150.0)      # the shrine, north of the middle
const CHEST := Vector2(-71.0, -152.0)      # the golden chest (Village.CHESTS)
const SIGN := Vector2(-62.0, -124.0)       # a signpost on the way from the village

## The pumpkin patch beside the road to the crypt: ordinary pumpkins and five that are alive (Enemies.SPAWNS).
const PATCH := Vector2(70.0, -171.0)
const PATCH_RADIUS := 8.0
