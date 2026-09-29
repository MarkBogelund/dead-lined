extends Node
class_name SafeSpotComponent

## Picks a random reachable navmesh point far from every threat.

var candidates := 12
var min_threat_distance := 180.0

func initialize(p_candidates: int, p_min_threat_distance: float) -> void:
	candidates = p_candidates
	min_threat_distance = p_min_threat_distance

## Returns the first sampled point at least min_threat_distance from all threats, else the safest sample.
func pick_spot(navigation_map: RID, navigation_layers: int, threats: Array[Node2D]) -> Vector2:
	var best := Vector2.ZERO
	var best_distance := -1.0
	for i in candidates:
		var point := NavigationServer2D.map_get_random_point(navigation_map, navigation_layers, true)
		var distance := get_nearest_threat_distance(point, threats)
		if distance >= min_threat_distance:
			return point
		if distance > best_distance:
			best_distance = distance
			best = point
	return best

func get_nearest_threat_distance(point: Vector2, threats: Array[Node2D]) -> float:
	var nearest := INF
	for threat: Node2D in threats:
		nearest = minf(nearest, point.distance_to(threat.global_position))
	return nearest
