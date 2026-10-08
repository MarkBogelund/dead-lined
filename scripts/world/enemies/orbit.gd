extends Node
class_name OrbitComponent

## Picks where a ranged enemy walks: to a circle of `radius` around its target, then around it in a random direction.
## Leaves the orbit (and later re-enters with a new random direction) on lost sight, leaving the band, or getting stuck.

enum State { APPROACH, ORBIT }

var radius := 100.0
var entry_tolerance := 20.0
var exit_margin := 15.0
var lead_angle := deg_to_rad(25.0)
var stuck_time := 0.6
var stuck_distance := 4.0

var _state := State.APPROACH
var _direction := 1.0
var _stuck_timer := 0.0
var _stuck_check_position := Vector2.ZERO

func initialize(p_radius: float, p_entry_tolerance: float, p_exit_margin: float, p_lead_angle_degrees: float, p_stuck_time: float, p_stuck_distance: float) -> void:
	radius = p_radius
	entry_tolerance = p_entry_tolerance
	exit_margin = p_exit_margin
	lead_angle = deg_to_rad(p_lead_angle_degrees)
	stuck_time = p_stuck_time
	stuck_distance = p_stuck_distance

func reset() -> void:
	_state = State.APPROACH

func is_orbiting() -> bool:
	return _state == State.ORBIT

func get_move_goal(from: Vector2, target_position: Vector2, has_line_of_sight: bool, delta: float, navigation_map: RID) -> Vector2:
	var offset := from - target_position
	var ring_error := absf(offset.length() - radius)

	if _state == State.ORBIT and (not has_line_of_sight or ring_error > entry_tolerance + exit_margin or _is_stuck(from, delta)):
		_state = State.APPROACH
	if _state == State.APPROACH and has_line_of_sight and ring_error <= entry_tolerance:
		_enter_orbit(from)

	if _state == State.APPROACH:
		if not has_line_of_sight or offset.is_zero_approx():
			return target_position
		return target_position + offset.normalized() * radius

	var goal := target_position + Vector2.from_angle(offset.angle() + _direction * lead_angle) * radius
	# The navigation map is empty for its first sync frames; closest-point queries would return the origin.
	if NavigationServer2D.map_get_iteration_id(navigation_map) == 0:
		return goal
	return NavigationServer2D.map_get_closest_point(navigation_map, goal)

func _enter_orbit(from: Vector2) -> void:
	_state = State.ORBIT
	_direction = 1.0 if randf() < 0.5 else -1.0
	_stuck_timer = 0.0
	_stuck_check_position = from

func _is_stuck(from: Vector2, delta: float) -> bool:
	_stuck_timer += delta
	if _stuck_timer < stuck_time:
		return false
	var moved := from.distance_to(_stuck_check_position)
	_stuck_timer = 0.0
	_stuck_check_position = from
	return moved < stuck_distance
