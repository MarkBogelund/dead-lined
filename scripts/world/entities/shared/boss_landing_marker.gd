extends Node2D
class_name BossLandingMarker

@export var radius := 32.0
@export var line_width := 2.0
@export var warning_color := Color(1.0, 0.25, 0.1, 0.9)
@export var impact_color := Color(1.0, 0.95, 0.8, 0.85)
@export_range(0.0, 1.0, 0.01) var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var _impact := false

func show_warning() -> void:
	_impact = false
	progress = 0.0
	show()

func show_impact() -> void:
	_impact = true
	progress = 0.0
	show()

func _draw() -> void:
	if _impact:
		var color := impact_color
		color.a *= 1.0 - progress
		draw_arc(Vector2.ZERO, radius * (1.0 + progress), 0.0, TAU, 48, color, line_width)
		return
	var color := warning_color
	color.a *= 0.35 + 0.65 * progress
	var fill_color := color
	fill_color.a *= 0.12
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, line_width)
	draw_arc(Vector2.ZERO, radius * (1.6 - progress * 0.6), 0.0, TAU, 48, color, 1.0)
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(direction * radius * 0.7, direction * radius * 1.15, color, line_width)