extends Node
class_name MovementComponent

@export var speed := 170.0
@export var acceleration := 3000.0
@export var friction := 4500.0

var _base_speed := speed

func initialize(p_speed: float, p_acceleration: float, p_friction: float) -> void:
	speed = p_speed
	_base_speed = p_speed
	acceleration = p_acceleration
	friction = p_friction

func set_crunch_time_active(active: bool, speed_multiplier: float) -> void:
	speed = _base_speed * speed_multiplier if active else _base_speed

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
