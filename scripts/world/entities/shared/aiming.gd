extends Node
class_name AimingComponent

## Handles aiming logic for entities (turrets, enemies, player)
## Supports both instant aiming and smooth rotation

## Aim speed in radians per second. Set to 0 for instant aiming
@export var aim_speed := 0.0

## Accuracy tolerance in radians. Only relevant when aim_speed > 0.
@export var accuracy_angle := 0.2

## Optional Node2D to visually rotate (e.g., turret canon)
@export var visual_node: Node2D = null

## Optional presentation nodes for a side-perspective cannon.
@export var feet_path: NodePath
@export var graphic_path: NodePath
@export_range(0.0, 1440.0, 10.0) var visual_turn_speed_degrees := 720.0
@export_range(-180.0, 180.0, 1.0) var visual_forward_angle_degrees := 0.0

## Optional spawn point for projectiles. Falls back to pivot if not set.
@export var muzzle: Node2D = null

## Rotation offset for visual node (e.g., -PI/2 for sprites facing up)
@export var visual_offset := 0.0

## Current aim angle in radians
var current_angle := 0.0
var feet: Sprite2D
var graphic: Sprite2D
var _visual_target_rotation := 0.0

func _ready() -> void:
	feet = get_node_or_null(feet_path) as Sprite2D
	graphic = get_node_or_null(graphic_path) as Sprite2D
	if visual_node:
		_visual_target_rotation = visual_node.global_rotation

func _process(delta: float) -> void:
	if visual_node:
		visual_node.global_rotation = rotate_toward(
			visual_node.global_rotation,
			_visual_target_rotation,
			deg_to_rad(visual_turn_speed_degrees) * delta)

func initialize(s_aim_speed: float, s_accuracy_angle: float) -> void:
	aim_speed = s_aim_speed
	accuracy_angle = s_accuracy_angle

## Returns the rotation pivot: visual_node position if set, else parent position
func _get_pivot() -> Vector2:
	if visual_node:
		return visual_node.global_position
	return (get_parent() as Node2D).global_position

## Aim at a target position
func aim_at(target_pos: Vector2, delta: float) -> void:
	var target_offset := target_pos - _get_pivot()
	if target_offset.is_zero_approx():
		return
	var target_angle := target_offset.angle()
	
	if aim_speed <= 0.0:
		current_angle = target_angle
	else:
		current_angle = lerp_angle(current_angle, target_angle, aim_speed * delta)
	
	if visual_node:
		_visual_target_rotation = target_angle + visual_forward_angle_degrees
		if feet:
			feet.flip_h = target_offset.x < 0.0
		if graphic:
			graphic.flip_h = false
			graphic.flip_v = target_offset.x < 0.0

## Get the current aim angle in radians
func get_current_angle() -> float:
	return current_angle

## Get the current aim direction as a normalized vector
func get_aim_direction() -> Vector2:
	return Vector2.from_angle(current_angle)

## Get the projectile spawn position
func get_muzzle_position() -> Vector2:
	if muzzle:
		return muzzle.global_position
	return _get_pivot()

## Check if currently aimed at the target within accuracy_angle tolerance
func is_aimed_at(target_pos: Vector2) -> bool:
	if aim_speed <= 0.0:
		return true
	
	var target_angle := (target_pos - _get_pivot()).angle()
	return abs(angle_difference(current_angle, target_angle)) < accuracy_angle
