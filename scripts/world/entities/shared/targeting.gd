extends Node
class_name TargetingComponent

## Reusable targeting component for entities (enemies, turrets, etc.)
## Configure target priorities in the inspector
## Higher priority values = higher importance

## Array of target configurations - configure in inspector
@export var target_configs: Array[TargetConfig] = []

## Distance threshold for priority switching
## If a lower priority target is closer by more than this amount, switch to it
@export var priority_distance_threshold := 20.0

## Maximum distance to consider targets in this group (-1 = unlimited)
@export var max_range: float = -1.0
## A same-priority challenger must be this many pixels closer before replacing the current target.
@export var same_priority_switch_distance: float = 0.0

var _sorted_configs: Array[TargetConfig] = []
var _current_target: Node2D
var _disabled_groups: Dictionary[String, bool] = {}

func _ready() -> void:
	_create_runtime_configs()

func initialize(s_max_range: float) -> void:
	max_range = s_max_range

func set_group_enabled(group_name: String, is_enabled: bool) -> void:
	if is_enabled:
		_disabled_groups.erase(group_name)
	else:
		_disabled_groups[group_name] = true

func configure_priorities(priorities: Dictionary, distance_threshold: float, same_priority_distance: float = 0.0) -> void:
	priority_distance_threshold = distance_threshold
	same_priority_switch_distance = maxf(0.0, same_priority_distance)
	_create_runtime_configs()
	for config: TargetConfig in _sorted_configs:
		config.priority = int(priorities.get(config.group_name, config.priority))
	_sort_configs()

func _create_runtime_configs() -> void:
	_sorted_configs.clear()
	for config: TargetConfig in target_configs:
		_sorted_configs.append(config.duplicate() as TargetConfig)
	_sort_configs()

func _sort_configs() -> void:
	_sorted_configs.sort_custom(func(a: TargetConfig, b: TargetConfig) -> bool: return a.priority > b.priority)

## Get the best target based on configured priorities and proximity
## filter: optional callable(Node2D) -> bool; return false to exclude a candidate
## Returns null if no valid targets found
func get_best_target(from_position: Vector2, filter: Callable = Callable()) -> Node2D:
	if target_configs.is_empty():
		return null
	
	var best_target: Node2D = null
	var best_distance_sq := INF
	var best_priority := -1
	
	# Scan through all priority groups
	for config: TargetConfig in _sorted_configs:
		if config.group_name.is_empty() or _disabled_groups.has(config.group_name):
			continue
		
		var nodes: Array[Node] = get_tree().get_nodes_in_group(config.group_name)
		
		for node: Node in nodes:
			# Skip invalid nodes
			if not is_instance_valid(node) or not node is Node2D:
				continue
			
			# Skip dead entities if they have is_dead() method
			if node.has_method("is_dead") and node.is_dead():
				continue
			
			var distance_sq := from_position.distance_squared_to(node.global_position)
			
			# Skip if outside max range
			if max_range >= 0.0 and distance_sq > max_range * max_range:
				continue
			
			# Apply optional caller-supplied filter (e.g. line of sight)
			if filter.is_valid() and not filter.call(node):
				continue
			
			# First valid target found
			if best_target == null:
				best_target = node
				best_distance_sq = distance_sq
				best_priority = config.priority
				continue
			
			# Same priority - take closest
			if config.priority == best_priority:
				if distance_sq < best_distance_sq:
					best_target = node
					best_distance_sq = distance_sq
			# Higher priority - take it as new best
			elif config.priority > best_priority:
				best_target = node
				best_distance_sq = distance_sq
				best_priority = config.priority
			# Lower priority - only take if significantly closer
			elif config.priority < best_priority:
				var best_distance := sqrt(best_distance_sq)
				var this_distance := sqrt(distance_sq)
				
				# If this lower priority target is closer by more than threshold, switch to it
				if (best_distance - this_distance) > priority_distance_threshold:
					best_target = node
					best_distance_sq = distance_sq
					best_priority = config.priority
	
	if best_target == null:
		_current_target = null
		return null

	if _is_valid_target(_current_target, from_position, filter) and best_target != _current_target:
		var current_priority := _get_target_priority(_current_target)
		var best_candidate_priority := _get_target_priority(best_target)
		if current_priority == best_candidate_priority:
			var current_distance := from_position.distance_to(_current_target.global_position)
			var challenger_distance := from_position.distance_to(best_target.global_position)
			if current_distance - challenger_distance < same_priority_switch_distance:
				return _current_target

	_current_target = best_target
	return _current_target

func _is_valid_target(target: Variant, from_position: Vector2, filter: Callable) -> bool:
	if not is_instance_valid(target) or not target is Node2D:
		return false
	var target_node := target as Node2D
	if not target_node.is_inside_tree():
		return false
	if target_node.has_method("is_dead") and target_node.is_dead():
		return false
	for group_name: String in _disabled_groups:
		if target_node.is_in_group(group_name):
			return false
	if max_range >= 0.0 and from_position.distance_squared_to(target_node.global_position) > max_range * max_range:
		return false
	return not filter.is_valid() or filter.call(target_node)

func _get_target_priority(target: Node2D) -> int:
	for config: TargetConfig in _sorted_configs:
		if target.is_in_group(config.group_name):
			return config.priority
	return -1
