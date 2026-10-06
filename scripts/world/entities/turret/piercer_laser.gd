extends Node2D
class_name PiercerLaser

signal visual_finished

@onready var laser_graphics: LaserGraphics = $LaserGraphics

@export_range(0.05, 1.0, 0.01) var fade_out_delay := 0.35
@export_range(0.05, 0.5, 0.01) var laser_fade_duration := 0.18
@export_range(0.01, 1.0, 0.01) var telegraph_alpha := 0.28

const WORLD_COLLISION_MASK := 1
const TARGET_COLLISION_MASK := 42
const WALL_QUERY_DISTANCE := 10000.0

var _visual_time := -1.0

func _ready() -> void:
	laser_graphics.fade_finished.connect(_on_visual_fade_finished)

func _on_visual_fade_finished(target_alpha: float) -> void:
	if is_zero_approx(target_alpha):
		visual_finished.emit()

func _process(delta: float) -> void:
	if _visual_time < 0.0:
		return
	_visual_time -= delta
	if _visual_time <= 0.0:
		_visual_time = -1.0
		laser_graphics.fade_to(0.0, laser_fade_duration)

func show_telegraph(origin: Vector2, direction: Vector2, fade_duration: float) -> void:
	var beam_length := _get_clear_length(origin, direction)
	_set_visual(origin, direction, beam_length, telegraph_alpha)
	laser_graphics.fade_to(telegraph_alpha, fade_duration)
	_visual_time = -1.0

func cancel_telegraph() -> void:
	_visual_time = -1.0
	laser_graphics.fade_to(0.0, laser_fade_duration)

func fire(origin: Vector2, direction: Vector2, damage: int, knockback: float, shooter: Node2D) -> void:
	var normalized_direction := direction.normalized()
	var beam_length := _get_clear_length(origin, normalized_direction)
	if beam_length <= 0.0:
		_visual_time = -1.0
		cancel_telegraph()
		visual_finished.emit()
		return
	_set_visual(origin, normalized_direction, beam_length, 1.0)
	laser_graphics.fade_to(1.0, laser_fade_duration)
	_visual_time = fade_out_delay
	_damage_targets(origin, normalized_direction, beam_length, damage, knockback, shooter)

func _get_clear_length(origin: Vector2, direction: Vector2) -> float:
	var space_state := get_world_2d().direct_space_state
	var normalized_direction := direction.normalized()
	var perpendicular := direction.orthogonal()
	var edge_offset := maxf(0.5, laser_graphics.laser_width * 0.5)
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
	if beam_length <= 0.0:
		cancel_telegraph()
		return
	laser_graphics.set_beam_length(beam_length)
	laser_graphics.aim_from(origin, direction)

func _damage_targets(origin: Vector2, direction: Vector2, beam_length: float, damage: int, knockback: float, shooter: Node2D) -> void:
	if beam_length <= 0.0:
		return
	var shape := RectangleShape2D.new()
	shape.size = Vector2(beam_length, laser_graphics.laser_width)
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