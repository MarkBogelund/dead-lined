extends Resource
class_name CrunchPowerupSettings

## Tuning for the Crunch Time powerup orb. Drop chance lives per enemy type in EnemyStats.

@export_group("Ground")
## Seconds an uncollected powerup stays on the ground.
@export var lifetime: float = 25.0

@export_group("Look")
## Scale of the powerup relative to a regular orb.
@export var visual_scale: float = 2.0
@export var light_color: Color = Color(1.0, 0.1, 0.08, 1.0)
@export var light_energy: float = 0.35

@export_group("Carry")
## Distance the carried powerup trails behind the player.
@export var follow_distance: float = 14.0
## How quickly it catches up; higher is snappier.
@export var follow_smoothing: float = 8.0
@export var bob_amplitude: float = 2.0
## Bobs per second.
@export var bob_speed: float = 1.5
