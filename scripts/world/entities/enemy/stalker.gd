extends CharacterBody2D
class_name Stalker

signal died

@onready var animation: AnimationHandler = $AnimationHandler
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var drop_scrap: DropScrapComponent = $DropScrapComponent
@onready var navigation: NavigationComponent = $NavigationComponent
@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var targeting: TargetingComponent = $TargetingComponent
@onready var aiming: AimingComponent = $AimingComponent

@export var stats: StalkerStats

var _speed := 25.0
var _ideal_distance := 100.0
var _distance_tolerance := 20.0
var _max_shoot_distance := 120.0
var _shoot_delay := 0.0

func _ready() -> void:
	_initialize()
	# Configure animations
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("take_damage", 2, true)
	animation.configure_animation("die", 3, true)
	animation.configure_animation("shoot", 1, true)

func _initialize() -> void:
	if not stats:
		return
	health.initialize(stats.max_health)
	aiming.aim_speed = stats.aim_speed
	aiming.accuracy_angle = stats.accuracy_angle
	shoot.shoot_cooldown = stats.shoot_cooldown
	shoot.projectile_damage = stats.projectile_damage
	shoot.projectile_knockback = stats.projectile_knockback
	shoot.projectile_speed = stats.projectile_speed
	drop_scrap.scrap_drop_amount = stats.scrap_drop_amount
	_speed = stats.speed
	_ideal_distance = stats.ideal_distance
	_distance_tolerance = stats.distance_tolerance
	_max_shoot_distance = stats.max_shoot_distance
	_shoot_delay = stats.shoot_start_delay

func _physics_process(delta: float) -> void:
	_shoot_delay -= delta
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead():
		velocity = Vector2.ZERO
	else:
		var target := targeting.get_best_target(global_position)
		if not target:
			velocity = Vector2.ZERO
		else:
			# Calculate distance and line of sight
			var to_target := target.global_position - global_position
			var distance := to_target.length()
			var has_line_of_sight := line_of_sight.can_see(global_position, target.global_position)
			
			# Movement logic: prioritize line of sight
			if not has_line_of_sight:
				# Phase 1: No LOS - actively seek target to find line of sight
				velocity = navigation.get_safe_velocity(target.global_position, _speed)
			else:
				# Phase 2: Has LOS - maintain ideal distance
				var ideal_position := target.global_position - to_target.normalized() * _ideal_distance
				
				if distance < (_ideal_distance - _distance_tolerance):
					# Too close - retreat to ideal position
					velocity = navigation.get_safe_velocity(ideal_position, _speed)
				elif distance > (_ideal_distance + _distance_tolerance):
					# Too far - advance toward target
					velocity = navigation.get_safe_velocity(target.global_position, _speed)
				else:
					# Good distance (80-120 range) - track target movement by navigating to ideal position
					velocity = navigation.get_safe_velocity(ideal_position, _speed)
			
			# Aim and shoot only when has line of sight
			if has_line_of_sight:
				aiming.aim_at(target.global_position, delta)
				
				# Shoot if within distance and aim is accurate
				if distance <= _max_shoot_distance and _shoot_delay <= 0.0:
					if aiming.is_aimed_at(target.global_position):
						if shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction()):
							animation.play_animation("shoot")

		# Play idle animation when moving
		animation.play_animation("idle")
	
	knockback.process(delta)
	move_and_slide()

func buff_health(multiplier: float) -> void:
	health.buff_max_health(multiplier)

func buff_damage(multiplier: float) -> void:
	shoot.projectile_damage = int(shoot.projectile_damage * multiplier)

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead():
		return
	
	var was_fatal = health.take_damage(amount)
	
	if was_fatal:
		_handle_death(from_position, knockback_force)
	else:
		_handle_damage(from_position, knockback_force)

func _handle_damage(from_position: Vector2, knockback_force: float) -> void:
	knockback.apply(from_position, knockback_force)
	
	animation.play_animation("take_damage")

func _handle_death(from_position: Vector2, knockback_force: float) -> void:
	remove_from_group("enemies")
	knockback.apply(from_position, knockback_force)
	died.emit()
	animation.play_animation("die")
	
func is_dead() -> bool:
	return health.is_dead()
