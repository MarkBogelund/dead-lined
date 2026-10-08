extends Node2D
class_name RadialFieldComponent

signal windup_started
signal field_started
signal field_finished

enum State {READY, WINDUP, ACTIVE, COOLDOWN}

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

@export_group("Presentation")
@export var windup_color := Color(0.2, 0.95, 0.85, 0.22)
@export var active_color := Color(0.35, 1.0, 0.9, 0.55)
@export_range(1.0, 8.0, 1.0) var line_width := 2.0

var max_range := 100.0
var cooldown := 3.0
var windup_duration := 0.6
var active_duration := 1.0
var force_speed := 110.0
var enemy_force_multiplier := 1.0
var player_force_multiplier := 0.75
var inner_dead_zone := 12.0
var edge_force_fraction := 0.35
var damage := 0
var affects_projectiles := false
var pushes_outward := false

var _enabled := false
var _state := State.READY
var _state_time := 0.0
var _source_id: int
var _affected_bodies: Dictionary[int, Node2D] = {}
var _deflected_projectiles: Dictionary[int, bool] = {}

const BODY_COLLISION_MASK := 10
const PROJECTILE_COLLISION_MASK := 20
const FIELD_RING_SEGMENTS := 96

func _ready() -> void:
	_source_id = get_instance_id()
	detection_shape.shape = detection_shape.shape.duplicate()
	_apply_radius()

func configure(p_max_range: float, p_cooldown: float, p_windup_duration: float, p_active_duration: float, p_force_speed: float, p_enemy_multiplier: float, p_player_multiplier: float, p_inner_dead_zone: float, p_edge_force_fraction: float, p_damage: int, p_pushes_outward: bool, p_affects_projectiles: bool) -> void:
	max_range = maxf(0.0, p_max_range)
	cooldown = maxf(0.0, p_cooldown)
	windup_duration = maxf(0.05, p_windup_duration)
	active_duration = maxf(0.05, p_active_duration)
	force_speed = maxf(0.0, p_force_speed)
	enemy_force_multiplier = maxf(0.0, p_enemy_multiplier)
	player_force_multiplier = maxf(0.0, p_player_multiplier)
	inner_dead_zone = clampf(p_inner_dead_zone, 0.0, max_range)
	edge_force_fraction = clampf(p_edge_force_fraction, 0.0, 1.0)
	damage = maxi(0, p_damage)
	pushes_outward = p_pushes_outward
	affects_projectiles = p_affects_projectiles
	_apply_radius()

func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_reset()

func set_max_range(value: float) -> void:
	max_range = maxf(0.0, value)
	inner_dead_zone = minf(inner_dead_zone, max_range)
	_apply_radius()

func get_cooldown_progress() -> float:
	var cycle_duration := active_duration + cooldown
	if cycle_duration <= 0.0:
		return 1.0
	match _state:
		State.ACTIVE:
			return clampf(_state_time / cycle_duration, 0.0, 1.0)
		State.COOLDOWN:
			return clampf((active_duration + _state_time) / cycle_duration, 0.0, 1.0)
		_:
			return 1.0

func _apply_radius() -> void:
	var circle := detection_shape.shape as CircleShape2D
	if circle:
		circle.radius = max_range
	detection_area.collision_mask = BODY_COLLISION_MASK | (PROJECTILE_COLLISION_MASK if affects_projectiles else 0)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	match _state:
		State.READY:
			if _has_target():
				_state = State.WINDUP
				_state_time = 0.0
				windup_started.emit()
		State.WINDUP:
			_state_time += delta
		State.ACTIVE:
			_state_time += delta
			_apply_force_to_bodies()
			_deflect_projectiles()
			if _state_time >= active_duration:
				_clear_affected_bodies()
				_state = State.COOLDOWN
				_state_time = 0.0
				field_finished.emit()
		State.COOLDOWN:
			_state_time += delta
			if _state_time >= cooldown:
				_state = State.READY
				_state_time = 0.0
	queue_redraw()

func activate_field() -> void:
	if not _enabled or _state != State.WINDUP:
		return
	_state = State.ACTIVE
	_state_time = 0.0
	_deflected_projectiles.clear()
	_apply_damage()
	field_started.emit()

func cancel_windup() -> void:
	if _state != State.WINDUP:
		return
	_state = State.READY
	_state_time = 0.0
	queue_redraw()

func _has_target() -> bool:
	for body: Node2D in detection_area.get_overlapping_bodies():
		if _is_force_target(body):
			return true
	return affects_projectiles and _has_overlapping_projectile()

func _is_force_target(body: Node2D) -> bool:
	return body.has_method("set_external_velocity") \
		and body.has_method("clear_external_velocity") \
		and not (body.has_method("is_dead") and body.is_dead()) \
		and (body.is_in_group("player") or body.is_in_group("enemies"))

func _has_overlapping_projectile() -> bool:
	for area: Area2D in detection_area.get_overlapping_areas():
		var projectile := area.get_parent() as Node2D
		if projectile and projectile.is_in_group("projectiles") and projectile.has_method("deflect_away_from"):
			return true
	return false

func _apply_force_to_bodies() -> void:
	var overlapping_body_ids: Dictionary[int, bool] = {}
	for body: Node2D in detection_area.get_overlapping_bodies():
		if not _is_force_target(body):
			continue
		var body_id := body.get_instance_id()
		overlapping_body_ids[body_id] = true
		_affected_bodies[body_id] = body
		var radial_offset := body.global_position - global_position
		var distance := radial_offset.length()
		if not radial_offset.is_finite() or distance <= inner_dead_zone:
			body.call(&"clear_external_velocity", _source_id)
			continue
		var force_span := max_range - inner_dead_zone
		var distance_ratio := clampf((distance - inner_dead_zone) / force_span, 0.0, 1.0) \
			if force_span > 0.0001 else 0.0
		var target_multiplier := player_force_multiplier if body.is_in_group("player") else enemy_force_multiplier
		var strength := force_speed * target_multiplier * lerpf(1.0, edge_force_fraction, distance_ratio)
		var force_direction := radial_offset / distance
		if not pushes_outward:
			force_direction = - force_direction
		body.call(&"set_external_velocity", _source_id, force_direction * strength)
	for body_id: int in _affected_bodies.keys():
		if not overlapping_body_ids.has(body_id):
			_clear_body(body_id)

func _deflect_projectiles() -> void:
	if not affects_projectiles:
		return
	for area: Area2D in detection_area.get_overlapping_areas():
		var projectile := area.get_parent() as Node2D
		if not projectile or not projectile.is_in_group("projectiles"):
			continue
		var projectile_id := projectile.get_instance_id()
		if _deflected_projectiles.has(projectile_id) or not projectile.has_method("deflect_away_from"):
			continue
		if projectile.call(&"deflect_away_from", global_position):
			_deflected_projectiles[projectile_id] = true

func _apply_damage() -> void:
	if damage <= 0:
		return
	for body: Node2D in detection_area.get_overlapping_bodies():
		if _is_force_target(body) and body.has_method("was_hit"):
			body.call(&"was_hit", damage, 0.0, global_position)

func _clear_body(body_id: int) -> void:
	var body := _affected_bodies.get(body_id) as Node2D
	if is_instance_valid(body):
		body.call(&"clear_external_velocity", _source_id)
	_affected_bodies.erase(body_id)

func _clear_affected_bodies() -> void:
	for body_id: int in _affected_bodies.keys():
		_clear_body(body_id)

func _reset() -> void:
	_clear_affected_bodies()
	_deflected_projectiles.clear()
	_state = State.READY
	_state_time = 0.0
	queue_redraw()

func _exit_tree() -> void:
	_clear_affected_bodies()

func _draw() -> void:
	var field_width := maxf(1.0, max_range - inner_dead_zone)
	var field_radius := (max_range + inner_dead_zone) * 0.5
	if _state == State.WINDUP:
		var progress := minf(_state_time / windup_duration, 1.0)
		var windup_radius := lerpf(max_range, inner_dead_zone, progress) if not pushes_outward else lerpf(inner_dead_zone, max_range, progress)
		var telegraph_color := windup_color
		telegraph_color.a *= progress
		_draw_annulus(field_radius, field_width, telegraph_color)
		_draw_annulus(windup_radius, line_width, active_color)
	elif _state == State.ACTIVE:
		var phase := fmod(_state_time * 2.5, 1.0)
		_draw_annulus(field_radius, field_width, Color(active_color, active_color.a * 0.16))
		for offset: float in [0.0, 0.33, 0.66]:
			var wave_progress := fmod(phase + offset, 1.0)
			var radius := lerpf(max_range, inner_dead_zone, wave_progress) if not pushes_outward else lerpf(inner_dead_zone, max_range, wave_progress)
			_draw_annulus(radius, line_width, active_color)

func _draw_annulus(radius: float, thickness: float, color: Color) -> void:
	var inner_radius := maxf(0.0, radius - thickness * 0.5)
	var outer_radius := radius + thickness * 0.5
	for segment in range(FIELD_RING_SEGMENTS):
		var next_segment := (segment + 1) % FIELD_RING_SEGMENTS
		var start_angle := TAU * float(segment) / FIELD_RING_SEGMENTS
		var end_angle := TAU * float(next_segment) / FIELD_RING_SEGMENTS
		var outer_start := Vector2.from_angle(start_angle) * outer_radius
		var outer_end := Vector2.from_angle(end_angle) * outer_radius
		var inner_end := Vector2.from_angle(end_angle) * inner_radius
		var inner_start := Vector2.from_angle(start_angle) * inner_radius
		draw_colored_polygon(PackedVector2Array([outer_start, outer_end, inner_end, inner_start]), color)