extends Node2D
class_name DashDirectionIndicator

## Thin line from the player toward where the dash will go; shown only while charging.

@export_range(0.0, 64.0, 1.0) var start_offset := 8.0
@export_range(1.0, 128.0, 1.0) var length := 24.0
## Width at the end nearest the player; the line tapers to tip_width.
@export_range(0.0, 8.0, 0.5) var base_width := 3.0
@export_range(0.0, 8.0, 0.5) var tip_width := 0.0
@export var color := Color(1.0, 1.0, 1.0, 0.85)

var _direction := Vector2.RIGHT

func _ready() -> void:
	hide()

func point_in(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	_direction = direction.normalized()
	show()
	queue_redraw()

func _draw() -> void:
	var start := (_direction * start_offset).round()
	var end := (_direction * (start_offset + length)).round()
	var side := _direction.orthogonal()
	var points := PackedVector2Array([
		start + side * base_width * 0.5,
		end + side * tip_width * 0.5,
		end - side * tip_width * 0.5,
		start - side * base_width * 0.5])
	draw_colored_polygon(points, color)
