extends Node2D
class_name BeamComponent

signal windup_started
signal firing_started
signal overheated

enum State {IDLE, WINDUP, FIRING, COOLDOWN}

@onready var beam_area: Area2D = $BeamArea
@onready var beam_shape: CollisionShape2D = $BeamArea/CollisionShape2D
@onready var speed_particles: GPUParticles2D = $SpeedParticles
@onready var laser_graphics: LaserGraphics = $LaserGraphics

var beam_length := 180.0
var beam_width := 12.0
var damage_interval := 0.3
var windup_duration := 0.55
var lock_break_distance := 5.0
var damage := 4
var knockback := 0.0
var sweep_speed := deg_to_rad(45.0)
var tracking_speed := deg_to_rad(24.0)
var max_tracking_duration := 5.0
var attack_cooldown := 0.15

var _enabled := false
var _state := State.IDLE
var _state_time := 0.0
var _tracking_time := 0.0
var _sweep_angle := 0.0
var _locked_target: Node2D
var _target_cooldowns: Dictionary[int, float] = {}

func _ready() -> void:
	beam_shape.shape = RectangleShape2D.new()
	_update_geometry()

func configure(p_range: float, p_width: float, p_damage_interval: float, p_windup_duration: float, p_lock_break_distance: float, p_damage: int, p_knockback: float, p_sweep_speed_degrees: float, p_tracking_speed_degrees: float, p_max_tracking_duration: float = 5.0, p_attack_cooldown: float = 0.15) -> void:
	beam_length = maxf(1.0, p_range)
	beam_width = maxf(1.0, p_width)
	damage_interval = maxf(0.05, p_damage_interval)
	windup_duration = maxf(0.05, p_windup_duration)
	lock_break_distance = maxf(0.0, p_lock_break_distance)
	damage = maxi(0, p_damage)
	knockback = maxf(0.0, p_knockback)
	sweep_speed = deg_to_rad(p_sweep_speed_degrees)
	tracking_speed = deg_to_rad(p_tracking_speed_degrees)
	max_tracking_duration = maxf(0.05, p_max_tracking_duration)
	attack_cooldown = maxf(0.0, p_attack_cooldown)
	_update_geometry()

func set_enabled(value: bool) -> void:
	if _enabled == value:
		return
	_enabled = value
	_state_time = 0.0
	_tracking_time = 0.0
	_locked_target = null
	_target_cooldowns.clear()
	if not value:
		_state = State.IDLE
		laser_graphics.fade_to(0.0)
		return
	_state = State.WINDUP
	laser_graphics.fade_to(0.0)
	windup_started.emit()

func set_range(value: float) -> void:
	beam_length = maxf(1.0, value)
	_update_geometry()

func set_damage(value: int) -> void:
	damage = maxi(0, value)

func get_cooldown_progress() -> float:
	if _state != State.COOLDOWN or attack_cooldown <= 0.0:
		return 1.0
	return clampf(_state_time / attack_cooldown, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	_state_time += delta
	if _state == State.COOLDOWN:
		if _state_time >= attack_cooldown:
			_state = State.WINDUP
			_state_time = 0.0
			_tracking_time = 0.0
			windup_started.emit()
		return
	_update_aim(delta)
	_update_sweep_transforms()
	match _state:
		State.WINDUP:
			if _state_time >= windup_duration:
				_state = State.FIRING
				_state_time = 0.0
				_target_cooldowns.clear()
				laser_graphics.fade_to(1.0)
				firing_started.emit()
		State.FIRING:
			if is_instance_valid(_locked_target):
				_tracking_time += delta
				if _tracking_time >= max_tracking_duration:
					_overheat()
					return
			_damage_overlapped_targets(delta)

func _overheat() -> void:
	_state = State.COOLDOWN
	_state_time = 0.0
	_locked_target = null
	_target_cooldowns.clear()
	laser_graphics.fade_to(0.0)
	speed_particles.emitting = false
	overheated.emit()

func _update_geometry() -> void:
	if not is_node_ready():
		return
	var shape := beam_shape.shape as RectangleShape2D
	shape.size = Vector2(beam_length, beam_width)
	laser_graphics.set_beam_length(beam_length)
	_update_sweep_transforms()

func _update_sweep_transforms() -> void:
	beam_area.global_rotation = global_rotation + _sweep_angle
	beam_area.global_position = global_position + Vector2(beam_length * 0.5, 0.0).rotated(global_rotation + _sweep_angle)
	speed_particles.position = Vector2.ZERO
	speed_particles.rotation = _sweep_angle
	laser_graphics.aim_from(global_position, Vector2.from_angle(global_rotation + _sweep_angle))

func _update_aim(delta: float) -> void:
	if is_instance_valid(_locked_target):
		if _can_track_target(_locked_target):
			var target_angle := (_locked_target.global_position - global_position).angle()
			_sweep_angle = rotate_toward(_sweep_angle, target_angle, tracking_speed * delta)
			return
		_locked_target = null
	_sweep_angle = wrapf(_sweep_angle + sweep_speed * delta, -PI, PI)

func _damage_overlapped_targets(delta: float) -> void:
	var active_targets: Dictionary[int, bool] = {}
	for body: Node2D in beam_area.get_overlapping_bodies():
		if not _is_damageable(body):
			continue
		var target_id := body.get_instance_id()
		active_targets[target_id] = true
		var time_left: float = maxf(0.0, _target_cooldowns.get(target_id, 0.0) - delta)
		if time_left > 0.0:
			_target_cooldowns[target_id] = time_left
			continue
		if not _has_clear_path(body.global_position):
			_target_cooldowns.erase(target_id)
			continue
		if not is_instance_valid(_locked_target):
			_locked_target = body
		var target_knockback := knockback if body.is_in_group("enemies") else 0.0
		body.was_hit(damage, target_knockback, global_position)
		_target_cooldowns[target_id] = damage_interval
	for target_id: int in _target_cooldowns.keys():
		if not active_targets.has(target_id):
			_target_cooldowns.erase(target_id)

func _is_damageable(body: Node2D) -> bool:
	if not body.has_method("was_hit"):
		return false
	if body.has_method("is_dead") and body.is_dead():
		return false
	return body.is_in_group("player") or body.is_in_group("enemies")

func _can_track_target(body: Node2D) -> bool:
	return _is_damageable(body) \
		and global_position.distance_squared_to(body.global_position) <= beam_length * beam_length \
		and _has_clear_path(body.global_position) \
		and (beam_area.get_overlapping_bodies().has(body) or _distance_from_beam(body.global_position) <= lock_break_distance)

func _distance_from_beam(target_position: Vector2) -> float:
	var beam_direction := Vector2.from_angle(global_rotation + _sweep_angle)
	var along_beam := clampf((target_position - global_position).dot(beam_direction), 0.0, beam_length)
	var closest_point := global_position + beam_direction * along_beam
	return maxf(0.0, target_position.distance_to(closest_point) - beam_width * 0.5)

func _has_clear_path(target_position: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target_position, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()