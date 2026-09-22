extends Node2D
class_name ShockwaveComponent

signal windup_started
signal shockwave_started
signal shockwave_finished

enum State {READY, WINDUP, EXPANDING, COOLDOWN}

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var contact_radius := 48.0
var shockwave_radius := 120.0
var ring_thickness := 8.0
var cooldown := 2.5
var expansion_duration := 0.6
var damage := 20

var _enabled := false
var _state := State.READY
var _state_time := 0.0
var _wave_radius := 0.0
var _previous_wave_radius := 0.0
var _hit_targets: Dictionary[int, bool] = {}

func configure(p_contact_radius: float, p_shockwave_radius: float, p_ring_thickness: float, p_cooldown: float, p_expansion_duration: float, p_damage: int) -> void:
	contact_radius = maxf(0.0, p_contact_radius)
	shockwave_radius = maxf(contact_radius, p_shockwave_radius)
	ring_thickness = maxf(1.0, p_ring_thickness)
	cooldown = maxf(0.0, p_cooldown)
	expansion_duration = maxf(0.01, p_expansion_duration)
	damage = maxi(0, p_damage)
	var circle := detection_shape.shape as CircleShape2D
	if circle:
		circle.radius = shockwave_radius + ring_thickness * 0.5
	queue_redraw()

func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_reset()

func apply_damage_upgrade(amount: int) -> void:
	damage += amount

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	match _state:
		State.READY:
			if _has_trigger_target():
				_enter_windup()
		State.EXPANDING:
			_update_expansion(delta)
		State.COOLDOWN:
			_state_time += delta
			if _state_time >= cooldown:
				_state = State.READY
				_state_time = 0.0
	queue_redraw()

func _has_trigger_target() -> bool:
	for body: Node2D in detection_area.get_overlapping_bodies():
		if _is_damageable(body) and global_position.distance_to(body.global_position) <= contact_radius:
			return true
	return false

func _enter_windup() -> void:
	_state = State.WINDUP
	_state_time = 0.0
	windup_started.emit()

func execute_shockwave() -> void:
	if not _enabled or _state != State.WINDUP:
		return
	_state = State.EXPANDING
	_state_time = 0.0
	_wave_radius = 0.0
	_previous_wave_radius = 0.0
	_hit_targets.clear()
	shockwave_started.emit()

func _update_expansion(delta: float) -> void:
	_state_time += delta
	_previous_wave_radius = _wave_radius
	_wave_radius = shockwave_radius * minf(_state_time / expansion_duration, 1.0)
	_damage_swept_ring()
	if _state_time >= expansion_duration:
		_state = State.COOLDOWN
		_state_time = 0.0
		shockwave_finished.emit()

func _damage_swept_ring() -> void:
	var inner_radius := maxf(0.0, _previous_wave_radius - ring_thickness * 0.5)
	var outer_radius := _wave_radius + ring_thickness * 0.5
	for body: Node2D in detection_area.get_overlapping_bodies():
		if not _is_damageable(body):
			continue
		var target_id := body.get_instance_id()
		if _hit_targets.has(target_id):
			continue
		var distance := global_position.distance_to(body.global_position)
		if distance >= inner_radius and distance <= outer_radius:
			_hit_targets[target_id] = true
			body.was_hit(damage, 0.0, global_position)

func _is_damageable(body: Node2D) -> bool:
	if not body.has_method("was_hit"):
		return false
	if body.has_method("is_dead") and body.is_dead():
		return false
	return body.is_in_group("player") or body.is_in_group("enemies")

func _reset() -> void:
	_state = State.READY
	_state_time = 0.0
	_wave_radius = 0.0
	_previous_wave_radius = 0.0
	_hit_targets.clear()
	queue_redraw()

func _draw() -> void:
	if _state == State.EXPANDING:
		draw_arc(Vector2.ZERO, _wave_radius, 0.0, TAU, 96, Color(0.3, 0.9, 1.0, 0.9), ring_thickness)