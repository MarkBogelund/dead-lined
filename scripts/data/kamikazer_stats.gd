extends Resource
class_name KamikazerStats

@export_group("Health")
## Maximum hit points
@export var max_health: int = 10

@export_group("Movement")
## Navigation speed while searching for line of sight
@export var speed: float = 34.0
## Straight-line speed while charging
@export var charge_speed: float = 110.0

@export_group("Charge Behavior")
## How quickly speed ramps up while accelerating (pixels/second^2)
@export var charge_acceleration: float = 150.0
## How quickly speed ramps down while braking (pixels/second^2)
@export var charge_deceleration: float = 200.0
## Speed below which the charge is considered fully stopped
@export var charge_stop_threshold: float = 5.0
## Seconds to wait after hitting a non-player obstacle before charging again
@export var collision_cooldown_duration: float = 1.0

@export_group("Targeting")
## Target selection rules (player only)
@export var targeting: TargetingProfile = preload("res://resources/targeting/kamikazer_targeting.tres")

@export_group("Combat")
## Damage dealt to the player on explosion trigger
@export var explosion_damage: int = 30
## Knockback applied to the player on explosion trigger
@export var explosion_knockback: float = 260.0

@export_group("Effects")
## Screen shake intensity on explosion trigger
@export var explosion_screen_shake_intensity: float = 0.35

@export_group("Drops")
## Number of scrap units dropped on death
@export var scrap_drop_amount: int = 5
