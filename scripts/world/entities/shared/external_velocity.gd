extends Node
class_name ExternalVelocityComponent

var _velocities: Dictionary[int, Vector2] = {}

func set_velocity(source_id: int, value: Vector2) -> void:
	if value.is_zero_approx():
		_velocities.erase(source_id)
	else:
		_velocities[source_id] = value

func clear_velocity(source_id: int) -> void:
	_velocities.erase(source_id)

func clear_all() -> void:
	_velocities.clear()

func get_total_velocity() -> Vector2:
	var total := Vector2.ZERO
	for value: Vector2 in _velocities.values():
		total += value
	return total