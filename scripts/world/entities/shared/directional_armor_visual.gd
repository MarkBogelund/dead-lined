extends Node2D
class_name DirectionalArmorVisual

@export var radius := 18.0
@export var line_width := 3.0
@export var armored_color := Color(0.7, 0.85, 0.9, 1.0)
@export var stress_color := Color(1.0, 0.15, 0.1, 1.0)
@export var broken_color := Color(1.0, 0.25, 0.15, 0.4)

var _half_arc := deg_to_rad(60.0)
var _stress := 0.0
var _broken := false

func configure(arc_degrees: float) -> void:
	_half_arc = deg_to_rad(arc_degrees * 0.5)
	queue_redraw()

func set_facing(angle: float) -> void:
	global_rotation = angle

func set_stress(progress: float) -> void:
	_stress = clampf(progress, 0.0, 1.0)
	queue_redraw()

func set_broken(value: bool) -> void:
	_broken = value
	queue_redraw()

func _draw() -> void:
	if _broken:
		draw_arc(Vector2.ZERO, radius + 2.0, -_half_arc, -_half_arc * 0.6, 8, broken_color, line_width)
		draw_arc(Vector2.ZERO, radius + 2.0, _half_arc * 0.6, _half_arc, 8, broken_color, line_width)
	else:
		draw_arc(Vector2.ZERO, radius, -_half_arc, _half_arc, 32, armored_color.lerp(stress_color, _stress), line_width)