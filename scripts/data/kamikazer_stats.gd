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
## Maximum seconds to charge in a straight line before giving up and re-routing (safety net)
@export var max_charge_duration: float = 1.5
## Seconds between progress checks while charging; if stuck, it re-routes early
@export var stuck_check_interval: float = 0.25

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
