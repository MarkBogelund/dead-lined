extends Node2D
class_name TurretExclusionZone

@export var exclusion_color := Color(1.0, 0.4, 0.2, 0.12)
@export var invalid_color := Color(1.0, 0.1, 0.1, 0.25)

var exclusion_radius: float = 80.0
var _invalid := false

func _ready() -> void:
	add_to_group("turret_exclusion_zones")
	visible = false

func initialize(radius: float) -> void:
	exclusion_radius = radius
	queue_redraw()

func set_invalid(value: bool) -> void:
	if value != _invalid:
		_invalid = value
		queue_redraw()

func _draw() -> void:
	if exclusion_radius > 0.0:
		var color := invalid_color if _invalid else exclusion_color
		draw_circle(Vector2.ZERO, exclusion_radius, color)
