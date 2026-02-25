extends Node
class_name HealthComponent

@export var max_health: int
var current_health: int
var _is_dead = false

signal died
signal damaged(current_health: int)

func _ready():
	current_health = max_health
	if current_health <= 0:
		die()

func take_damage(amount: int) -> void:
	if _is_dead:
		return
	
	current_health -= amount
	
	if current_health <= 0:
		die()
		return
	
	emit_signal("damaged", current_health)

# Call this when health reaches zero
func die() -> void:
	current_health = 0
	_is_dead = true
	emit_signal("died")

## Public API for querying health
func get_current_health() -> int:
	return current_health

func is_dead() -> bool:
	return _is_dead

## Public API for modifying health
func restore_to_max() -> void:
	current_health = max_health
	_is_dead = false

func buff_max_health(multiplier: float) -> void:
	max_health = int(max_health * multiplier)
	restore_to_max()
