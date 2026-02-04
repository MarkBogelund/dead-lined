extends Node
class_name HealthComponent

# Health
@export var max_health: int
var current_health: int
var is_dead = false

# Signals
signal died
signal damaged(amount)

func _ready():
	current_health = max_health

	if current_health <= 0:
		die()

# Call this to deal damage
func take_damage(amount: int) -> void:
	current_health -= amount
	
	if current_health <= 0:
		die()
		return
	
	emit_signal("damaged", amount)
	print(get_parent().name + " took damage")

# Call this when health reaches zero
func die() -> void:
	current_health = 0
	is_dead = true
	emit_signal("died")
	print(get_parent().name + " died")
