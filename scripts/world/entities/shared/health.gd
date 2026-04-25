extends Node
class_name HealthComponent

@export var max_health: int
var current_health: int
var _is_dead = false

func _ready():
	current_health = max_health
	if current_health <= 0:
		current_health = 0
		_is_dead = true

func take_damage(amount: int) -> bool:
	"""Returns true if damage was fatal, false otherwise"""
	if _is_dead:
		return false
	
	current_health -= amount
	
	if current_health <= 0:
		current_health = 0
		_is_dead = true
		return true
	
	return false

## Public API for querying health
func get_current_health() -> int:
	return current_health

## Apply stats from a TurretStats resource (call from parent _ready after children have initialized)
func initialize(new_max_health: int) -> void:
	max_health = new_max_health
	current_health = new_max_health
	_is_dead = false

func is_dead() -> bool:
	return _is_dead

## Public API for modifying health
func restore_to_max() -> void:
	current_health = max_health
	_is_dead = false

func buff_max_health(multiplier: float) -> void:
	max_health = int(max_health * multiplier)
	restore_to_max()

func increase_max_health(amount: int) -> void:
	max_health += amount
	current_health = mini(current_health + amount, max_health)

func heal(amount: int) -> void:
	if _is_dead:
		return
	current_health = mini(current_health + amount, max_health)
