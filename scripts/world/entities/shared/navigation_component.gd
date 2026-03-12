extends NavigationAgent2D
class_name NavigationComponent

var entity: CharacterBody2D

func _ready() -> void:
	path_desired_distance = 8.0
	target_desired_distance = 4.0
	entity = get_parent() as CharacterBody2D

func get_velocity_to(target_pos: Vector2, move_speed: float) -> Vector2:
	target_position = target_pos
	
	if is_navigation_finished():
		return Vector2.ZERO
	
	var next_pos := get_next_path_position()
	return (next_pos - entity.global_position).normalized() * move_speed
