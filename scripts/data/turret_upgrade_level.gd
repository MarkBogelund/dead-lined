extends Resource
class_name TurretUpgrade

## One upgrade level. A turret is maxed once every entry in TurretStats.upgrades is applied.

@export var cost: float = 15.0
## Multipliers of the turret's base TurretStats value after this upgrade (1.5 = 150% of base, not of the previous level).
## -1 leaves the stat as it was at the previous level.
@export var max_health: float = -1.0
@export var damage: float = -1.0
## Multiplier of the base attack range.
@export var attack_range: float = -1.0
## Multiplier of the base seconds between attacks (below 1 = faster).
@export var attack_cooldown: float = -1.0
