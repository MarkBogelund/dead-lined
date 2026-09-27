extends Resource
class_name EnemyStats

## Fields shared by every enemy. Enemy-specific stats extend this.

@export_group("Health")
## Maximum hit points.
@export var max_health: int = 10

@export_group("Combat")
## Damage dealt per hit (contact, projectile, or explosion).
@export var damage: int = 10
## Knockback force applied to whatever this enemy hits.
@export var knockback: float = 200.0

@export_group("Movement")
## Movement speed in pixels/second.
@export var move_speed: float = 30.0

@export_group("Targeting")
## Rules for choosing between the player and turrets.
@export var targeting: TargetingProfile = preload("res://resources/enemies/enemy_targeting.tres")

@export_group("Drops")
## Capacity orbs dropped on death.
@export var orb_drop_amount: int = 3
## Chance (0-1) of also dropping a Crunch Time powerup on death.
@export_range(0.0, 1.0, 0.005) var crunch_powerup_drop_chance: float = 0.02
