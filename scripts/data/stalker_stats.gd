extends EnemyStats
class_name StalkerStats

@export_group("Stalker")
## Distance the stalker tries to keep from its target.
@export var preferred_distance: float = 100.0
## How far from preferred_distance the stalker may drift before repositioning.
@export var preferred_distance_tolerance: float = 20.0
## Aim rotation speed in radians/second.
@export var aim_speed: float = 3.0
## Angle in radians the aim may be off and still fire.
@export var aim_tolerance: float = 0.25
## Seconds after gaining line of sight before the first shot.
@export var first_shot_delay: float = 1.0
## Maximum distance at which the stalker fires.
@export var shoot_range: float = 120.0
## Seconds between shots.
@export var attack_cooldown: float = 0.5
## Projectile travel speed in pixels/second.
@export var projectile_speed: float = 300.0
