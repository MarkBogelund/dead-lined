extends Node
class_name TimeScaleManager

## Sole owner of Engine.time_scale. Sources request a scale by name; the slowest active request wins.

@export var default_freeze_duration := 0.08

var _requests: Dictionary[StringName, float] = {}
var _next_freeze_id := 0

func _ready() -> void:
	add_to_group("time_scale_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS

func _exit_tree() -> void:
	_requests.clear()
	Engine.time_scale = 1.0

func request(source: StringName, scale: float) -> void:
	_requests[source] = clampf(scale, 0.0, 1.0)
	_apply()

func release(source: StringName) -> void:
	if _requests.erase(source):
		_apply()

## Hitstop: holds time at 0 for duration real seconds, then returns to whatever else is requested.
func freeze(duration: float = -1.0) -> void:
	var source := StringName("freeze_%d" % _next_freeze_id)
	_next_freeze_id += 1
	request(source, 0.0)
	await get_tree().create_timer(duration if duration > 0.0 else default_freeze_duration, true, false, true).timeout
	release(source)

func _apply() -> void:
	var scale := 1.0
	for value: float in _requests.values():
		scale = minf(scale, value)
	Engine.time_scale = scale
