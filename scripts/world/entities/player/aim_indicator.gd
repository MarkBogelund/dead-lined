extends Node2D
class_name AimIndicator

## Pixel-art aim marker: moves around the player on whole pixels instead of rotating a sprite.

@export_range(1.0, 64.0, 1.0) var distance := 24.0
@export_range(0, 8, 1) var dot_radius := 2:
	set(value):
		dot_radius = value
		queue_redraw()
@export var color := Color(0.165, 0.165, 0.165, 1.0):
	set(value):
		color = value
		queue_redraw()

func point_in(direction: Vector2) -> void:
	position = (direction.normalized() * distance).round()

func _draw() -> void:
	# The +0.8 rounds the disc edge so small radii read as circles, not diamonds.
	var radius_sq := dot_radius * dot_radius + dot_radius * 0.8
	for y in range(-dot_radius, dot_radius + 1):
		for x in range(-dot_radius, dot_radius + 1):
			if x * x + y * y <= radius_sq:
				draw_rect(Rect2(x, y, 1, 1), color)
