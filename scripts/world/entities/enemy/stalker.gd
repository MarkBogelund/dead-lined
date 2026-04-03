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

@export var damage := 15
@export var speed := 25.0
@export var ideal_distance := 100.0 ## Target distance to maintain from target
@export var distance_tolerance := 20.0 ## Acceptable range around ideal distance before adjusting
@export var max_shoot_distance := 120.0 ## Maximum distance to shoot from (wiggle room)
@export var shoot_cooldown := 1.5
@export var aim_rotation_speed := 4.0
@export var aim_accuracy_angle := 0.25

var current_aim_angle := 0.0

func _ready() -> void:
	# Configure animations
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("take_damage", 1, true)
	animation.configure_animation("die", 2, true)
	
	if shoot:
		shoot.shoot_cooldown = shoot_cooldown

func _physics_process(delta: float) -> void:
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
			var has_line_of_sight := line_of_sight.can_see(target.global_position)
			
			# Movement logic: prioritize line of sight
			if not has_line_of_sight:
				# Phase 1: No LOS - actively seek target to find line of sight
				velocity = navigation.get_safe_velocity(target.global_position, speed)
			else:
				# Phase 2: Has LOS - maintain ideal distance
				var ideal_position := target.global_position - to_target.normalized() * ideal_distance
				
				if distance < (ideal_distance - distance_tolerance):
					# Too close - retreat to ideal position
					velocity = navigation.get_safe_velocity(ideal_position, speed)
				elif distance > (ideal_distance + distance_tolerance):
					# Too far - advance toward target
					velocity = navigation.get_safe_velocity(target.global_position, speed)
				else:
					# Good distance (80-120 range) - track target movement by navigating to ideal position
					velocity = navigation.get_safe_velocity(ideal_position, speed)
			
			# Aim and shoot only when has line of sight
			if has_line_of_sight:
				var target_angle := to_target.angle()
				current_aim_angle = lerp_angle(current_aim_angle, target_angle, aim_rotation_speed * delta)
				
				# Shoot if within distance and aim is accurate
				if distance <= max_shoot_distance:
					var angle_diff = abs(angle_difference(current_aim_angle, target_angle))
					if angle_diff < aim_accuracy_angle:
						shoot.try_shoot(target.global_position, global_position)
		# Play idle animation when moving
		animation.play_animation("idle")
	
	knockback.process(delta)
	move_and_slide()

func buff_health(multiplier: float) -> void:
	health.buff_max_health(multiplier)

func buff_damage(multiplier: float) -> void:
	damage = int(damage * multiplier)
	if shoot:
		shoot.projectile_damage = damage

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead():
		return
	
	var was_fatal = health.take_damage(amount)
	
	if was_fatal:
		_handle_death()
	else:
		_handle_damage(from_position, knockback_force)

func _handle_damage(from_position: Vector2, knockback_force: float) -> void:
	knockback.apply(from_position, knockback_force)
	
	if hit_particles:
		hit_particles.restart()
	
	animation.play_animation("take_damage")

func _handle_death() -> void:
	remove_from_group("enemies")
	died.emit()
	animation.play_animation("die")

func despawn() -> void:
	drop_scrap.drop()
	queue_free()

func is_dead() -> bool:
	return health.is_dead()
