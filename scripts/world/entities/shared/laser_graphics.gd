extends Node2D
class_name LaserGraphics

signal fade_finished(target_alpha: float)

@export var pixel_rotate_shader: Shader
@export_range(0.0, 64.0, 1.0) var start_offset := 0.0
@export_range(1.0, 64.0, 1.0) var laser_width := 3.0
@export_range(1.0, 32.0, 1.0) var center_line_thickness := 1.0
@export var center_color := Color(1.0, 0.96, 0.78, 1.0)
@export var edge_color := Color(1.0, 0.28, 0.08, 0.9)
@export_range(0.01, 1.0, 0.01) var fade_duration := 0.12

var _visual: PixelRotatedSprite
var _beam_length := 1.0

func _ready() -> void:
	if not pixel_rotate_shader:
		push_error("%s requires pixel_rotate_shader" % name)
		return
	_visual = PixelRotatedSprite.new()
	_visual.name = "LaserVisual"
	_visual.pixel_shader = pixel_rotate_shader
	_visual.start_offset = start_offset
	_visual.fade_finished.connect(_on_visual_fade_finished)
	add_child(_visual)
	_update_texture()

func set_beam_length(value: float) -> void:
	_beam_length = maxf(1.0, value)
	_update_texture()

func aim_from(origin: Vector2, direction: Vector2) -> void:
	if not is_instance_valid(_visual):
		return
	_visual.global_position = origin
	_visual.point_at(direction.angle() - global_rotation)

func fade_to(target_alpha: float, duration := -1.0) -> void:
	if not is_instance_valid(_visual):
		return
	_visual.fade_duration = fade_duration if duration < 0.0 else maxf(0.01, duration)
	_visual.fade_to(target_alpha)

func _update_texture() -> void:
	if is_instance_valid(_visual):
		_visual.texture = _make_texture()

func _make_texture() -> Texture2D:
	var image_width := maxi(1, ceili(_beam_length - start_offset))
	var image_height := maxi(1, roundi(laser_width))
	var image := Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)
	var center_y := (float(image_height) - 1.0) * 0.5
	var edge_radius := minf(float(image_height) * 0.5, float(image_width) * 0.5)
	var center_radius := minf(maxf(0.5, center_line_thickness * 0.5), edge_radius)
	var capsule_start := edge_radius
	var capsule_end := maxf(capsule_start, float(image_width) - edge_radius)
	for y in range(image_height):
		for x in range(image_width):
			var sample_x := float(x) + 0.5
			var closest_x := clampf(sample_x, capsule_start, capsule_end)
			var sample_y := float(y) + 0.5
			var vertical_distance := sample_y - center_y
			var edge_distance := Vector2(sample_x - closest_x, vertical_distance).length()
			if edge_distance <= edge_radius:
				var center_distance := Vector2(sample_x - clampf(sample_x, capsule_start, capsule_end), vertical_distance).length()
				var pixel_color := center_color if center_distance <= center_radius else edge_color
				image.set_pixel(x, y, pixel_color)
	return ImageTexture.create_from_image(image)

func _on_visual_fade_finished(target_alpha: float) -> void:
	fade_finished.emit(target_alpha)