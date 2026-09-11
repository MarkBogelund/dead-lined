extends EnemyBase
class_name Kamikazer

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")

@export var stats: KamikazerStats

var _speed := 34.0
var _charge_speed := 110.0
var _explosion_screen_shake_intensity := 0.35

var _default_avoidance_mask := 1
var _charging := false
var _exploding := false
var _charge_direction := Vector2.ZERO

var _charge_timer := 0.0
var _stuck_timer := 0.0
var _stuck_check_position := Vector2.ZERO
var _max_charge_duration := 1.5 ## Safety timeout in case the charge direction points into a wall
var _stuck_check_interval := 0.25
const STUCK_DISTANCE_THRESHOLD := 6.0 ## Minimum progress required per interval while charging

func _ready() -> void:
	_initialize()
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("take_damage", 1, true)
	animation.configure_animation("die", 2, true)
	hitbox.hit_target.connect(_on_hit_target)

func _initialize() -> void:
	if not stats:
		return
	_initialize_base(stats.max_health, stats.scrap_drop_amount)
	hitbox.initialize(stats.explosion_damage, stats.explosion_knockback)
	_speed = stats.speed
	_charge_speed = stats.charge_speed
	_explosion_screen_shake_intensity = stats.explosion_screen_shake_intensity
	_max_charge_duration = stats.max_charge_duration
	_stuck_check_interval = stats.stuck_check_interval
	_default_avoidance_mask = navigation.avoidance_mask

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead() or _exploding:
		velocity = Vector2.ZERO
	else:
		var target := targeting.get_best_target(global_position)
		if target:
			_face_target(animated_sprite, target.global_position)
			_update_chase_state(target, delta)
			animation.play_animation("idle")
		else:
			_cancel_charge()
			velocity = Vector2.ZERO

	knockback.process(delta)
	move_and_slide()

	if _charging and get_slide_collision_count() > 0:
		_cancel_charge()

func _update_chase_state(target: Node2D, delta: float) -> void:
	if not _charging:
		navigation.avoidance_mask = _default_avoidance_mask
		if line_of_sight.can_see(global_position, target.global_position):
			_start_charge(target.global_position)
		else:
			velocity = navigation.get_safe_velocity(target.global_position, _speed)
			return

	if not line_of_sight.can_see(global_position, target.global_position):
		_cancel_charge()
		velocity = navigation.get_safe_velocity(target.global_position, _speed)
		return

	if _charging and _is_charge_stuck(delta):
		_cancel_charge()
		velocity = navigation.get_safe_velocity(target.global_position, _speed)
		return

	navigation.avoidance_mask = 0
	velocity = _charge_direction * _charge_speed

func _is_charge_stuck(delta: float) -> bool:
	_charge_timer += delta
	if _charge_timer >= _max_charge_duration:
		return true

	_stuck_timer += delta
	if _stuck_timer < _stuck_check_interval:
		return false

	var progressed := global_position.distance_to(_stuck_check_position) >= STUCK_DISTANCE_THRESHOLD
	_stuck_timer = 0.0
	_stuck_check_position = global_position
	return not progressed

func _cancel_charge() -> void:
	_charging = false
	_charge_timer = 0.0
	_stuck_timer = 0.0
	navigation.avoidance_mask = _default_avoidance_mask

func _start_charge(target_position: Vector2) -> void:
	var dir := (target_position - global_position).normalized()
	if dir.length_squared() <= 0.0:
		_charging = false
		return
	_charge_direction = dir
	_charging = true
	_charge_timer = 0.0
	_stuck_timer = 0.0
	_stuck_check_position = global_position

func _on_hit_target(target: Node) -> void:
	if _exploding or is_dead() or not target:
		return
	if not target.is_in_group("player"):
		return
	_trigger_explosion(target.global_position)

func _trigger_explosion(from_position: Vector2) -> void:
	_exploding = true
	_cancel_charge()
	if camera_shake_manager:
		camera_shake_manager.shake_screen(_explosion_screen_shake_intensity, 0.25)
	if hit_particles:
		hit_particles.restart()
	_handle_death(from_position, 0.0)

func buff_damage(multiplier: float) -> void:
	hitbox.damage = int(hitbox.damage * multiplier)
	hitbox.knockback *= multiplier

func _should_restart_hit_particles_on_damage() -> bool:
	return true
