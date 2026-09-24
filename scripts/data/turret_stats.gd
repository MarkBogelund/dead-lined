extends Resource
class_name TurretStats

@export_group("Health")
@export var max_health: int = 100

@export_group("Placement")
@export var exclusion_radius: float = 80.0

@export_group("Upgrades")
@export var health_upgrades: Array[TurretUpgrade] = []
@export var damage_upgrades: Array[TurretUpgrade] = []

@export_group("Repair")
@export var capacity_drain_rate: float = 10.0
@export var health_restore_rate: float = 15.0
@export var repair_amount_per_wrench_hit: int = 5