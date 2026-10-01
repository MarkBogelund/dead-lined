extends Node2D
class_name VisualsTurnComponent

@export var feet_path: NodePath
@export var canon_path: NodePath
## Total vertical viewing arc: 0 = locked outward, 90 = +/-45 degrees, 180 = down to up.
@export_range(0.0, 180.0, 1.0) var canon_turn_degrees := 180.0

var _feet: Sprite2D
var _canon: Sprite2D

func _ready() -> void:
	_feet = get_node_or_null(feet_path) as Sprite2D
	_canon = get_node_or_null(canon_path) as Sprite2D
	if not _feet:
		push_error("%s requires a valid feet_path" % name)
	if not _canon:
		push_error("%s requires a valid canon_path" % name)

func turn_to(target_position: Vector2) -> void:
	var offset := target_position - global_position
	if offset.is_zero_approx():
		return
	var facing_right := offset.x >= 0.0
	if _feet:
		_feet.flip_h = not facing_right
	if _canon:
		_canon.flip_h = not facing_right
		var facing_offset := Vector2(absf(offset.x), offset.y)
		var target_angle := rad_to_deg(facing_offset.angle())
		var vertical_angle := clampf(90.0 - target_angle, 0.0, 180.0)
		var half_arc := canon_turn_degrees * 0.5
		vertical_angle = clampf(vertical_angle, 90.0 - half_arc, 90.0 + half_arc)
		_canon.rotation = deg_to_rad(90.0 - vertical_angle)