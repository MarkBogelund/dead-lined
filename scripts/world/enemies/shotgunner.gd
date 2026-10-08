extends EnemyBase
class_name Shotgunner

## Keeps its distance like the Stalker, then stands still during the windup animation, which fires a fan of projectiles.
## A completed shot forces relocation before another attack. Damage during windup cancels the shot and spends its cooldown.

const RELOCATION_CANDIDATES := 16

@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var body_sprite: AnimatedSprite2D = $Visuals/Body
@onready var confused: ConfusedComponent = $Visuals/ConfusedSprite

@export var stats: ShotgunnerStats

var _speed := 25.0
var _max_shoot_distance := 120.0
var _shoot_delay := 0.0
var _windup_duration := 2.0
var _winding_up := false
var _relocating := false
var _relocation_goal := Vector2.ZERO

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
	elif confused.is_movement_locked():
		velocity = Vector2.ZERO
	elif _winding_up:
		velocity = Vector2.ZERO
	elif _relocating:
		_process_relocation()
	else:
		_process_movement(delta)

	knockback.process(delta)
	_apply_environment_velocity()
	move_and_slide()

func _process_movement(delta: float) -> void:
	var target := targeting.get_best_target(global_position)
	animation.play_animation("idle")
	if not target:
		velocity = Vector2.ZERO
		return

	var has_line_of_sight := line_of_sight.can_see(global_position, target.global_position)
	var to_target := target.global_position - global_position
	var goal := target.global_position
	if has_line_of_sight and to_target.length() <= stats.preferred_distance + stats.preferred_distance_tolerance:
		goal -= to_target.normalized() * stats.preferred_distance
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
	var fired := shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction())
	animation.stop_animation("windup")
	animation.play_animation("shoot")
	if fired:
		var recoil_source := global_position + aiming.get_aim_direction()
		knockback.apply(recoil_source, stats.shot_recoil_force)
		confused.start_confusion(stats.attack_cooldown, stats.confusion_movement_lock_duration)
		_begin_relocation()

func _begin_relocation() -> void:
	var navigation_map := navigation.get_navigation_map()
	var required_goal_distance := stats.relocation_min_distance + navigation.target_desired_distance
	var nearest_distance := INF
	var found := false
	for i in RELOCATION_CANDIDATES:
		var candidate := NavigationServer2D.map_get_random_point(
			navigation_map, navigation.navigation_layers, true)
		var distance := global_position.distance_to(candidate)
		if distance < required_goal_distance or distance >= nearest_distance:
			continue
		found = true
		nearest_distance = distance
		_relocation_goal = candidate
	_relocating = found

func _process_relocation() -> void:
	animation.play_animation("idle")
	if global_position.distance_to(_relocation_goal) <= navigation.target_desired_distance:
		_relocating = false
		velocity = Vector2.ZERO
		return
	velocity = navigation.get_safe_velocity(_relocation_goal, _speed)
	_face_target(body_sprite, _relocation_goal)

func _cancel_windup(show_confused: bool) -> void:
	if not _winding_up:
		return
	_winding_up = false
	if show_confused:
		shoot.start_cooldown()
		confused.start_confusion(stats.attack_cooldown, stats.confusion_movement_lock_duration)

func buff_damage(multiplier: float) -> void:
	shoot.projectile_damage = int(shoot.projectile_damage * multiplier)

func _before_handle_damage() -> void:
	_cancel_windup(true)

func _before_handle_death() -> void:
	_cancel_windup(false)
	confused.stop_confusion()
