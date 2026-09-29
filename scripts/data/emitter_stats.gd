extends EnemyStats
class_name EmitterStats

@export_group("Relocation")
## Random navmesh points sampled when choosing a new spot.
@export_range(1, 64, 1) var spot_candidates: int = 12
## A spot must be at least this far from every player/turret. Keep it above flee_radius.
@export var spot_min_target_distance: float = 180.0
## A player/turret this close makes the emitter stop and run to a new spot.
@export var flee_radius: float = 90.0
## Distance to the spot that counts as arrived.
@export var arrive_distance: float = 8.0

@export_group("Emission")
## Seconds between shots; each shot fires one projectile from each side.
@export var emit_interval: float = 0.15
## Clockwise rotation of the emission direction in degrees/second.
@export var rotation_speed: float = 90.0
## Projectile travel speed in pixels/second.
@export var projectile_speed: float = 45.0
## Seconds before a projectile despawns on its own. 0 or less = never.
@export var projectile_lifetime: float = 2.0
## Seconds without emitting after being hit while emitting. Keeps counting while it flees.
@export var hit_cooldown: float = 2.0
