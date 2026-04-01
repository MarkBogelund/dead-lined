extends Node
class_name CircleMovementComponent

@export var orbit_distance := 150.0
@export var orbit_tolerance := 20.0
@export var orbit_angle_step := 45.0

var entity: Node2D
var circle_direction: int = 1

func _ready() -> void:
	entity = get_parent() as Node2D
	if not entity:
		push_error("CircleMovementComponent must be a child of a Node2D")
		return
	
	circle_direction = 1 if randf() > 0.5 else -1

func get_orbit_target_position(player_position: Vector2) -> Vector2:
	if not entity:
		return player_position
	
	var to_target := player_position - entity.global_position
	var distance := to_target.length()
	
	if distance < 0.1:
		return player_position + Vector2.RIGHT * orbit_distance
	
	var direction_to_target := to_target.normalized()
	var angle_to_target := direction_to_target.angle()
	var orbit_angle := angle_to_target + deg_to_rad(orbit_angle_step * circle_direction)
	var orbit_offset := Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_distance
	
	return player_position + orbit_offset

func should_circle(distance: float) -> bool:
	return distance <= orbit_distance + orbit_tolerance and distance >= orbit_distance - orbit_tolerance


func randomize_direction() -> void:
	circle_direction = 1 if randf() > 0.5 else -1
