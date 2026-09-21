extends EnemyBase
class_name Stalker

@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var body_sprite: AnimatedSprite2D = $Body

@export var stats: StalkerStats

var _speed := 25.0
var _ideal_distance := 100.0
var _distance_tolerance := 20.0
var _max_shoot_distance := 120.0
var _shoot_delay := 0.0
var _telegraphing := false

func _ready() -> void:
	_initialize()
	# Configure animations
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("spawn_sleep", 0, false)
	animation.configure_animation("spawn_wake", 0, true)
	animation.configure_animation("take_damage", 2, true)
	animation.configure_animation("die", 3, true)
	animation.configure_animation("shoot", 1, true)

func _initialize() -> void:
	if not stats:
		return
	_initialize_base(stats.max_health, stats.scrap_drop_amount)
	aiming.initialize(stats.aim_speed, stats.accuracy_angle)
	targeting.configure_priorities({
		"player": stats.player_target_priority,
		"turrets": stats.turret_target_priority,
	}, stats.priority_distance_threshold)
	shoot.initialize(stats.shoot_cooldown, stats.projectile_damage, stats.projectile_knockback, stats.projectile_speed)
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
				
# Telegraph and shoot if within distance and aim is accurate
			if distance <= _max_shoot_distance and _shoot_delay <= 0.0 and not _telegraphing and shoot.is_ready():
				if aiming.is_aimed_at(target.global_position):
					_begin_telegraph()

		# Play idle animation when moving
		animation.play_animation("idle")
		if target:
			_face_target(body_sprite, target.global_position)
	
	knockback.process(delta)
	_add_conveyor_velocity()
	move_and_slide()

func _begin_telegraph() -> void:
	if not animation.play_animation("shoot"):
		return
	_telegraphing = true

## Called by AnimationPlayer Call Method track at the fire keyframe
func _execute_shot() -> void:
	shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction())
	_telegraphing = false
func buff_damage(multiplier: float) -> void:
	shoot.projectile_damage = int(shoot.projectile_damage * multiplier)

func _before_handle_damage() -> void:
	_telegraphing = false

func _before_handle_death() -> void:
	_telegraphing = false
