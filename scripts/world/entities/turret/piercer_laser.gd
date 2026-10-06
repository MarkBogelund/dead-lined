extends Node2D
class_name PiercerLaser

signal visual_finished

@export var pixel_rotate_shader: Shader
@export_range(1.0, 16.0, 1.0) var laser_width := 3.0
@export_range(1.0, 16.0, 1.0) var center_line_thickness := 1.0
@export var center_color := Color(1.0, 0.96, 0.78, 1.0)
@export var edge_color := Color(1.0, 0.28, 0.08, 0.9)
@export_range(0.05, 1.0, 0.01) var fade_out_delay := 0.35
@export_range(0.05, 0.5, 0.01) var laser_fade_duration := 0.18
@export_range(0.01, 1.0, 0.01) var telegraph_alpha := 0.28

const WORLD_COLLISION_MASK := 1
const TARGET_COLLISION_MASK := 42
const WALL_QUERY_DISTANCE := 10000.0

var _visual: PixelRotatedSprite
var _visual_time := -1.0

func _ready() -> void:
	if not pixel_rotate_shader:
		push_error("%s requires pixel_rotate_shader" % name)
		return
	_visual = PixelRotatedSprite.new()
	_visual.name = "LaserVisual"
	_visual.pixel_shader = pixel_rotate_shader
	_visual.start_offset = 0.0
	_visual.fade_duration = laser_fade_duration
	_visual.fade_finished.connect(_on_visual_fade_finished)
	add_child(_visual)

func _on_visual_fade_finished(target_alpha: float) -> void:
	if is_zero_approx(target_alpha):
		visual_finished.emit()

func _process(delta: float) -> void:
	if _visual_time < 0.0:
		return
	_visual_time -= delta
	if _visual_time <= 0.0:
		_visual_time = -1.0
		_visual.fade_to(0.0)

func show_telegraph(origin: Vector2, direction: Vector2, fade_duration: float) -> void:
	var beam_length := _get_clear_length(origin, direction)
	_visual.fade_duration = maxf(0.01, fade_duration)
	_set_visual(origin, direction, beam_length, telegraph_alpha)
	_visual_time = -1.0

func cancel_telegraph() -> void:
	if not is_instance_valid(_visual):
		return
	_visual_time = -1.0
	_visual.fade_duration = laser_fade_duration
	_visual.fade_to(0.0)

func fire(origin: Vector2, direction: Vector2, damage: int, knockback: float, shooter: Node2D) -> void:
	var normalized_direction := direction.normalized()
	var beam_length := _get_clear_length(origin, normalized_direction)
	if beam_length <= 0.0:
		_visual_time = -1.0
		cancel_telegraph()
		visual_finished.emit()
		return
	_visual.fade_duration = laser_fade_duration
	_set_visual(origin, normalized_direction, beam_length, 1.0)
	_visual_time = fade_out_delay
	_damage_targets(origin, normalized_direction, beam_length, damage, knockback, shooter)

func _get_clear_length(origin: Vector2, direction: Vector2) -> float:
	var space_state := get_world_2d().direct_space_state
	var normalized_direction := direction.normalized()
	var perpendicular := direction.orthogonal()
	var edge_offset := maxf(0.5, laser_width * 0.5)
	var clear_length := WALL_QUERY_DISTANCE
	for offset: float in [0.0, -edge_offset, edge_offset]:
		var ray_start := origin + perpendicular * offset
		var query := PhysicsRayQueryParameters2D.create(ray_start, ray_start + normalized_direction * WALL_QUERY_DISTANCE, WORLD_COLLISION_MASK)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit := space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_position: Vector2 = hit["position"]
			var hit_distance: float = (hit_position - origin).dot(normalized_direction)
			clear_length = minf(clear_length, maxf(0.0, hit_distance))
	return clear_length

func _set_visual(origin: Vector2, direction: Vector2, beam_length: float, alpha: float) -> void:
	if not is_instance_valid(_visual) or beam_length <= 0.0:
		cancel_telegraph()
		return
	_visual.global_position = origin
	_visual.texture = _make_texture(beam_length)
	_visual.point_at(direction.angle())
	_visual.fade_to(alpha)

func _make_texture(beam_length: float) -> Texture2D:
	var image_width := maxi(1, ceili(beam_length))
	var image_height := maxi(1, roundi(laser_width))
	var image := Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)
	var center_y := (float(image_height) - 1.0) * 0.5
	var center_half_thickness := maxf(0.5, center_line_thickness * 0.5)
	var corner_radius := minf(float(image_height) * 0.5, float(image_width) * 0.5)
	var capsule_start := corner_radius
	var capsule_end := maxf(capsule_start, float(image_width) - corner_radius)
	for y in range(image_height):
		var distance_from_center := absf(float(y) - center_y)
		var pixel_color := center_color if distance_from_center <= center_half_thickness else edge_color
		for x in range(image_width):
			var sample_x := float(x) + 0.5
			var closest_x := clampf(sample_x, capsule_start, capsule_end)
			var distance_to_capsule := Vector2(sample_x - closest_x, float(y) + 0.5 - center_y).length()
			if distance_to_capsule <= corner_radius:
				image.set_pixel(x, y, pixel_color)
	return ImageTexture.create_from_image(image)

func _damage_targets(origin: Vector2, direction: Vector2, beam_length: float, damage: int, knockback: float, shooter: Node2D) -> void:
	if beam_length <= 0.0:
		return
	var shape := RectangleShape2D.new()
	shape.size = Vector2(beam_length, laser_width)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(direction.angle(), origin + direction * beam_length * 0.5)
	query.collision_mask = TARGET_COLLISION_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [shooter.get_rid()]
	var hit_ids: Dictionary[int, bool] = {}
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 128):
		var target := result.get("collider") as Node2D
		if not target or hit_ids.has(target.get_instance_id()) or not _is_damageable_target(target):
			continue
		hit_ids[target.get_instance_id()] = true
		var target_knockback := knockback if target.is_in_group("enemies") or target.is_in_group("player") else 0.0
		target.was_hit(damage, target_knockback, origin)

func _is_damageable_target(target: Node2D) -> bool:
	if not target.has_method("was_hit"):
		return false
	if target.has_method("is_dead") and target.is_dead():
		return false
	return target.is_in_group("enemies") or target.is_in_group("player") or target.is_in_group("turrets")