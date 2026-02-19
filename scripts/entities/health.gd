extends Node
class_name HealthComponent

@export var max_health: int
var current_health: int
var is_dead = false

signal died
signal damaged(current_health: int)

func _ready():
	current_health = max_health
	if current_health <= 0:
		die()

func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	current_health -= amount
	
	if current_health <= 0:
		die()
		return
	
	emit_signal("damaged", current_health)

# Call this when health reaches zero
func die() -> void:
	current_health = 0
	is_dead = true
	emit_signal("died")
