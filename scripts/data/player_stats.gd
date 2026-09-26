extends Resource
class_name PlayerStats

@export_group("Movement")
## Top movement speed in pixels/second
@export var speed: float = 160.0
## How quickly the player accelerates to top speed
@export var acceleration: float = 3000.0
## How quickly the player decelerates when no input is given
@export var friction: float = 2500.0

@export_group("Dash")
## Distance travelled by a tapped dash, in pixels
@export var dash_min_distance: float = 120.0
## Distance travelled by a fully charged dash, in pixels
@export var dash_max_distance: float = 300.0
## Starting speed of a dash in pixels/second; it eases to 0, so longer dashes last longer
@export var dash_speed: float = 1750.0
## Real-time seconds the dash can be charged before it fires automatically
@export var dash_max_charge_time: float = 0.5
## Engine time scale while charging a dash
@export_range(0.05, 1.0, 0.05) var dash_charge_time_scale: float = 0.5
## Seconds before the player can dash again
@export var dash_cooldown: float = 0.2

@export_group("Melee")
## Damage dealt per slash
@export var slash_damage: int = 20
## Knockback force applied to hit targets
@export var slash_knockback: float = 200.0
## Knockback force applied to the player when the slash hits a wall or obstacle
@export var slash_self_knockback: float = 150.0
## Radius of the slash arc in pixels
@export var slash_radius: float = 24.0
## Full sweep angle of the slash in radians
@export var slash_arc_angle: float = PI
## Duration of the slash animation in seconds
@export var slash_duration: float = 0.25
## Seconds before the player can slash again
@export var slash_cooldown: float = 0.3

@export_group("Shooting")
## Seconds between shots
@export var shoot_cooldown: float = 0.25
## Damage dealt per projectile
@export var projectile_damage: int = 20
## Knockback force applied to targets hit by projectiles
@export var projectile_knockback: int = 200
## Projectile travel speed in pixels/second
@export var projectile_speed: float = 300.0

@export_group("Capacity")
## Starting capacity value at spawn
@export var initial_capacity: float = 80.0
## Hard cap on capacity
@export var max_capacity: float = 100.0
## Capacity level at which crunch time becomes available
@export var crunch_threshold: float = 90.0
## How much the crunch threshold lowers each time a turret is placed
@export var threshold_step: float = 10.0
## Minimum value the crunch threshold can reach
@export var min_crunch_threshold: float = 10.0

@export_group("Crunch Time")
## Capacity spent on crunch time activation
@export var crunch_activation_cost: float = 50.0
## Duration of crunch time in seconds
@export var crunch_duration: float = 5.0
## Slash damage multiplier while crunch time is active
@export var damage_multiplier: float = 2.0
## Slash radius multiplier while crunch time is active
@export var radius_multiplier: float = 2.0
## Movement speed multiplier while crunch time is active
@export var speed_multiplier: float = 1.5
## Slash arc angle multiplier while crunch time is active
@export var arc_angle_multiplier: float = 1.5
## Melee weapon scale multiplier while crunch time is active
@export var weapon_size_multiplier: float = 2.0
## Cooldown multiplier while crunch time is active (< 1 = faster)
@export var cooldown_multiplier: float = 0.5

@export_group("Damage Reaction")
## Knockback force applied to the player when taking damage
@export var damage_knockback_force: float = 200.0
## Duration of freeze frame when taking damage
@export var damage_freeze_duration: float = 0.1
## Screen shake intensity when taking damage
@export var damage_screen_shake_intensity: float = 0.2

@export_group("Death Reaction")
## Knockback force applied to the player on death
@export var death_knockback_force: float = 400.0
## Duration of freeze frame on death
@export var death_freeze_duration: float = 0.15
## Screen shake intensity on death
@export var death_screen_shake_intensity: float = 0.35
