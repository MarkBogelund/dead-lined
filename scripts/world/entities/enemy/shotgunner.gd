extends EnemyBase
class_name Shotgunner

## Keeps its distance like the Stalker, then stands still during the windup animation, which fires a fan of projectiles.
## Damage during the windup cancels the shot and still spends the attack cooldown.

@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var keep_distance: KeepDistanceComponent = $KeepDistanceComponent
@onready var body_sprite: AnimatedSprite2D = $Visuals/Body

@export var stats: ShotgunnerStats

var _speed := 25.0
var _max_shoot_distance := 120.0
var _shoot_delay := 0.0
var _windup_duration := 2.0
var _winding_up := false

func _ready() -> void:
	_initialize()
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("windup", 1, true)
	animation.configure_animation("shoot", 1, true)

func _initialize() -> void:
	if not stats:
		push_error("%s requires a ShotgunnerStats resource" % name)
		return
	_initialize_base(stats)
	aiming.initialize(stats.aim_speed, stats.aim_tolerance)
	targeting.configure(stats.targeting)
	shoot.initialize(stats.attack_cooldown, stats.damage, stats.knockback, stats.projectile_speed, stats.projectile_lifetime)
	shoot.set_spread(stats.projectile_count, stats.spread_angle)
	keep_distance.initialize(stats.preferred_distance, stats.preferred_distance_tolerance)
	_speed = stats.move_speed
	_max_shoot_distance = stats.shoot_range
	_shoot_delay = stats.first_shot_delay
	_windup_duration = stats.windup_duration

func _physics_process(delta: float) -> void:
	_shoot_delay -= delta
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead():
		velocity = Vector2.ZERO
	elif _winding_up:
		velocity = Vector2.ZERO
	else:
		_process_movement(delta)

	knockback.process(delta)
	_add_conveyor_velocity()
	move_and_slide()

func _process_movement(delta: float) -> void:
	var target := targeting.get_best_target(global_position)
	animation.play_animation("idle")
	if not target:
		velocity = Vector2.ZERO
		return

	var has_line_of_sight := line_of_sight.can_see(global_position, target.global_position)
	var goal := keep_distance.get_move_goal(global_position, target.global_position, has_line_of_sight)
	velocity = navigation.get_safe_velocity(goal, _speed)
	_face_target(body_sprite, target.global_position)

	if not has_line_of_sight:
		return
	aiming.aim_at(target.global_position, delta)
	var in_range := global_position.distance_to(target.global_position) <= _max_shoot_distance
	if in_range and _shoot_delay <= 0.0 and shoot.is_ready() and aiming.is_aimed_at(target.global_position):
		_begin_windup()

## The windup clip is authored at any length and sped up/slowed down to last windup_duration.
func _begin_windup() -> void:
	var speed := animation.get_animation_length("windup") / _windup_duration
	if not animation.play_animation("windup", -1, speed):
		return
	_winding_up = true
	velocity = Vector2.ZERO

## Called by the windup animation's Call Method track at the fire keyframe.
func _execute_shot() -> void:
	if not _winding_up:
		return
	_winding_up = false
	shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction())
	animation.stop_animation("windup")
	animation.play_animation("shoot")

func _cancel_windup() -> void:
	if not _winding_up:
		return
	_winding_up = false
	shoot.start_cooldown()

func buff_damage(multiplier: float) -> void:
	shoot.projectile_damage = int(shoot.projectile_damage * multiplier)

func _before_handle_damage() -> void:
	_cancel_windup()

func _before_handle_death() -> void:
	_cancel_windup()
