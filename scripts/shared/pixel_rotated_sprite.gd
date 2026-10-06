extends Node2D
class_name PixelRotatedSprite

signal fade_finished(target_alpha: float)

## Sprite rotated by pixel_rotate.gdshader on a world-aligned grid, so the art keeps crisp, undeformed
## pixels at any angle. Starts hidden; use fade_to() to show it.

@export var pixel_shader: Shader

## Drawn pointing right; its left edge sits start_offset pixels from this node's origin.
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export_range(0.0, 64.0, 1.0) var start_offset := 0.0:
	set(value):
		start_offset = value
		queue_redraw()
@export var color := Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		color = value
		queue_redraw()
@export_range(0.0, 1.0, 0.01) var fade_duration := 0.12

var _material: ShaderMaterial
var _fade_tween: Tween
var _target_alpha := 0.0

func _ready() -> void:
	if not pixel_shader:
		push_error("%s requires pixel_shader" % name)
		return
	_material = ShaderMaterial.new()
	_material.shader = pixel_shader
	material = _material
	modulate.a = 0.0
	hide()

func point_at(angle: float) -> void:
	_material.set_shader_parameter("angle", angle)
	queue_redraw()

func fade_to(target_alpha: float) -> void:
	if is_equal_approx(_target_alpha, target_alpha):
		return
	_target_alpha = target_alpha
	if _fade_tween:
		_fade_tween.kill()
	visible = true
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", target_alpha, fade_duration)
	_fade_tween.finished.connect(_on_fade_finished.bind(target_alpha))

func _on_fade_finished(target_alpha: float) -> void:
	if is_zero_approx(target_alpha):
		hide()
	fade_finished.emit(target_alpha)

func _draw() -> void:
	if not texture:
		return
	var sprite_size := texture.get_size()
	# Big enough to hold the sprite at any angle around the pivot.
	var half := ceilf(start_offset + sprite_size.length())
	var canvas := Rect2(-Vector2.ONE * half, Vector2.ONE * half * 2.0)
	_material.set_shader_parameter("canvas_size", canvas.size)
	_material.set_shader_parameter("sprite_size", sprite_size)
	_material.set_shader_parameter("start_offset", start_offset)
	draw_texture_rect(texture, canvas, false, color)
