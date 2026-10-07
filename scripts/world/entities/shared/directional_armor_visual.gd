extends Sprite2D
class_name DirectionalArmorVisual

@export var armored_color := Color.WHITE
@export var stress_color := Color(1.0, 0.15, 0.1, 1.0)
@export var broken_color := Color(1.0, 0.25, 0.15, 0.4)
@export_range(0.01, 1.0, 0.01) var hit_flash_duration := 0.12

var _stress := 0.0
var _broken := false
var _hit_flash_tween: Tween
var _shader_material: ShaderMaterial

func _ready() -> void:
	_shader_material = material as ShaderMaterial
	assert(_shader_material, "DirectionalArmorVisual requires its own hit-flash ShaderMaterial")
	_update_color()

func flash_hit() -> void:
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	_shader_material.set_shader_parameter("flash_amount", 1.0)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(_shader_material, "shader_parameter/flash_amount", 0.0, hit_flash_duration)

func set_facing(angle: float) -> void:
	global_rotation = angle

func set_stress(progress: float) -> void:
	_stress = clampf(progress, 0.0, 1.0)
	_update_color()

func set_broken(value: bool) -> void:
	_broken = value
	_update_color()

func _update_color() -> void:
	modulate = broken_color if _broken else armored_color.lerp(stress_color, _stress)

func _exit_tree() -> void:
	if _hit_flash_tween:
		_hit_flash_tween.kill()