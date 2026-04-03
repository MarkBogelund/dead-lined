extends Node
class_name AimingComponent

## Handles aiming logic for entities (turrets, enemies, player)
## Supports both instant aiming and smooth rotation

## Aim speed in radians per second. Set to 0 for instant aiming
@export var aim_speed := 0.0

## Optional Node2D to visually rotate (e.g., turret canon)
@export var visual_node: Node2D = null

## Rotation offset for visual node (e.g., -PI/2 for sprites facing up)
@export var visual_offset := 0.0

## Current aim angle in radians
var current_angle := 0.0

## Aim at a target position from a given origin
## Returns true if aiming is complete (within tolerance or instant)
func aim_at(target_pos: Vector2, from_pos: Vector2, delta: float) -> void:
	var target_angle := (target_pos - from_pos).angle()
	
	if aim_speed <= 0.0:
		# Instant aiming
		current_angle = target_angle
	else:
		# Smooth aiming
		current_angle = lerp_angle(current_angle, target_angle, aim_speed * delta)
	
	# Update visual node if assigned
	if visual_node:
		visual_node.rotation = current_angle + visual_offset

## Get the current aim angle in radians
func get_current_angle() -> float:
	return current_angle

## Get the current aim direction as a normalized vector
func get_aim_direction() -> Vector2:
	return Vector2.from_angle(current_angle)

## Check if currently aimed at the target within the given tolerance (radians)
func is_aimed_at(target_pos: Vector2, from_pos: Vector2, tolerance: float) -> bool:
	if aim_speed <= 0.0:
		# Instant aiming is always accurate
		return true
	
	var target_angle := (target_pos - from_pos).angle()
	return abs(angle_difference(current_angle, target_angle)) < tolerance

## Set the current angle directly (useful for initialization)
func set_angle(angle: float) -> void:
	current_angle = angle
	if visual_node:
		visual_node.rotation = current_angle + visual_offset
