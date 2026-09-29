extends TurretStats
class_name SeekerStats

@export_group("Seeker")
## Rules for choosing between enemies and the player.
@export var targeting: TargetingProfile = preload("res://resources/turrets/turret_targeting.tres")
## Aim rotation speed in radians/second.
@export var aim_speed: float = 6.0
## Angle in radians the aim may be off and still fire.
@export var aim_tolerance: float = 0.1
## Seconds after combat starts before the first shot.
@export var first_shot_delay: float = 1.0
## Projectile travel speed in pixels/second.
@export var projectile_speed: float = 200.0
## Seconds before a projectile despawns on its own. 0 or less = never.
@export var projectile_lifetime: float = 2.0
