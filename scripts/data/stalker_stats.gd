extends Resource
class_name StalkerStats

@export_group("Health")
## Maximum hit points
@export var max_health: int = 30

@export_group("Movement")
## Movement speed in pixels/second
@export var speed: float = 25.0
## Preferred distance from the player in pixels
@export var ideal_distance: float = 100.0
## How far from ideal_distance the stalker will tolerate before repositioning
@export var distance_tolerance: float = 20.0

@export_group("Aiming")
## Rotation speed toward the target in radians/second
@export var aim_speed: float = 3.0
## Angle tolerance in radians within which the stalker will fire
@export var accuracy_angle: float = 0.25
## Target selection rules (player high priority, turrets low)
@export var targeting: TargetingProfile = preload("res://resources/targeting/enemy_targeting.tres")

@export_group("Shooting")
## Seconds after acquiring line-of-sight before the first shot is fired
@export var shoot_start_delay: float = 1.0
## Maximum distance in pixels at which the stalker will shoot
@export var max_shoot_distance: float = 120.0
## Seconds between shots
@export var shoot_cooldown: float = 0.5
## Damage dealt per projectile
@export var projectile_damage: int = 10
## Knockback force applied to targets hit by projectiles
@export var projectile_knockback: int = 200
## Projectile travel speed in pixels/second
@export var projectile_speed: float = 300.0

@export_group("Drops")
## Number of scrap units dropped on death
@export var scrap_drop_amount: int = 3
