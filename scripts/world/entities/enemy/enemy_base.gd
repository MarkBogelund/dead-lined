extends CharacterBody2D
class_name EnemyBase

signal died

@onready var animation: AnimationHandler = $AnimationHandler
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var drop_scrap: DropScrapComponent = $DropScrapComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var navigation: NavigationComponent = $NavigationComponent
@onready var targeting: TargetingComponent = $TargetingComponent
@onready var contact_hitbox: HitboxComponent = $HitboxComponent


func _initialize_base(max_health: int, scrap_drop_amount: int) -> void:
	health.initialize(max_health)
	drop_scrap.initialize(scrap_drop_amount)

var _spawn_intro_active := false
var _collision_layer_before_intro := 0
var _collision_mask_before_intro := 0
var _conveyor_velocity := Vector2.ZERO

func set_conveyor_velocity(conveyor_velocity: Vector2) -> void:
	_conveyor_velocity = conveyor_velocity

func clear_conveyor_velocity() -> void:
	_conveyor_velocity = Vector2.ZERO

func _add_conveyor_velocity() -> void:
	velocity += _conveyor_velocity

func play_spawn_intro(target_position: Vector2, duration: float) -> void:
	_spawn_intro_active = true
	_collision_layer_before_intro = collision_layer
	_collision_mask_before_intro = collision_mask
	collision_layer = 0
	collision_mask = 0
	collision_shape.set_deferred("disabled", true)
	contact_hitbox.disable()
	set_physics_process(false)
	velocity = Vector2.ZERO
	animation.play_animation("spawn_sleep")

	var intro_tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	intro_tween.tween_property(self, "global_position", target_position, maxf(0.0, duration))
	intro_tween.finished.connect(_finish_spawn_intro)

func _finish_spawn_intro() -> void:
	_spawn_intro_active = false
	collision_layer = _collision_layer_before_intro
	collision_mask = _collision_mask_before_intro
	collision_shape.set_deferred("disabled", false)
	contact_hitbox.enable()
	set_physics_process(true)
	animation.play_animation("spawn_wake")

func buff_health(multiplier: float) -> void:
	health.buff_max_health(multiplier)

func buff_damage(_multiplier: float) -> void:
	push_warning("EnemyBase.buff_damage() should be overridden by subclasses")

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead() or _spawn_intro_active:
		return

	var was_fatal := health.take_damage(amount)

	if was_fatal:
		_handle_death(from_position, knockback_force)
	else:
		_handle_damage(from_position, knockback_force)

func _handle_damage(from_position: Vector2, knockback_force: float) -> void:
	_before_handle_damage()
	knockback.apply(from_position, knockback_force)
	if _should_restart_hit_particles_on_damage() and hit_particles:
		hit_particles.restart()
	animation.play_animation("take_damage")

func _handle_death(from_position: Vector2, knockback_force: float) -> void:
	_before_handle_death()
	knockback.apply(from_position, knockback_force)
	remove_from_group("enemies")
	died.emit()
	animation.play_animation("die")

func _before_handle_damage() -> void:
	pass

func _before_handle_death() -> void:
	pass

func _should_restart_hit_particles_on_damage() -> bool:
	return false

func despawn() -> void:
	drop_scrap.drop()
	queue_free()

func despawn_without_drop() -> void:
	remove_from_group("enemies")
	queue_free()

func is_dead() -> bool:
	return health.is_dead()

func _face_target(sprite: AnimatedSprite2D, target_position: Vector2) -> void:
	sprite.flip_h = target_position.x < global_position.x