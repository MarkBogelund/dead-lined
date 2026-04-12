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

## Get the best target based on configured priorities and proximity
## Returns null if no valid targets found
func get_best_target(from_position: Vector2) -> Node2D:
	if target_configs.is_empty():
		return null
	
	# Sort configs by priority (highest first) if not already sorted
	var sorted_configs := target_configs.duplicate()
	sorted_configs.sort_custom(func(a, b): return a.priority > b.priority)
	
	var best_target: Node2D = null
	var best_distance_sq := INF
	var best_priority := -1
	
	# Scan through all priority groups
	for config in sorted_configs:
		if config.group_name.is_empty():
			continue
		
		var nodes := get_tree().get_nodes_in_group(config.group_name)
		
		for node in nodes:
			# Skip invalid nodes
			if not is_instance_valid(node) or not node is Node2D:
				continue
			
			# Skip self
			if node == get_parent():
				continue
			
			# Skip dead entities if they have is_dead() method
			if node.has_method("is_dead") and node.is_dead():
				continue
			
			var distance_sq := from_position.distance_squared_to(node.global_position)
			
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
	
	return best_target
