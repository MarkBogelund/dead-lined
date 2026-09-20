extends EnemyBase
class_name Chaser

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var stats: ChaserStats

var _speed := 30.0
var _self_knockback := 150.0
var _attack_radius := 60.0
var _attack_exit_margin := 20.0

var _circle_direction := Vector2.ZERO ## Random approach angle; ZERO means not yet chosen
var _is_attacking := false ## Hysteresis latch: avoids flicker when resting right at attack_radius


func _ready() -> void:
	_initialize()
	# Configure animations
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("spawn_sleep", 0, false)
	animation.configure_animation("spawn_wake", 0, true)
	animation.configure_animation("take_damage", 1, true)
	animation.configure_animation("die", 2, true)
	
	hitbox.hit_target.connect(_on_hit_target)

func _initialize() -> void:
	if not stats:
		return
	_initialize_base(stats.max_health, stats.scrap_drop_amount)
	hitbox.initialize(stats.hitbox_damage, stats.hitbox_knockback)
	targeting.configure_priorities({
		"player": stats.player_target_priority,
		"turrets": stats.turret_target_priority,
	}, stats.priority_distance_threshold)
	_speed = stats.speed
	_self_knockback = stats.self_knockback
	_attack_radius = stats.attack_radius
	_attack_exit_margin = stats.attack_exit_margin

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead():
		velocity = Vector2.ZERO
	else:
		var target := targeting.get_best_target(global_position)
		if target:
			if _circle_direction == Vector2.ZERO:
				_circle_direction = Vector2.RIGHT.rotated(randf() * TAU)
			_update_attack_latch(global_position.distance_to(target.global_position))
			navigation.avoidance_mask = 0 if _is_attacking else 1
			velocity = navigation.get_safe_velocity(_get_nav_target(target.global_position), _speed)
			animated_sprite.flip_h = target.global_position.x < global_position.x
			# Play idle animation when moving
			animation.play_animation("idle")
		else:
			velocity = Vector2.ZERO
	
	knockback.process(delta)
	_add_conveyor_velocity()
	move_and_slide()
func buff_damage(multiplier: float) -> void:
	hitbox.damage = int(hitbox.damage * multiplier)

func _on_hit_target(target: Node) -> void:
	if target and _self_knockback > 0:
		knockback.apply(target.global_position, _self_knockback)

func _should_restart_hit_particles_on_damage() -> bool:
	return true

## Enters attack mode at attack_radius, but only exits it past attack_radius + margin, so resting
## exactly on the boundary doesn't flip the target/avoidance state every frame.
func _update_attack_latch(distance_to_target: float) -> void:
	if _is_attacking:
		if distance_to_target > _attack_radius + _attack_exit_margin:
			_is_attacking = false
	# The nav agent can settle up to target_desired_distance short of the circle waypoint
	# (which itself sits exactly attack_radius away), so entry must tolerate that same slack
	# or a chaser can stop just outside attack_radius and never latch in, freezing forever.
	elif distance_to_target <= _attack_radius + navigation.target_desired_distance:
		_is_attacking = true

func _get_nav_target(player_pos: Vector2) -> Vector2:
	# Inside the attack circle, ignore the approach point and go straight for the player
	if _is_attacking:
		return player_pos

	# Outside it, head for this chaser's own point on the circle; avoidance keeps chasers apart en route
	return player_pos + _circle_direction * _attack_radius