extends RangedEnemyStats
class_name ShotgunnerStats

@export_group("Shotgunner")
## Seconds the windup animation is scaled to last before it fires. Taking damage cancels the shot.
@export var windup_duration: float = 2.0
## Projectiles fired per shot.
@export_range(1, 32, 1) var projectile_count: int = 5
## Total fan angle in degrees between the outermost projectiles.
@export_range(0.0, 360.0, 1.0) var spread_angle: float = 45.0
## Knockback applied to the Shotgunner opposite its firing direction.
@export_range(0.0, 1000.0, 1.0) var shot_recoil_force := 100.0
## Seconds after firing or an interrupted windup before navigation movement may resume.
@export_range(0.0, 5.0, 0.05) var confusion_movement_lock_duration := 0.25
## Minimum distance the Shotgunner itself travels before it may attack again.
@export_range(0.0, 500.0, 1.0) var relocation_min_distance := 20.0
