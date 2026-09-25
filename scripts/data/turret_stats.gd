extends Resource
class_name TurretStats

@export_group("Health")
@export var max_health: int = 100

@export_group("Placement")
@export var exclusion_radius: float = 80.0

@export_group("Upgrades")
@export var upgrades: Array[TurretUpgrade] = []
## When maxed the turret stops targeting the player; its attacks can still hit the player.
@export var stops_targeting_player_when_maxed := true

@export_group("Selling")
@export_range(0.0, 1.0, 0.05) var sell_refund_ratio := 0.75

@export_group("Repair")
@export var capacity_drain_rate: float = 10.0
@export var health_restore_rate: float = 15.0