extends Resource
class_name TurretUpgrade

## One upgrade level. A turret is maxed once every entry in TurretStats.upgrades is applied.

@export var cost: float = 15.0
@export var max_health_bonus: int = 0
@export var damage_bonus: int = 0
## Added to the attack range in pixels; negative shrinks it.
@export var range_bonus: float = 0.0
## Added to the seconds between attacks; negative attacks faster.
@export var cooldown_bonus: float = 0.0
