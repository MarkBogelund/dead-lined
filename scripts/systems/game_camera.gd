@tool
extends Camera2D
class_name GameCamera

## Sole owner of zoom: sources set named factors (e.g. crunch time, dash charge) that multiply onto the base zoom.

const CRUNCH_TIME_SOURCE := &"crunch_time"

@export_group("Crunch Time")
@export_range(1.0, 3.0, 0.01) var crunch_time_zoom_factor := 1.75
@export_range(0.0, 2.0, 0.01) var crunch_time_zoom_duration := 0.35

var _base_zoom := Vector2.ONE
var _factors: Dictionary[StringName, float] = {}
var _tweens: Dictionary[StringName, Tween] = {}
var _zoom_ready := false

@export_group("Cinematics")
## Animation-owned multiplier; RESET must set it to 1. Other zoom effects still compose with it.
@export_range(0.1, 4.0, 0.01) var game_over_zoom_factor := 1.0:
	set(value):
		game_over_zoom_factor = value
		if _zoom_ready:
			_update_zoom()

func _ready() -> void:
	_base_zoom = zoom
	_zoom_ready = true
	_update_zoom()

## Tweens this source's factor; 1.0 removes it. ignore_time_scale keeps the fade real-time during slow-motion.
func set_zoom_factor(source: StringName, factor: float, duration: float, ignore_time_scale := false) -> void:
	if _tweens.has(source):
		_tweens[source].kill()
	var tween := create_tween().set_ignore_time_scale(ignore_time_scale)
	_tweens[source] = tween
	tween.tween_method(_set_factor.bind(source), _factors.get(source, 1.0), factor, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func set_crunch_time_active(active: bool) -> void:
	set_zoom_factor(CRUNCH_TIME_SOURCE, crunch_time_zoom_factor if active else 1.0, crunch_time_zoom_duration)

func _set_factor(value: float, source: StringName) -> void:
	_factors[source] = value
	_update_zoom()

func _update_zoom() -> void:
	var total := game_over_zoom_factor
	for factor: float in _factors.values():
		total *= factor
	zoom = _base_zoom * total
