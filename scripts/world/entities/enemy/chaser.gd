extends EnemyBase
class_name Chaser

## Walks to its target plus a personal flank offset that fades out up close, then finishes the approach in a straight line.

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var stats: ChaserStats

## Within this distance the chaser steers straight at its target, so standing just off the navmesh can't stall it.
const DIRECT_CHASE_DISTANCE := 32.0
const FLANK_REACHED_DISTANCE := 6.0

var _speed := 30.0
var _self_knockback := 150.0
var _flank_offset := Vector2.ZERO
var _flank_active := true

func _ready() -> void:
	_initialize()
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("spawn_sleep", 0, false)
	animation.configure_animation("spawn_wake", 0, true)
	animation.configure_animation("take_damage", 1, true)
	animation.configure_animation("die", 2, true)
	hitbox.hit_target.connect(_on_hit_target)

func _initialize() -> void:
	if not stats:
		push_error("%s requires a ChaserStats resource" % name)
		return
	_initialize_base(stats)
	hitbox.initialize(stats.damage, stats.knockback)
	targeting.configure(stats.targeting)
	targeting.target_changed.connect(func(_new: Node2D, _old: Node2D) -> void: _flank_active = true)
	_speed = stats.move_speed
	_self_knockback = stats.bounce_back_force
	_flank_offset = Vector2.RIGHT.rotated(randf() * TAU) * stats.flank_distance

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead():
		velocity = Vector2.ZERO
	else:
		var target := targeting.get_best_target(global_position)
		if target:
			if global_position.distance_to(target.global_position) <= DIRECT_CHASE_DISTANCE:
				velocity = navigation.get_safe_direct_velocity(global_position.direction_to(target.global_position) * _speed)
			else:
				velocity = navigation.get_safe_velocity(_get_goal(target.global_position), _speed)
			animated_sprite.flip_h = target.global_position.x < global_position.x
			animation.play_animation("idle")
		else:
			velocity = Vector2.ZERO

	knockback.process(delta)
	_add_conveyor_velocity()
	move_and_slide()

## Target plus the flank offset, scaled from full (far) to zero (close) so every chaser converges on the target itself.
## An off-mesh flank point (near a wall or belt) is snapped onto the walkable area; once reached the flank is dropped.
func _get_goal(target_position: Vector2) -> Vector2:
	if not _flank_active:
		return target_position
	var distance := global_position.distance_to(target_position)
	var strength := clampf(inverse_lerp(stats.flank_zero_distance, stats.flank_full_distance, distance), 0.0, 1.0)
	var goal := NavigationServer2D.map_get_closest_point(navigation.get_navigation_map(), target_position + _flank_offset * strength)
	# One-way: once the flank point is reached, head for the target until the target changes.
	if strength <= 0.0 or global_position.distance_to(goal) <= FLANK_REACHED_DISTANCE:
		_flank_active = false
		return target_position
	return goal

func buff_damage(multiplier: float) -> void:
	hitbox.damage = int(hitbox.damage * multiplier)

func _on_hit_target(target: Node) -> void:
	if target and _self_knockback > 0:
		knockback.apply(target.global_position, _self_knockback)

func _should_restart_hit_particles_on_damage() -> bool:
	return true
