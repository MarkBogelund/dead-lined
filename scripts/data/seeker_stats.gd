extends TurretStats
class_name SeekerStats

@export_group("Targeting")
## Maximum range in pixels at which the seeker will acquire a target
@export var max_range: float = 130.0

@export_group("Aiming")
## Rotation speed toward the target in radians/second
@export var aim_speed: float = 6.0
## Angle tolerance in radians within which the seeker will fire
@export var accuracy_angle: float = 0.1
## Target selection rules (enemies high priority, player low)
@export var targeting: TargetingProfile = preload("res://resources/targeting/seeker_targeting.tres")

@export_group("Shooting")
## Seconds after acquiring a target before the first shot is fired
@export var shoot_start_delay: float = 1.0
## Seconds between shots
@export var shoot_cooldown: float = 1.0
## Damage dealt per projectile
@export var projectile_damage: int = 10
## Knockback force applied to targets hit by projectiles
@export var projectile_knockback: int = 200
## Projectile travel speed in pixels/second
@export var projectile_speed: float = 200.0
