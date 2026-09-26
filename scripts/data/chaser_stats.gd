extends EnemyStats
class_name ChaserStats

@export_group("Chaser")
## Inside this distance from its target the chaser attacks directly; outside it heads to its own point on this circle.
@export var attack_radius: float = 60.0
## Extra distance past attack_radius before an attacking chaser gives up and returns to its circle point.
@export var attack_exit_margin: float = 20.0
## Knockback the chaser takes itself when its contact hit lands.
@export var bounce_back_force: float = 250.0
