extends Node2D
class_name AimIndicator

## Pixel-art aim marker: orbits the player on whole pixels and never rotates, so the texture stays upright.

@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export_range(1.0, 64.0, 1.0) var distance := 24.0
@export var color := Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		color = value
		queue_redraw()

func point_in(direction: Vector2) -> void:
	position = (direction.normalized() * distance).round()

func _draw() -> void:
	if not texture:
		return
	# Floored so odd-sized textures still land on whole pixels.
	draw_texture(texture, (-texture.get_size() * 0.5).floor(), color)
