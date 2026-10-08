extends Node2D
class_name AimIndicator

## Freely rotating aim pivot whose sprite counter-rotates to remain globally upright.

@export var texture: Texture2D:
	set(value):
		texture = value
		_sync_sprite()
@export_range(1.0, 64.0, 1.0) var distance := 24.0:
	set(value):
		distance = value
		_sync_sprite()
@export var color := Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		color = value
		_sync_sprite()

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_sync_sprite()

func point_in(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	rotation = direction.angle()
	sprite.rotation = - global_rotation

func _sync_sprite() -> void:
	if not is_node_ready():
		return
	sprite.texture = texture
	sprite.position = Vector2(distance, 0.0)
	sprite.modulate = color
