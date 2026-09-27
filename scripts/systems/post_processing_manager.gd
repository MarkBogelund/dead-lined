extends CanvasLayer

## Global source-keyed API for world-only full-screen effects. UI renders on a higher CanvasLayer.

const COMPOSITOR_SHADER := preload("res://shaders/post_processing.gdshader")
const SETTINGS := preload("res://resources/player/post_processing_settings.tres")

const DASH_DESATURATION := &"dash_desaturation"
const CAPACITY_OVERLAY := &"capacity"
const CRUNCH_TIME_OVERLAY := &"crunch_time"

var _surface: ColorRect
var _material: ShaderMaterial
var _overlay_requests: Dictionary[StringName, Dictionary] = {}
var _screen_effects: Dictionary[StringName, StringName] = {
	DASH_DESATURATION: &"desaturation_amount",
}
var _screen_amounts: Dictionary[StringName, float] = {
	DASH_DESATURATION: 0.0,
}
var _screen_tweens: Dictionary[StringName, Tween] = {}
var _overlay_tween: Tween
var _overlay_color := Color.WHITE
var _overlay_intensity := 0.0
var _overlay_pulse_speed := 0.0

func _ready() -> void:
	layer = 1
	_surface = ColorRect.new()
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	_material = ShaderMaterial.new()
	_material.shader = COMPOSITOR_SHADER
	_material.set_shader_parameter("max_desaturation", SETTINGS.dash_max_desaturation)
	_material.set_shader_parameter("darken", SETTINGS.dash_darken)
	_surface.material = _material
	_surface.hide()

func _process(_delta: float) -> void:
	var pulse := 1.0
	if _overlay_pulse_speed > 0.0:
		pulse = 0.75 + 0.25 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * _overlay_pulse_speed))
	_material.set_shader_parameter("overlay_color", _overlay_color)
	_material.set_shader_parameter("overlay_intensity", _overlay_intensity * pulse)

func set_color_overlay(source: StringName, color: Color, intensity: float, priority := 0, fade_duration := 0.0, pulse_speed := 0.0) -> void:
	_overlay_requests[source] = {
		"color": color,
		"intensity": clampf(intensity, 0.0, 1.0),
		"priority": priority,
		"fade_duration": maxf(fade_duration, 0.0),
		"pulse_speed": maxf(pulse_speed, 0.0),
	}
	_resolve_overlay()

func clear_color_overlay(source: StringName, fade_duration := 0.0) -> void:
	_overlay_requests.erase(source)
	_resolve_overlay(maxf(fade_duration, 0.0))

## Registers a scalar shader uniform so new composited effects use the same fade API.
func register_screen_effect(effect: StringName, uniform_name: StringName, initial_amount := 0.0) -> void:
	_screen_effects[effect] = uniform_name
	_screen_amounts[effect] = clampf(initial_amount, 0.0, 1.0)
	_material.set_shader_parameter(uniform_name, _screen_amounts[effect])
	_refresh_visibility()

func set_screen_effect(effect: StringName, amount: float, duration := 0.0, ignore_time_scale := false) -> void:
	if not _screen_effects.has(effect):
		push_error("PostProcessingManager has no registered screen effect '%s'" % effect)
		return
	if _screen_tweens.has(effect):
		_screen_tweens[effect].kill()
	var target := clampf(amount, 0.0, 1.0)
	if duration <= 0.0:
		_set_screen_amount(target, effect)
		return
	var tween := create_tween().set_ignore_time_scale(ignore_time_scale)
	_screen_tweens[effect] = tween
	tween.tween_method(_set_screen_amount.bind(effect), _screen_amounts[effect], target, maxf(duration, 0.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func set_effect_parameter(parameter: StringName, value: Variant) -> void:
	_material.set_shader_parameter(parameter, value)

func reset() -> void:
	if _overlay_tween:
		_overlay_tween.kill()
	for tween: Tween in _screen_tweens.values():
		tween.kill()
	_screen_tweens.clear()
	_overlay_requests.clear()
	_overlay_color = Color.WHITE
	_overlay_intensity = 0.0
	_overlay_pulse_speed = 0.0
	for effect: StringName in _screen_amounts:
		_set_screen_amount(0.0, effect)
	_material.set_shader_parameter("overlay_intensity", 0.0)
	_refresh_visibility()

func update_capacity_overlay(capacity: float, maximum: float) -> void:
	var fraction := clampf(capacity / maximum if maximum > 0.0 else 0.0, 0.0, 1.0)
	if fraction <= 0.5:
		var progress := 1.0 - fraction / 0.5
		var intensity := SETTINGS.danger_curve.sample(progress) if SETTINGS.danger_curve else progress
		set_color_overlay(CAPACITY_OVERLAY, SETTINGS.danger_color, intensity, SETTINGS.capacity_priority)
	else:
		var progress := (fraction - 0.5) / 0.5
		var intensity := SETTINGS.good_curve.sample(progress) if SETTINGS.good_curve else progress
		set_color_overlay(CAPACITY_OVERLAY, SETTINGS.good_color, intensity, SETTINGS.capacity_priority)

func set_crunch_time_overlay(active: bool, effects: CrunchTimeEffects) -> void:
	if active:
		set_color_overlay(
			CRUNCH_TIME_OVERLAY,
			effects.active_overlay_color,
			effects.active_overlay_intensity,
			SETTINGS.crunch_time_priority,
			SETTINGS.crunch_time_fade_duration,
			effects.active_overlay_pulse_speed)
	else:
		clear_color_overlay(CRUNCH_TIME_OVERLAY, SETTINGS.crunch_time_fade_duration)

func _set_screen_amount(value: float, effect: StringName) -> void:
	_screen_amounts[effect] = value
	_material.set_shader_parameter(_screen_effects[effect], value)
	_refresh_visibility()

func _resolve_overlay(override_duration := -1.0) -> void:
	var selected: Dictionary = {}
	for request: Dictionary in _overlay_requests.values():
		if selected.is_empty() or request["priority"] > selected["priority"]:
			selected = request
	var target_color := selected.get("color", _overlay_color) as Color
	var target_intensity := float(selected.get("intensity", 0.0))
	var duration := override_duration if override_duration >= 0.0 else float(selected.get("fade_duration", 0.0))
	_overlay_pulse_speed = float(selected.get("pulse_speed", 0.0))
	if _overlay_tween:
		_overlay_tween.kill()
	if duration <= 0.0:
		_overlay_color = target_color
		_overlay_intensity = target_intensity
		_material.set_shader_parameter("overlay_color", _overlay_color)
		_material.set_shader_parameter("overlay_intensity", _overlay_intensity)
		_refresh_visibility()
		return
	_overlay_tween = create_tween().set_parallel()
	_overlay_tween.tween_property(self, "_overlay_color", target_color, duration)
	_overlay_tween.tween_property(self, "_overlay_intensity", target_intensity, duration)
	_overlay_tween.finished.connect(_refresh_visibility)
	_surface.show()

func _refresh_visibility() -> void:
	var has_screen_effect := false
	for amount: float in _screen_amounts.values():
		if amount > 0.0:
			has_screen_effect = true
			break
	_surface.visible = has_screen_effect or _overlay_intensity > 0.0