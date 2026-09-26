extends Node2D
class_name DashDirectionIndicator

## Sprite pointing where the dash will go, shown only while charging. Rotation is done by pixel_rotate.gdshader
## on a world-aligned grid, so the art keeps crisp, undeformed pixels at any angle.

const SHADER := preload("res://shaders/pixel_rotate.gdshader")

## Drawn pointing right; its left edge sits start_offset pixels from the player.
@export var texture: Texture2D = preload("res://assets/sprites/player/dash_direction.png")
@export_range(0.0, 64.0, 1.0) var start_offset := 8.0
@export var color := Color(1.0, 1.0, 1.0, 0.85)
@export_range(0.0, 1.0, 0.01) var fade_duration := 0.12

var _material: ShaderMaterial
var _fade_tween: Tween
var _target_alpha := 0.0

func _ready() -> void:
	# Positioned manually on whole pixels so the rotation grid never shifts by sub-pixel player movement.
	top_level = true
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material = _material
	modulate.a = 0.0
	hide()

func point_in(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	global_position = (get_parent() as Node2D).global_position.round()
	_material.set_shader_parameter("angle", direction.angle())
	_fade_to(1.0)
	queue_redraw()

func fade_out() -> void:
	_fade_to(0.0)

func _fade_to(target_alpha: float) -> void:
	if is_equal_approx(_target_alpha, target_alpha):
		return
	_target_alpha = target_alpha
	if _fade_tween:
		_fade_tween.kill()
	visible = true
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", target_alpha, fade_duration)
	if is_zero_approx(target_alpha):
		_fade_tween.finished.connect(hide)

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
