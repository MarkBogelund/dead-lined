extends TurretStats
class_name ShockwaverStats

## attack_range is both the trigger distance and the blast radius.

@export_group("Shockwaver")
## Width of the expanding damage ring in pixels.
@export var ring_thickness: float = 8.0
## Seconds the ring takes to expand to attack_range.
@export var expansion_duration: float = 0.6
