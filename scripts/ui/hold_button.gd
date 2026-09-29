extends TextureButton
class_name HoldButton

## Press and hold for hold_duration to emit hold_completed.
## Progress is drawn by the hold_progress shader on progress_target, masked to its opaque pixels.
## Releasing, disabling, or hiding the button cancels the hold; a new press is required to repeat.

signal hold_started
## Emitted on release, cancel, or right before hold_completed.
signal hold_ended
signal hold_completed

@export var progress_shader: Shader
@export_range(0.1, 5.0, 0.05) var hold_duration := 0.8
@export var progress_target: Control
@export var fill_color := Color(1.0, 1.0, 1.0, 0.35)

var _holding := false
var _progress := 0.0
var _material: ShaderMaterial

func _ready() -> void:
	if not progress_target:
		push_error("%s: HoldButton requires progress_target" % name)
		return
	if not progress_shader:
		push_error("%s: HoldButton requires progress_shader" % name)
		return
	_material = ShaderMaterial.new()
	_material.shader = progress_shader
	_material.set_shader_parameter("fill_color", fill_color)
	progress_target.material = _material
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
		hold_ended.emit()
		hold_completed.emit()

func _on_button_down() -> void:
	_holding = true
	hold_started.emit()

func _cancel_hold() -> void:
	var was_holding := _holding
	_holding = false
	_set_progress(0.0)
	if was_holding:
		hold_ended.emit()

func _set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	_material.set_shader_parameter("rect_size", progress_target.size)
	_material.set_shader_parameter("progress", _progress)
