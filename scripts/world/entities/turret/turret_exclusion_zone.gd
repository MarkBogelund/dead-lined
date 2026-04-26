extends Node2D
class_name TurretExclusionZone

@export var exclusion_color := Color(1.0, 0.4, 0.2, 0.12)

var exclusion_radius: float = 80.0

func _ready() -> void:
	add_to_group("turret_exclusion_zones")
	visible = false

func initialize(radius: float) -> void:
	exclusion_radius = radius
	queue_redraw()

func _draw() -> void:
	if exclusion_radius > 0.0:
		draw_circle(Vector2.ZERO, exclusion_radius, exclusion_color)
