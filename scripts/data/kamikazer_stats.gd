extends EnemyStats
class_name KamikazerStats

@export_group("Kamikazer")
## Straight-line speed while charging, in pixels/second.
@export var charge_speed: float = 110.0
## How quickly the charge speeds up (pixels/second^2).
@export var charge_acceleration: float = 150.0
## How quickly the charge slows down (pixels/second^2).
@export var charge_deceleration: float = 200.0
## Speed below which a charge counts as stopped.
@export var charge_stop_speed: float = 5.0
## Seconds the kamikazer stands still after charging into an obstacle.
@export var collision_stun_duration: float = 1.0
## Screen shake intensity of the explosion.
@export var explosion_screen_shake: float = 0.35
