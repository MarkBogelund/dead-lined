extends Node
class_name SafeSpotComponent

## Shared random navmesh location selection for relocation and safe spawning.

## Random locations sampled per attempt.
@export_range(1, 256, 1) var candidates := 12
## Preferred distance from every live threat; otherwise choose the farthest available sample.
@export_range(0.0, 1000.0, 1.0) var min_threat_distance := 180.0
## Clear collision radius at the destination. Zero disables clearance checks.
@export_range(0.0, 128.0, 1.0) var clearance_radius := 0.0
@export_flags_2d_physics var clearance_collision_mask := 171
## Never relax wall clearance, even for fallback positions. Leave off to retain Emitter's policy.
@export var require_wall_clearance := false

var _clearance_shape := CircleShape2D.new()
var _clearance_query := PhysicsShapeQueryParameters2D.new()

func initialize(p_candidates: int, p_min_threat_distance: float) -> void:
	candidates = maxi(1, p_candidates)
	min_threat_distance = maxf(0.0, p_min_threat_distance)

## Fallback can relax actor clearance/reachability, but required wall clearance is never relaxed.
func pick_spot(navigation_map: RID, navigation_layers: int, threats: Array[Node2D], from_position: Vector2) -> Vector2:
	var origin := from_position if from_position.is_finite() else Vector2.ZERO
	var fallback := origin if not require_wall_clearance or is_wall_clear(origin) else Vector2.INF
	if not navigation_map.is_valid() or NavigationServer2D.map_get_iteration_id(navigation_map) == 0:
		return fallback
	var best := origin
	var fallback_distance_squared := -1.0
	var best_distance_squared := -1.0
	var minimum_distance_squared := min_threat_distance * min_threat_distance
	var threat_positions: Array[Vector2] = []
	for threat: Node2D in threats:
		if _is_live_threat(threat):
			threat_positions.append(threat.global_position)
	for i in candidates:
		var point := NavigationServer2D.map_get_random_point(navigation_map, navigation_layers, true)
		if not point.is_finite():
			continue
		var distance_squared := INF
		for threat_position: Vector2 in threat_positions:
			distance_squared = minf(distance_squared, point.distance_squared_to(threat_position))
		if distance_squared <= best_distance_squared and distance_squared <= fallback_distance_squared:
			continue
		if require_wall_clearance and not is_wall_clear(point):
			continue
		if distance_squared > fallback_distance_squared:
			fallback_distance_squared = distance_squared
			fallback = point
		if distance_squared <= best_distance_squared:
			continue
		if not is_point_clear(point):
			continue
		var path := NavigationServer2D.map_get_path(navigation_map, origin, point, true, navigation_layers)
		if path.is_empty() or path[path.size() - 1].distance_squared_to(point) > 1.0:
			continue
		if distance_squared >= minimum_distance_squared:
			return point
		best_distance_squared = distance_squared
		best = point
	return best if best_distance_squared >= 0.0 else fallback

func get_threats(groups: Array[StringName]) -> Array[Node2D]:
	var threats: Array[Node2D] = []
	for group: StringName in groups:
		if group.is_empty():
			continue
		for node: Node in get_tree().get_nodes_in_group(group):
			var threat := node as Node2D
			if _is_live_threat(threat) and not threats.has(threat):
				threats.append(threat)
	return threats

func is_point_clear(point: Vector2) -> bool:
	if not point.is_finite():
		return false
	if clearance_radius <= 0.0:
		return true
	return _query_clearance(point, clearance_collision_mask, clearance_radius)

func is_wall_clear(point: Vector2) -> bool:
	return point.is_finite() and _query_clearance(point, 1, maxf(1.0, clearance_radius))

func _query_clearance(point: Vector2, mask: int, radius: float) -> bool:
	_clearance_shape.radius = radius
	_clearance_query.shape = _clearance_shape
	_clearance_query.transform = Transform2D(0.0, point)
	_clearance_query.collision_mask = mask
	_clearance_query.collide_with_areas = false
	return get_viewport().find_world_2d().direct_space_state.intersect_shape(_clearance_query, 1).is_empty()

func _is_live_threat(threat: Node2D) -> bool:
	return is_instance_valid(threat) and threat.is_inside_tree() and threat.global_position.is_finite() \
		and (not threat.has_method("is_dead") or not threat.is_dead())

func get_nearest_threat_distance(point: Vector2, threats: Array[Node2D]) -> float:
	var nearest := INF
	for threat: Node2D in threats:
		if _is_live_threat(threat):
			nearest = minf(nearest, point.distance_to(threat.global_position))
	return nearest
