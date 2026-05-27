extends Resource
class_name ChaserStats

@export_group("Health")
## Maximum hit points
@export var max_health: int = 30

@export_group("Movement")
## Movement speed in pixels/second
@export var speed: float = 30.0
## Radius within which nearby chasers influence this chaser's approach angle
@export var spread_radius: float = 48.0
## How far to offset the navigation target away from the local crowd
@export var spread_strength: float = 24.0
## Distance to player at which spread is dropped and the chaser converges to melee
@export var converge_distance: float = 40.0

@export_group("Combat")
## Damage dealt on contact with the player
@export var hitbox_damage: int = 10
## Knockback force applied to the player on contact
@export var hitbox_knockback: float = 200.0
## Knockback force applied to the chaser itself on contact
@export var self_knockback: float = 250.0

@export_group("Drops")
## Number of scrap units dropped on death
@export var scrap_drop_amount: int = 5
