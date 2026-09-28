extends Node
class_name KeepDistanceComponent

## Picks where a ranged enemy walks: straight to its target until it has line of sight, then to preferred_distance from it.

var preferred_distance := 100.0
var tolerance := 20.0

func initialize(p_preferred_distance: float, p_tolerance: float) -> void:
	preferred_distance = p_preferred_distance
	tolerance = p_tolerance

func get_move_goal(from: Vector2, target_position: Vector2, has_line_of_sight: bool) -> Vector2:
	var to_target := target_position - from
	if not has_line_of_sight or to_target.length() > preferred_distance + tolerance:
		return target_position
	return target_position - to_target.normalized() * preferred_distance
