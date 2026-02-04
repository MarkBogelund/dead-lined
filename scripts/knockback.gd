extends Node
class_name KnockbackComponent

@export var friction := 1200.0

var velocity: Vector2 = Vector2.ZERO

func is_active() -> bool:
	return velocity.length() > 1.0

func apply(from_position: Vector2, strength: float) -> void:
	var owner := get_parent() as Node2D
	if owner == null:
		return

	var dir = (owner.global_position - from_position).normalized()
	velocity = dir * strength

func process(delta: float) -> void:
	if is_active():
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
