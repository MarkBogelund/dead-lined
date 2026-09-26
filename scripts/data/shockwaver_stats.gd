extends TurretStats
class_name ShockwaverStats

@export_group("Shockwave")
## Trigger distance and blast radius.
@export var max_range: float = 120.0
@export var ring_thickness: float = 8.0
@export var cooldown: float = 2.5
@export var expansion_duration: float = 0.6
@export var damage: int = 20
@export var knockback_force: float = 180.0
