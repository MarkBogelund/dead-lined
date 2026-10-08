extends EnemyBase
class_name Kamikazer

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var charge_particles: GPUParticles2D = $ChargeParticles
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")

@export var stats: KamikazerStats

enum State {SEEK, CHARGE, DECELERATE, COOLDOWN}

var _speed := 34.0
var _charge_speed := 110.0
var _explosion_screen_shake_intensity := 0.35

var _default_avoidance_mask := 1
var _exploding := false

var _state := State.SEEK
var _charge_direction := Vector2.ZERO
var _current_velocity := Vector2.ZERO
var _cooldown_timer := 0.0

var _charge_acceleration := 150.0
var _charge_deceleration := 200.0
var _charge_stop_threshold := 5.0
var _collision_cooldown_duration := 1.0

func _ready() -> void:
	_initialize()
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("charge", 0, false)
	hitbox.hit_target.connect(_on_hit_target)

func _initialize() -> void:
	if not stats:
		push_error("%s requires a KamikazerStats resource" % name)
		return
	_initialize_base(stats)
	targeting.configure(stats.targeting)
	hitbox.initialize(stats.damage, stats.knockback)
	_speed = stats.move_speed
	_charge_speed = stats.charge_speed
	_explosion_screen_shake_intensity = stats.explosion_screen_shake
	_charge_acceleration = stats.charge_acceleration
	_charge_deceleration = stats.charge_deceleration
	_charge_stop_threshold = stats.charge_stop_speed
	_collision_cooldown_duration = stats.collision_stun_duration
	_default_avoidance_mask = navigation.avoidance_mask

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead() or _exploding:
		velocity = Vector2.ZERO
		charge_particles.emitting = false
	else:
		var target := targeting.get_best_target(global_position)
		if target:
			_face_target(animated_sprite, target.global_position)
			_update_state(target, delta)
			var is_charging_visual := _state == State.CHARGE
			animation.play_animation("charge" if is_charging_visual else "idle")
			charge_particles.emitting = is_charging_visual
		else:
			_reset_to_seek()
			velocity = Vector2.ZERO
			charge_particles.emitting = false

	knockback.process(delta)
	_apply_environment_velocity()
	move_and_slide()

	if _state == State.CHARGE and get_slide_collision_count() > 0:
		if velocity.length() <= _charge_stop_threshold:
			_begin_cooldown()
		else:
			## Glancing/sliding hit still has momentum along the wall; resume steering instead of freezing.
			_current_velocity = velocity
			_reset_to_seek()

func _update_state(target: Node2D, delta: float) -> void:
	match _state:
		State.SEEK:
			if line_of_sight.can_see(global_position, target.global_position):
				_start_charge(target.global_position)
				navigation.avoidance_mask = 0
				velocity = _steer(_charge_direction, _charge_speed, delta)
			else:
				navigation.avoidance_mask = _default_avoidance_mask
				velocity = _steer(_seek_direction(target.global_position), _speed, delta)
		State.CHARGE:
			navigation.avoidance_mask = 0
			if not line_of_sight.can_see(global_position, target.global_position) or _has_passed_target(target.global_position):
				_begin_decelerate()
			velocity = _steer(_charge_direction, _charge_speed, delta)
		State.DECELERATE:
			navigation.avoidance_mask = _default_avoidance_mask
			velocity = _steer(Vector2.ZERO, 0.0, delta)
			if _current_velocity.length() <= _charge_stop_threshold:
				_reset_to_seek()
		State.COOLDOWN:
			navigation.avoidance_mask = _default_avoidance_mask
			_current_velocity = Vector2.ZERO
			velocity = Vector2.ZERO
			_cooldown_timer -= delta
			if _cooldown_timer <= 0.0:
				_state = State.SEEK

func _seek_direction(target_pos: Vector2) -> Vector2:
	var nav_velocity := navigation.get_safe_velocity(target_pos, _speed)
	return nav_velocity.normalized() if nav_velocity.length() > 0.01 else Vector2.ZERO

## Accelerates/decelerates _current_velocity toward target_speed along desired_direction.
func _steer(desired_direction: Vector2, target_speed: float, delta: float) -> Vector2:
	if desired_direction == Vector2.ZERO:
		_current_velocity = _current_velocity.move_toward(Vector2.ZERO, _charge_deceleration * delta)
		return _current_velocity

	var current_speed := _current_velocity.length()
	var rate := _charge_acceleration if current_speed < target_speed else _charge_deceleration
	var new_speed := move_toward(current_speed, target_speed, rate * delta)
	_current_velocity = desired_direction * new_speed
	return _current_velocity

## True once the player has crossed behind us along the frozen charge direction.
func _has_passed_target(target_position: Vector2) -> bool:
	return _charge_direction.dot(target_position - global_position) <= 0.0

func _begin_decelerate() -> void:
	_state = State.DECELERATE

func _begin_cooldown() -> void:
	_state = State.COOLDOWN
	_cooldown_timer = _collision_cooldown_duration
	_current_velocity = Vector2.ZERO
	navigation.avoidance_mask = _default_avoidance_mask

func _reset_to_seek() -> void:
	_state = State.SEEK
	navigation.avoidance_mask = _default_avoidance_mask

func _start_charge(target_position: Vector2) -> void:
	var dir := (target_position - global_position).normalized()
	if dir.length_squared() <= 0.0:
		return
	_charge_direction = dir
	_state = State.CHARGE

func _on_hit_target(target: Node) -> void:
	if _exploding or is_dead() or not target:
		return
	if not target.is_in_group("player") and not target.is_in_group("turrets"):
		return
	_trigger_explosion(target.global_position)

func _trigger_explosion(from_position: Vector2) -> void:
	_exploding = true
	_reset_to_seek()
	if camera_shake_manager:
		camera_shake_manager.shake_screen(_explosion_screen_shake_intensity, 0.25)
	if hit_particles:
		hit_particles.restart()
	health.take_damage(health.get_current_health())
	_handle_death(from_position, 0.0)

func buff_damage(multiplier: float) -> void:
	hitbox.damage = int(hitbox.damage * multiplier)
	hitbox.knockback *= multiplier
