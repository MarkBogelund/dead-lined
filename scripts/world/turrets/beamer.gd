extends TurretBase
class_name Beamer

enum State {IDLE, WINDUP, FIRING, COOLDOWN}

@onready var beam_area: Area2D = $Beam/BeamArea
@onready var beam_shape: CollisionShape2D = $Beam/BeamArea/CollisionShape2D
@onready var speed_particles: GPUParticles2D = $Beam/SpeedParticles
@onready var laser_graphics: LaserGraphics = $Beam/LaserGraphics

@export var stats: BeamerStats
## Groups the beam locks onto and damages.
@export var hit_groups: Array[StringName] = [&"player", &"enemies"]

var _damage := 0
var _beam_length := 1.0
var _attack_cooldown := 0.0
var _beam_enabled := false
var _state := State.IDLE
var _state_time := 0.0
var _tracking_time := 0.0
var _sweep_angle := 0.0
var _locked_target: Node2D
var _target_cooldowns: Dictionary[int, float] = {}

func _ready() -> void:
	_initialize()
	animation.configure_animation("windup", 2, false)
	animation.configure_animation("fire", 3, false)
	super._ready()

func _initialize() -> void:
	if not stats:
		push_error("%s requires a BeamerStats resource" % name)
		return
	initialize_base(stats)
	_damage = stats.damage
	_attack_cooldown = stats.attack_cooldown
	beam_shape.shape = RectangleShape2D.new()
	_set_beam_length(stats.attack_range)

func _on_combat_started() -> void:
	_set_beam_enabled(true)

func _on_combat_stopped() -> void:
	_set_beam_enabled(false)
	animation.stop_animation("fire")
	animation.stop_animation("windup")

func _before_death_animation() -> void:
	_on_combat_stopped()

func _set_beam_enabled(value: bool) -> void:
	if _beam_enabled == value:
		return
	_beam_enabled = value
	_locked_target = null
	_target_cooldowns.clear()
	laser_graphics.fade_to(0.0)
	if value:
		_start_windup()
	else:
		_state = State.IDLE

func _start_windup() -> void:
	_state = State.WINDUP
	_state_time = 0.0
	_tracking_time = 0.0
	animation.stop_animation("fire")
	animation.play_animation("windup", -1, animation.get_animation_length("windup") / stats.windup_duration)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _beam_enabled:
		return
	_state_time += delta
	if _state == State.COOLDOWN:
		if _state_time >= _attack_cooldown:
			_start_windup()
		return
	_update_aim(delta)
	_update_beam_transform()
	match _state:
		State.WINDUP:
			if _state_time >= stats.windup_duration:
				_state = State.FIRING
				_state_time = 0.0
				_target_cooldowns.clear()
				laser_graphics.fade_to(1.0)
				animation.play_animation("fire")
		State.FIRING:
			if is_instance_valid(_locked_target):
				_tracking_time += delta
				if _tracking_time >= stats.max_tracking_duration:
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
	animation.stop_animation("fire")

func _set_beam_length(value: float) -> void:
	_beam_length = maxf(1.0, value)
	(beam_shape.shape as RectangleShape2D).size = Vector2(_beam_length, stats.beam_width)
	laser_graphics.set_beam_length(_beam_length)
	_update_beam_transform()

func _update_beam_transform() -> void:
	var direction := Vector2.from_angle(_sweep_angle)
	beam_area.global_rotation = _sweep_angle
	beam_area.global_position = global_position + direction * _beam_length * 0.5
	speed_particles.rotation = _sweep_angle
	laser_graphics.aim_from(global_position, direction)

func _update_aim(delta: float) -> void:
	if is_instance_valid(_locked_target):
		if _can_track_target(_locked_target):
			var target_angle := (_locked_target.global_position - global_position).angle()
			_sweep_angle = rotate_toward(_sweep_angle, target_angle, deg_to_rad(stats.tracking_speed_degrees) * delta)
			return
		_locked_target = null
	_sweep_angle = wrapf(_sweep_angle + deg_to_rad(stats.sweep_speed_degrees) * delta, -PI, PI)

func _damage_overlapped_targets(delta: float) -> void:
	var active_targets: Dictionary[int, bool] = {}
	for body: Node2D in beam_area.get_overlapping_bodies():
		if not HitboxComponent.can_hit(body, hit_groups):
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
		HitboxComponent.apply_hit(body, _damage, stats.knockback, global_position)
		_target_cooldowns[target_id] = stats.damage_interval
	for target_id: int in _target_cooldowns.keys():
		if not active_targets.has(target_id):
			_target_cooldowns.erase(target_id)

func _can_track_target(body: Node2D) -> bool:
	return HitboxComponent.can_hit(body, hit_groups) \
		and global_position.distance_squared_to(body.global_position) <= _beam_length * _beam_length \
		and _has_clear_path(body.global_position) \
		and (beam_area.get_overlapping_bodies().has(body) or _distance_from_beam(body.global_position) <= stats.lock_break_distance)

func _distance_from_beam(target_position: Vector2) -> float:
	var direction := Vector2.from_angle(_sweep_angle)
	var along_beam := clampf((target_position - global_position).dot(direction), 0.0, _beam_length)
	var closest_point := global_position + direction * along_beam
	return maxf(0.0, target_position.distance_to(closest_point) - stats.beam_width * 0.5)

func _has_clear_path(target_position: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func get_attack_cooldown_progress() -> float:
	if _state != State.COOLDOWN or _attack_cooldown <= 0.0:
		return 1.0
	return clampf(_state_time / _attack_cooldown, 0.0, 1.0)

func set_attack_cooldown(value: float) -> void:
	_attack_cooldown = maxf(0.0, value)

func get_damage_value() -> int:
	return _damage

func set_damage(value: int) -> void:
	_damage = maxi(0, value)

func set_attack_range(value: float) -> void:
	_set_beam_length(value)
	range_indicator.initialize(value)
