extends EnemyStats
class_name ChaserStats

@export_group("Chaser")
## How far to the side of its target each chaser aims while far away, so a group fans out and arrives from different angles.
@export var flank_distance: float = 48.0
## Beyond this distance from its target the full flank offset is used.
@export var flank_full_distance: float = 120.0
## Within this distance the flank offset is gone and the chaser heads straight for its target.
@export var flank_zero_distance: float = 40.0
## Knockback the chaser takes itself when its contact hit lands.
@export var bounce_back_force: float = 250.0
