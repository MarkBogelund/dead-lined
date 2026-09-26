extends Camera2D
class_name GameCamera

## Sole owner of zoom: sources set named factors (e.g. crunch time, dash charge) that multiply onto the base zoom.

var _base_zoom := Vector2.ONE
var _factors: Dictionary[StringName, float] = {}
var _tweens: Dictionary[StringName, Tween] = {}

func _ready() -> void:
	_base_zoom = zoom

## Tweens this source's factor; 1.0 removes it. ignore_time_scale keeps the fade real-time during slow-motion.
func set_zoom_factor(source: StringName, factor: float, duration: float, ignore_time_scale := false) -> void:
	if _tweens.has(source):
		_tweens[source].kill()
	var tween := create_tween().set_ignore_time_scale(ignore_time_scale)
	_tweens[source] = tween
	tween.tween_method(_set_factor.bind(source), _factors.get(source, 1.0), factor, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_factor(value: float, source: StringName) -> void:
	_factors[source] = value
	var total := 1.0
	for factor: float in _factors.values():
		total *= factor
	zoom = _base_zoom * total
