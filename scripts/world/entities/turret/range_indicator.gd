extends Node2D
class_name RangeIndicator

@export var color := Color(1.0, 1.0, 1.0, 0.35)
@export var line_width := 1.0
@export var segments := 64

var radius: float = 0.0
var inner_radius: float = -1.0
var _fade_tween: Tween

func _ready() -> void:
	visible = false

func initialize(p_radius: float, p_inner_radius: float = -1.0) -> void:
	radius = p_radius
	inner_radius = clampf(p_inner_radius, 0.0, radius) if p_inner_radius >= 0.0 else -1.0
	queue_redraw()

func show_indicator(fade_duration := 0.0) -> void:
	if visible:
		return
	visible = true
	modulate.a = 0.0 if fade_duration > 0.0 else 1.0
	if fade_duration > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)

func hide_indicator() -> void:
	if _fade_tween:
		_fade_tween.kill()
	visible = false

func _draw() -> void:
	if radius > 0.0:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, segments, color, line_width)
	if inner_radius > 0.0:
		draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, segments, color, line_width)
