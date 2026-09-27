extends Resource
class_name CrunchPowerupSettings

## Tuning for the Crunch Time powerup orb. The base drop chance lives per enemy type in EnemyStats.

@export_group("Drop Chance")
## Added to the enemy's base chance for every turret standing on the map.
@export_range(0.0, 1.0, 0.005) var chance_per_turret: float = 0.02
## Cap on that turret bonus, so a full board can't guarantee a drop.
@export_range(0.0, 1.0, 0.01) var max_turret_bonus: float = 0.15

@export_group("Ground")
## Seconds an uncollected powerup stays on the ground.
@export var lifetime: float = 25.0
## Playtesting: keep dropping capacity orbs while Crunch Time is running. Powerups never drop during it.
@export var drop_orbs_during_crunch_time: bool = false

@export_group("Carry")
## Distance the carried powerup trails behind the player.
@export var follow_distance: float = 14.0
## How quickly it catches up; higher is snappier.
@export var follow_smoothing: float = 8.0
@export var bob_amplitude: float = 2.0
## Bobs per second.
@export var bob_speed: float = 1.5
