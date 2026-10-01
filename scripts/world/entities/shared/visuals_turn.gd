extends Node2D
class_name VisualsTurnComponent

@export var feet_path: NodePath
@export var canon_path: NodePath
@export var graphic_path: NodePath
## Smooth cannon turn speed in degrees per second.
@export_range(0.0, 1440.0, 10.0) var turn_speed_degrees := 720.0
## Matches the authored cannon orientation used by AimingComponent.visual_offset.
@export_range(-180.0, 180.0, 1.0) var canon_forward_angle_degrees := 0.0

var _feet: Sprite2D
var _canon: Node2D
var _graphic: Sprite2D
var _target_rotation := 0.0
var _initialized := false

func _ready() -> void:
	_feet = get_node_or_null(feet_path) as Sprite2D
	_canon = get_node_or_null(canon_path) as Node2D
	_graphic = get_node_or_null(graphic_path) as Sprite2D
	if not _graphic and _canon is Sprite2D:
		_graphic = _canon as Sprite2D
	if not _feet:
		push_error("%s requires a valid feet_path" % name)
	if not _canon:
		push_error("%s requires a valid canon_path" % name)
	if not _graphic:
		push_error("%s requires a valid graphic_path or a Sprite2D canon" % name)
	else:
		_target_rotation = _canon.global_rotation
		_initialized = true

func turn_to(target_position: Vector2) -> void:
	var offset := target_position - global_position
	if offset.is_zero_approx():
		return
	var facing_right := offset.x >= 0.0
	if _feet:
		_feet.flip_h = not facing_right
	if _canon:
		if _graphic:
			_graphic.flip_h = false
			_graphic.flip_v = not facing_right
		_target_rotation = offset.angle() + deg_to_rad(canon_forward_angle_degrees)

func _process(delta: float) -> void:
	if not _initialized or not _canon:
		return
	_canon.global_rotation = rotate_toward(
		_canon.global_rotation,
		_target_rotation,
		deg_to_rad(turn_speed_degrees) * delta)