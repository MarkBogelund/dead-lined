extends RangedEnemyStats
class_name StalkerStats

## Orbit radius is preferred_distance; it enters the orbit within preferred_distance_tolerance of it.
@export_group("Orbit")
## How far ahead on the circle (degrees) the next navigation goal is placed. Larger = smoother, wider cut.
@export_range(1.0, 90.0, 1.0) var orbit_lead_angle: float = 25.0
## Extra distance beyond preferred_distance_tolerance before the stalker leaves the orbit and re-approaches.
@export var orbit_exit_margin: float = 15.0
## Seconds between stuck checks while orbiting.
@export var orbit_stuck_time: float = 0.6
## Moving less than this many pixels within orbit_stuck_time counts as blocked; it re-approaches with a new direction.
@export var orbit_stuck_distance: float = 4.0
