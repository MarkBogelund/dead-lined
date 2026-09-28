extends RangedEnemyStats
class_name ShotgunnerStats

@export_group("Shotgunner")
## Seconds the windup animation is scaled to last before it fires. Taking damage cancels the shot.
@export var windup_duration: float = 2.0
## Projectiles fired per shot.
@export_range(1, 32, 1) var projectile_count: int = 5
## Total fan angle in degrees between the outermost projectiles.
@export_range(0.0, 360.0, 1.0) var spread_angle: float = 45.0
