@tool
extends Node2D
class_name PixelCircle

enum Shape {CIRCLE, ELLIPSE}

## A circle fits the smaller size axis; an ellipse uses both axes.
@export var shape := Shape.CIRCLE:
	set(value):
		shape = value
		queue_redraw()

## Local pixel bounds of the filled shape.
@export var size := Vector2i(16, 16):
	set(value):
		size = Vector2i(maxi(1, value.x), maxi(1, value.y))
		queue_redraw()

## Width and height of each square raster step, in local units.
@export_range(1, 16, 1) var pixel_size := 2:
	set(value):
		pixel_size = maxi(1, value)
		queue_redraw()

func _draw() -> void:
	var half_size := Vector2(size) * 0.5
	var circle_diameter := float(mini(size.x, size.y))
	var circle_radius := circle_diameter * 0.5
	var step := maxi(1, pixel_size)
	var top := -half_size.y
	var left := -half_size.x

	for y in range(0, size.y, step):
		var row_height := mini(step, size.y - y)
		var sample_y := float(y) + float(row_height) * 0.5
		var first_pixel := -1
		var last_pixel := 0
		for x in range(0, size.x, step):
			var column_width := mini(step, size.x - x)
			var sample_x := float(x) + float(column_width) * 0.5
			var normalized: Vector2
			if shape == Shape.CIRCLE:
				normalized = (Vector2(sample_x, sample_y) - half_size) / circle_radius
			else:
				normalized = (Vector2(sample_x, sample_y) - half_size) / half_size
			if normalized.length_squared() <= 1.0:
				if first_pixel < 0:
					first_pixel = x
				last_pixel = x + column_width
		if first_pixel >= 0:
			draw_rect(
				Rect2(Vector2(left + first_pixel, top + y), Vector2(last_pixel - first_pixel, row_height)),
				Color.WHITE
			)