extends NavigationAgent2D
class_name NavigationComponent

var entity: CharacterBody2D
var last_safe_velocity := Vector2.ZERO

func _ready() -> void:
	entity = get_parent() as CharacterBody2D
	velocity_computed.connect(_on_velocity_computed)

func get_safe_velocity(target_pos: Vector2, move_speed: float) -> Vector2:
	target_position = target_pos
	
	if is_navigation_finished():
		velocity = Vector2.ZERO
		return Vector2.ZERO
	
	var next_pos := get_next_path_position()
	var desired_velocity := (next_pos - entity.global_position).normalized() * move_speed
	velocity = desired_velocity
	
	# Return the last computed safe velocity (from previous frame)
	# This handles the one-frame delay in velocity_computed signal
	return last_safe_velocity

func _on_velocity_computed(safe_vel: Vector2) -> void:
	last_safe_velocity = safe_vel
