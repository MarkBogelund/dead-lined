extends Resource
class_name TurretUpgrade

## A single upgrade step. Add to health_upgrades or damage_upgrades in SeekerStats.

## How much capacity this upgrade costs
@export var cost: float = 15.0
## How much to add (HP for health upgrades, damage for damage upgrades)
@export var value: int = 10
