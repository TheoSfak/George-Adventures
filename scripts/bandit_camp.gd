class_name BanditCamp
## The bandits' hideout in the north-west forest (see docs/superpowers/specs/2026-10-14-bandits-design.md).
## The camp is built by Village._build_bandit_camp; the creatures are listed in Enemies.SPAWNS
## (kinds `bandit_*`), the quest is "bandits" in quest_data.gd.

const CENTER := Vector2(-140.0, -90.0)     # open ground (tools/bandit_site_probe.gd), 50 m from the windmill zone
const RADIUS := 36.0                       # nothing is scattered inside, nor do skeletons spawn there
const CHEST := Vector2(-135.0, -95.0)      # the golden chest (Village.CHESTS)
const SIGN := Vector2(-118.0, -74.0)       # a signpost on the way from the mill
