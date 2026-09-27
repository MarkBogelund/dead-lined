extends PixelRotatedSprite
class_name DashDirectionIndicator

## Sprite pointing where the dash will go, shown only while charging.

func _ready() -> void:
	super()
	# Positioned manually on whole pixels so the rotation grid never shifts by sub-pixel player movement.
	top_level = true

func point_in(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	global_position = (get_parent() as Node2D).global_position.round()
	point_at(direction.angle())
	fade_to(1.0)

func fade_out() -> void:
	fade_to(0.0)
