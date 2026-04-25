extends Resource
class_name SeekerStats

@export var display_name: String = "Seeker"

@export_group("Health")
## Maximum hit points
@export var max_health: int = 100

@export_group("Targeting")
## Maximum range in pixels at which the seeker will acquire a target
@export var max_range: float = 130.0

@export_group("Aiming")
## Rotation speed toward the target in radians/second
@export var aim_speed: float = 6.0
## Angle tolerance in radians within which the seeker will fire
@export var accuracy_angle: float = 0.1

@export_group("Upgrades")
## Capacity cost per upgrade purchase
@export var upgrade_cost: float = 15.0
## Max HP added per health upgrade
@export var health_upgrade_amount: int = 10
## Projectile damage added per damage upgrade
@export var damage_upgrade_amount: int = 5

@export_group("Repair")
## Capacity drained from the player per second while repairing
@export var capacity_drain_rate: float = 10.0
## Health restored to this turret per second while repairing
@export var health_restore_rate: float = 15.0

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
