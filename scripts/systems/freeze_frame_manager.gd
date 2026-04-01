extends Node
class_name FreezeFrameManager

## Manages freeze frames (hitstop) for impact effects

@export var default_duration := 0.08 ## Default freeze duration

func _ready() -> void:
	add_to_group("freeze_frame_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS ## Work even when time_scale = 0

## Freeze the game for impact
func freeze(duration: float = -1.0) -> void:
	var freeze_time = duration if duration > 0 else default_duration
	Engine.time_scale = 0.0
	await get_tree().create_timer(freeze_time, true, false, true).timeout
	Engine.time_scale = 1.0
