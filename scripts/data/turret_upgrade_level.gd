extends Resource
class_name TurretUpgrade

## One upgrade level. A turret is maxed once every entry in TurretStats.upgrades is applied.

@export var cost: float = 15.0
## Absolute values the turret has after this upgrade. -1 leaves the stat unchanged.
@export var max_health: int = -1
@export var damage: int = -1
## Attack range in pixels.
@export var attack_range: float = -1.0
## Seconds between attacks.
@export var attack_cooldown: float = -1.0
