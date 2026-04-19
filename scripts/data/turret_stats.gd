extends Resource
class_name TurretStats

@export_group("Health")
@export var max_health: int = 100

@export_group("Targeting")
@export var max_range: float = 130.0

@export_group("Firing")
@export var fire_rate: float = 1.0
@export var projectile_damage: int = 10
@export var projectile_knockback: int = 200
@export var projectile_speed: float = 200.0
