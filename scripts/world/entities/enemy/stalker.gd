extends EnemyBase
class_name Stalker

@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var orbit: OrbitComponent = $OrbitComponent
@onready var body_sprite: AnimatedSprite2D = $Visuals/Body

@export var stats: StalkerStats

var _speed := 25.0
var _max_shoot_distance := 120.0
var _shoot_delay := 0.0
var _telegraphing := false

func _ready() -> void:
	_initialize()
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("shoot", 1, true)

func _initialize() -> void:
	if not stats:
		push_error("%s requires a StalkerStats resource" % name)
		return
	_initialize_base(stats)
	aiming.initialize(stats.aim_speed, stats.aim_tolerance)
	targeting.configure(stats.targeting)
	shoot.initialize(stats.attack_cooldown, stats.damage, stats.knockback, stats.projectile_speed, stats.projectile_lifetime)
	orbit.initialize(stats.preferred_distance, stats.preferred_distance_tolerance, stats.orbit_exit_margin, stats.orbit_lead_angle, stats.orbit_stuck_time, stats.orbit_stuck_distance)
	targeting.target_changed.connect(func(_new: Node2D, _old: Node2D) -> void: orbit.reset())
	_speed = stats.move_speed
	_max_shoot_distance = stats.shoot_range
	_shoot_delay = stats.first_shot_delay

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
			var distance := global_position.distance_to(target.global_position)
			var has_line_of_sight := line_of_sight.can_see(global_position, target.global_position)
			var goal := orbit.get_move_goal(global_position, target.global_position, has_line_of_sight, delta, navigation.get_navigation_map())
			velocity = navigation.get_safe_velocity(goal, _speed)

			if has_line_of_sight:
				aiming.aim_at(target.global_position, delta)

			if distance <= _max_shoot_distance and _shoot_delay <= 0.0 and not _telegraphing and shoot.is_ready():
				if aiming.is_aimed_at(target.global_position):
					_begin_telegraph()

		animation.play_animation("idle")
		if target:
			_face_target(body_sprite, target.global_position)
	
	knockback.process(delta)
	_apply_environment_velocity()
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
