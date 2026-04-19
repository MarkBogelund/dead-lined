extends Node
class_name MovementComponent

@export var speed := 170.0
@export var acceleration := 3000.0
@export var friction := 4500.0

func initialize(p_speed: float, p_acceleration: float, p_friction: float) -> void:
	speed = p_speed
	acceleration = p_acceleration
	friction = p_friction

func calculate_velocity(
	current_velocity: Vector2,
	input_dir: Vector2,
	delta: float
) -> Vector2:
	
	if input_dir != Vector2.ZERO:
		return current_velocity.move_toward(
			input_dir * speed,
			acceleration * delta
		)

	return current_velocity.move_toward(
		Vector2.ZERO,
		friction * delta
	)
