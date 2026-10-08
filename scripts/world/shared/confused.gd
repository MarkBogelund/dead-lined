extends AnimatedSprite2D
class_name ConfusedComponent

signal confusion_ended

var _time_left := 0.0
var _movement_lock_time_left := 0.0

func _ready() -> void:
	stop_confusion()

func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left = maxf(0.0, _time_left - delta)
	_movement_lock_time_left = maxf(0.0, _movement_lock_time_left - delta)
	if _time_left <= 0.0:
		stop_confusion()
		confusion_ended.emit()

func start_confusion(duration: float, movement_lock_duration := 0.0) -> void:
	_time_left = maxf(0.0, duration)
	_movement_lock_time_left = minf(maxf(0.0, movement_lock_duration), _time_left)
	if _time_left <= 0.0:
		stop_confusion()
		return
	visible = true
	play()

func stop_confusion() -> void:
	_time_left = 0.0
	_movement_lock_time_left = 0.0
	visible = false
	stop()

func is_confused() -> bool:
	return _time_left > 0.0

func is_movement_locked() -> bool:
	return _movement_lock_time_left > 0.0