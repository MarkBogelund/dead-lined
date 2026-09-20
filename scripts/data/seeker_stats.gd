extends Resource
class_name SeekerStats

@export_group("Health")
## Maximum hit points
@export var max_health: int = 100

@export_group("Targeting")
## Maximum range in pixels at which the seeker will acquire a target
@export var max_range: float = 130.0

@export_group("Placement")
## Radius around this turret where no other turret can be placed
@export var exclusion_radius: float = 80.0

@export_group("Aiming")
## Rotation speed toward the target in radians/second
@export var aim_speed: float = 6.0
## Angle tolerance in radians within which the seeker will fire
@export var accuracy_angle: float = 0.1
## Priority assigned to the enemy target group
@export var enemy_target_priority: int = 1
## Priority assigned to the player target group
@export var player_target_priority: int = 0
## Distance advantage required before switching to a lower-priority target
@export var priority_distance_threshold: float = 20.0
## Distance advantage required before switching between equal-priority targets
@export var same_priority_switch_distance: float = 24.0

@export_group("Upgrades")
## Each entry is one purchasable health upgrade, in order.
@export var health_upgrades: Array[TurretUpgrade] = []
## Each entry is one purchasable damage upgrade, in order.
@export var damage_upgrades: Array[TurretUpgrade] = []

@export_group("Repair")
## Capacity drained from the player per second while repairing
@export var capacity_drain_rate: float = 10.0
## Health restored to this turret per second while repairing
@export var health_restore_rate: float = 15.0
## Health restored per wrench hit
@export var repair_amount_per_wrench_hit: int = 5

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
