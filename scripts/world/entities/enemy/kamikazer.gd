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
			_update_chase_state(target)
			animation.play_animation("idle")
		else:
			_charging = false
			navigation.avoidance_mask = _default_avoidance_mask
			velocity = Vector2.ZERO

	knockback.process(delta)
	move_and_slide()

func _update_chase_state(target: Node2D) -> void:
	if not _charging:
		navigation.avoidance_mask = _default_avoidance_mask
		if line_of_sight.can_see(global_position, target.global_position):
			_start_charge(target.global_position)
		else:
			velocity = navigation.get_safe_velocity(target.global_position, _speed)
			return

	if not line_of_sight.can_see(global_position, target.global_position):
		_charging = false
		navigation.avoidance_mask = _default_avoidance_mask
		velocity = navigation.get_safe_velocity(target.global_position, _speed)
		return

	navigation.avoidance_mask = 0
	velocity = _charge_direction * _charge_speed

func _start_charge(target_position: Vector2) -> void:
	var dir := (target_position - global_position).normalized()
	if dir.length_squared() <= 0.0:
		_charging = false
		return
	_charge_direction = dir
	_charging = true

func _on_hit_target(target: Node) -> void:
	if _exploding or is_dead() or not target:
		return
	if not target.is_in_group("player"):
		return
	_trigger_explosion(target.global_position)

func _trigger_explosion(from_position: Vector2) -> void:
	_exploding = true
	_charging = false
	navigation.avoidance_mask = _default_avoidance_mask
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
