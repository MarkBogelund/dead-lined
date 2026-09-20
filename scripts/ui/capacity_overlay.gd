extends ColorRect
class_name CapacityOverlay

@export_group("Danger (0% capacity)")
@export var danger_color: Color = Color(0.4, 0.0, 0.0, 1.0)
@export var danger_curve: Curve ## X = 0 at 50%, 1 at 0% — Y = intensity (0-1)

@export_group("Good (100% capacity)")
@export var good_color: Color = Color(1.0, 0.82, 0.2, 1.0)
@export var good_curve: Curve ## X = 0 at 50%, 1 at 100% — Y = intensity (0-1)

@export var crunch_time_effects: CrunchTimeEffects = preload("res://resources/crunch_time_effects.tres")

var _active_crunch_time := false
var _last_capacity := 0.0
var _last_maximum := 1.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/low_capacity.gdshader")
	mat.set_shader_parameter("overlay_color", normal_color())
	mat.set_shader_parameter("intensity", 0.0)
	material = mat

func _process(_delta: float) -> void:
	if _active_crunch_time and crunch_time_effects:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * crunch_time_effects.active_overlay_pulse_speed)
		material.set_shader_parameter("overlay_color", crunch_time_effects.active_overlay_color)
		material.set_shader_parameter("intensity", crunch_time_effects.active_overlay_intensity * (0.75 + pulse * 0.25))

func normal_color() -> Color:
	return crunch_time_effects.normal_overlay_color if crunch_time_effects else Color(0.65, 0.3, 0.05, 0.3)

func set_crunch_time_active(active: bool) -> void:
	_active_crunch_time = active
	if active:
		material.set_shader_parameter("overlay_color", crunch_time_effects.active_overlay_color if crunch_time_effects else Color(1.0, 0.68, 0.12, 1.0))
		material.set_shader_parameter("intensity", crunch_time_effects.active_overlay_intensity if crunch_time_effects else 0.95)
	else:
		_update_capacity_from_value(_last_capacity / _last_maximum if _last_maximum > 0.0 else 0.0)

func update_capacity(capacity: float, maximum: float) -> void:
	_last_capacity = capacity
	_last_maximum = maximum
	if _active_crunch_time:
		return
	var fraction := capacity / maximum if maximum > 0.0 else 0.0
	_update_capacity_from_value(fraction)

func _update_capacity_from_value(fraction: float) -> void:
	if _active_crunch_time:
		return
	if fraction <= 0.5:
		var p := 1.0 - (fraction / 0.5)
		var intensity := danger_curve.sample(p) if danger_curve else p
		material.set_shader_parameter("overlay_color", danger_color)
		material.set_shader_parameter("intensity", intensity)
	else:
		var p := (fraction - 0.5) / 0.5
		var intensity := good_curve.sample(p) if good_curve else p
		material.set_shader_parameter("overlay_color", good_color)
		material.set_shader_parameter("intensity", intensity)
