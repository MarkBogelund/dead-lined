extends Resource
class_name ChaserStats

@export_group("Health")
@export var max_health: int = 30

@export_group("Movement")
@export var speed: float = 30.0

@export_group("Combat")
@export var hitbox_damage: int = 10
@export var hitbox_knockback: float = 200.0
@export var self_knockback: float = 250.0

@export_group("Drops")
@export var scrap_drop_amount: int = 5
