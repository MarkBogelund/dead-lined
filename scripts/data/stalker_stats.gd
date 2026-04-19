extends Resource
class_name StalkerStats

@export_group("Health")
@export var max_health: int = 30

@export_group("Movement")
@export var speed: float = 25.0
@export var ideal_distance: float = 100.0
@export var distance_tolerance: float = 20.0

@export_group("Aiming")
@export var aim_speed: float = 3.0
@export var accuracy_angle: float = 0.25

@export_group("Shooting")
@export var shoot_start_delay: float = 1.0
@export var max_shoot_distance: float = 120.0
@export var shoot_cooldown: float = 0.5
@export var projectile_damage: int = 10
@export var projectile_knockback: int = 200
@export var projectile_speed: float = 300.0

@export_group("Drops")
@export var scrap_drop_amount: int = 3
