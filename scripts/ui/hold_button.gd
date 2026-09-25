extends TextureButton
class_name HoldButton

## Press and hold for hold_duration to emit hold_completed. Progress is shown by the child ProgressFill.
## Releasing, disabling, or hiding the button cancels the hold; a new press is required to repeat.

signal hold_completed

@export_range(0.1, 5.0, 0.05) var hold_duration := 0.8

@onready var progress_fill: Control = $ProgressFill

var _holding := false
var _progress := 0.0

func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_cancel_hold)
	_set_progress(0.0)

func _process(delta: float) -> void:
	if not _holding:
		return
	if disabled or not is_visible_in_tree():
		_cancel_hold()
		return
	_set_progress(_progress + delta / hold_duration)
	if _progress >= 1.0:
		_holding = false
		_set_progress(0.0)
		hold_completed.emit()

func _on_button_down() -> void:
	_holding = true

func _cancel_hold() -> void:
	_holding = false
	_set_progress(0.0)

func _set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	progress_fill.anchor_right = _progress
