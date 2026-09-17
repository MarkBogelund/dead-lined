extends Resource
class_name ChaserStats

@export_group("Health")
## Maximum hit points
@export var max_health: int = 30

@export_group("Movement")
## Movement speed in pixels/second
@export var speed: float = 30.0
## Distance from the player: inside it, chasers attack directly; outside it, they head to a point on this circle
@export var attack_radius: float = 60.0
## Extra distance beyond attack_radius required before an attacking chaser gives up and returns to its circle point (prevents boundary flicker)
@export var attack_exit_margin: float = 20.0

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
