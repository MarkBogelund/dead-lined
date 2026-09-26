extends ColorRect
class_name SlowMotionOverlay

## Fades a desaturation overlay in while the player charges a dash. Fades use real time, unaffected by slow-motion.

@export var shader: Shader = preload("res://shaders/slow_motion.gdshader")
@export_range(0.0, 1.0, 0.05) var max_desaturation := 0.85
@export_range(0.0, 1.0, 0.05) var darken := 0.1
@export_range(0.0, 2.0, 0.01) var fade_in_duration := 0.15
@export_range(0.0, 2.0, 0.01) var fade_out_duration := 0.2

@onready var player: Player = %Player

var _material: ShaderMaterial
var _tween: Tween

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("max_desaturation", max_desaturation)
	_material.set_shader_parameter("darken", darken)
	material = _material
	_set_amount(0.0)
	player.dash.charge_started.connect(_fade_to.bind(1.0, fade_in_duration))
	player.dash.charge_ended.connect(_fade_to.bind(0.0, fade_out_duration))

func _fade_to(target: float, duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_method(_set_amount, _material.get_shader_parameter("amount"), target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_amount(value: float) -> void:
	_material.set_shader_parameter("amount", value)
	# Skip the screen-texture copy entirely while faded out.
	visible = value > 0.0
