extends Node2D
class_name MagneticFieldComponent

signal windup_started
signal pull_started
signal pull_finished

enum State {READY, WINDUP, PULLING, COOLDOWN}

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

@export_group("Presentation")
@export var windup_color := Color(0.2, 0.95, 0.85, 0.22)
@export var pull_color := Color(0.35, 1.0, 0.9, 0.55)
@export_range(1.0, 8.0, 1.0) var line_width := 2.0

var max_range := 100.0
var cooldown := 3.0
var windup_duration := 0.6
var pull_duration := 1.0
var pull_speed := 110.0
var enemy_pull_multiplier := 1.0
var player_pull_multiplier := 0.75
var inner_dead_zone := 12.0
var edge_pull_fraction := 0.35
var damage := 2
var affect_player := true

var _enabled := false
var _state := State.READY
var _state_time := 0.0
var _source_id: int
var _affected: Dictionary[int, Node2D] = {}

func _ready() -> void:
	_source_id = get_instance_id()
	detection_shape.shape = detection_shape.shape.duplicate()
	_apply_radius()

func configure(stats: AttractorStats) -> void:
	max_range = maxf(0.0, stats.attack_range)
	cooldown = maxf(0.0, stats.attack_cooldown)
	windup_duration = maxf(0.05, stats.windup_duration)
	pull_duration = maxf(0.05, stats.pull_duration)
	pull_speed = maxf(0.0, stats.pull_speed)
	enemy_pull_multiplier = maxf(0.0, stats.enemy_pull_multiplier)
	player_pull_multiplier = maxf(0.0, stats.player_pull_multiplier)
	inner_dead_zone = clampf(stats.inner_dead_zone, 0.0, max_range)
	edge_pull_fraction = clampf(stats.edge_pull_fraction, 0.0, 1.0)
	damage = maxi(0, stats.damage)
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
	var cycle_duration := pull_duration + cooldown
	if cycle_duration <= 0.0:
		return 1.0
	match _state:
		State.PULLING:
			return clampf(_state_time / cycle_duration, 0.0, 1.0)
		State.COOLDOWN:
			return clampf((pull_duration + _state_time) / cycle_duration, 0.0, 1.0)
		_:
			return 1.0

func _apply_radius() -> void:
	var circle := detection_shape.shape as CircleShape2D
	if circle:
		circle.radius = max_range
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
		State.PULLING:
			_state_time += delta
			_apply_pull()
			if _state_time >= pull_duration:
				_clear_affected()
				_state = State.COOLDOWN
				_state_time = 0.0
				pull_finished.emit()
		State.COOLDOWN:
			_state_time += delta
			if _state_time >= cooldown:
				_state = State.READY
				_state_time = 0.0
	queue_redraw()

func execute_pull() -> void:
	if not _enabled or _state != State.WINDUP:
		return
	_state = State.PULLING
	_state_time = 0.0
	_damage_targets()
	pull_started.emit()

func cancel_windup() -> void:
	if _state != State.WINDUP:
		return
	_state = State.READY
	_state_time = 0.0
	queue_redraw()

func _has_target() -> bool:
	for body: Node2D in detection_area.get_overlapping_bodies():
		if _is_target(body):
			return true
	return false

func _is_target(body: Node2D) -> bool:
	if not body.has_method("set_external_velocity") or not body.has_method("clear_external_velocity"):
		return false
	if body.has_method("is_dead") and body.is_dead():
		return false
	if body.is_in_group("player"):
		return affect_player
	return body.is_in_group("enemies")

func _apply_pull() -> void:
	var still_affected: Dictionary[int, bool] = {}
	for body: Node2D in detection_area.get_overlapping_bodies():
		if not _is_target(body):
			continue
		var body_id := body.get_instance_id()
		still_affected[body_id] = true
		_affected[body_id] = body
		var pull_offset := global_position - body.global_position
		if not pull_offset.is_finite():
			body.call(&"clear_external_velocity", _source_id)
			continue
		var distance := pull_offset.length()
		if distance <= inner_dead_zone:
			body.call(&"clear_external_velocity", _source_id)
			continue
		var pull_span := max_range - inner_dead_zone
		var distance_ratio := clampf((distance - inner_dead_zone) / pull_span, 0.0, 1.0) \
			if pull_span > 0.0001 else 0.0
		var multiplier := player_pull_multiplier if body.is_in_group("player") else enemy_pull_multiplier
		var strength := pull_speed * multiplier * lerpf(1.0, edge_pull_fraction, distance_ratio)
		body.call(&"set_external_velocity", _source_id, pull_offset / distance * strength)
	for body_id: int in _affected.keys():
		if still_affected.has(body_id):
			continue
		_clear_body(body_id)

func _damage_targets() -> void:
	if damage <= 0:
		return
	for body: Node2D in detection_area.get_overlapping_bodies():
		if _is_target(body) and body.has_method("was_hit"):
			body.call(&"was_hit", damage, 0.0, global_position)

func _clear_body(body_id: int) -> void:
	var body := _affected.get(body_id) as Node2D
	if is_instance_valid(body):
		body.call(&"clear_external_velocity", _source_id)
	_affected.erase(body_id)

func _clear_affected() -> void:
	for body_id: int in _affected.keys():
		_clear_body(body_id)

func _reset() -> void:
	_clear_affected()
	_state = State.READY
	_state_time = 0.0
	queue_redraw()

func _exit_tree() -> void:
	_clear_affected()

func _draw() -> void:
	var ring_width := maxf(1.0, max_range - inner_dead_zone)
	var ring_radius := (max_range + inner_dead_zone) * 0.5
	if _state == State.WINDUP:
		var progress := minf(_state_time / windup_duration, 1.0)
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 96, Color(windup_color, windup_color.a * progress), ring_width)
		draw_arc(Vector2.ZERO, lerpf(max_range, inner_dead_zone, progress), 0.0, TAU, 96, pull_color, line_width)
	elif _state == State.PULLING:
		var phase := fmod(_state_time * 2.5, 1.0)
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 96, Color(pull_color, pull_color.a * 0.16), ring_width)
		for offset: float in [0.0, 0.33, 0.66]:
			var radius := lerpf(max_range, inner_dead_zone, fmod(phase + offset, 1.0))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, pull_color, line_width)