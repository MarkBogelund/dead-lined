extends Resource
class_name TurretStats

## Fields shared by every turret; TurretUpgrade uses the same names. Turret-specific stats extend this.

@export_group("Health")
## Maximum hit points.
@export var max_health: int = 100

@export_group("Combat")
## Damage dealt per hit (projectile or shockwave).
@export var damage: int = 10
## Knockback force applied to enemies hit.
@export var knockback: float = 200.0
## Attack reach in pixels; also drives the range indicator and placement preview.
@export var attack_range: float = 100.0
## Seconds between attacks.
@export var attack_cooldown: float = 1.0

@export_group("Upgrades")
@export var upgrades: Array[TurretUpgrade] = []
## When maxed the turret stops targeting the player; its attacks can still hit the player.
@export var stops_targeting_player_when_maxed := true

@export_group("Selling")
@export_range(0.0, 1.0, 0.05) var sell_refund_ratio := 0.75

@export_group("Repair")
## Player capacity spent per second while repairing.
@export var repair_cost_per_second: float = 10.0
## Health restored per second while repairing.
@export var repair_health_per_second: float = 15.0
