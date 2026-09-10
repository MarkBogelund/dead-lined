extends ColorRect
class_name CapacityOverlay

@export_group("Danger (0% capacity)")
@export var danger_color: Color = Color(0.4, 0.0, 0.0, 1.0)
@export var danger_curve: Curve ## X = 0 at 50%, 1 at 0% — Y = intensity (0-1)

@export_group("Good (100% capacity)")
@export var good_color: Color = Color(1.0, 0.82, 0.2, 1.0)
@export var good_curve: Curve ## X = 0 at 50%, 1 at 100% — Y = intensity (0-1)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/low_capacity.gdshader")
	mat.set_shader_parameter("overlay_color", danger_color)
	mat.set_shader_parameter("intensity", 0.0)
	material = mat

func update_capacity(capacity: float, maximum: float) -> void:
	var fraction := capacity / maximum if maximum > 0.0 else 0.0
	if fraction <= 0.5:
		var p := 1.0 - (fraction / 0.5) # 0 at 50%, 1 at 0%
		var intensity := danger_curve.sample(p) if danger_curve else p
		material.set_shader_parameter("overlay_color", danger_color)
		material.set_shader_parameter("intensity", intensity)
	else:
		var p := (fraction - 0.5) / 0.5 # 0 at 50%, 1 at 100%
		var intensity := good_curve.sample(p) if good_curve else p
		material.set_shader_parameter("overlay_color", good_color)
		material.set_shader_parameter("intensity", intensity)
