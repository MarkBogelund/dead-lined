extends Resource
class_name SeekerStats

@export_group("Health")
@export var max_health: int = 100

@export_group("Targeting")
@export var max_range: float = 130.0

@export_group("Aiming")
@export var aim_speed: float = 6.0
@export var accuracy_angle: float = 0.1

@export_group("Shooting")
@export var shoot_start_delay: float = 1.0
@export var shoot_cooldown: float = 1.0
@export var projectile_damage: int = 10
@export var projectile_knockback: int = 200
@export var projectile_speed: float = 200.0
