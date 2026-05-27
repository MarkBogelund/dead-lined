extends EnemyBase
class_name Chaser

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var stats: ChaserStats

var _speed := 30.0
var _self_knockback := 150.0
var _spread_radius := 48.0
var _spread_strength := 24.0
var _converge_distance := 40.0


func _ready() -> void:
	_initialize()
	# Configure animations
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("take_damage", 1, true)
	animation.configure_animation("die", 2, true)
	
	hitbox.hit_target.connect(_on_hit_target)

func _initialize() -> void:
	if not stats:
		return
	_initialize_base(stats.max_health, stats.scrap_drop_amount)
	hitbox.initialize(stats.hitbox_damage, stats.hitbox_knockback)
	_speed = stats.speed
	_self_knockback = stats.self_knockback
	_spread_radius = stats.spread_radius
	_spread_strength = stats.spread_strength
	_converge_distance = stats.converge_distance

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead():
		velocity = Vector2.ZERO
	else:
		var target := targeting.get_best_target(global_position)
		if target:
			var converging := global_position.distance_to(target.global_position) <= _converge_distance
			navigation.avoidance_mask = 0 if converging else 1
			velocity = navigation.get_safe_velocity(_get_nav_target(target.global_position), _speed)
			animated_sprite.flip_h = target.global_position.x < global_position.x
			# Play idle animation when moving
			animation.play_animation("idle")
		else:
			velocity = Vector2.ZERO
	
	knockback.process(delta)
	move_and_slide()
func buff_damage(multiplier: float) -> void:
	hitbox.damage = int(hitbox.damage * multiplier)

func _on_hit_target(target: Node) -> void:
	if target and _self_knockback > 0:
		knockback.apply(target.global_position, _self_knockback)

func _should_restart_hit_particles_on_damage() -> bool:
	return true

func _get_nav_target(player_pos: Vector2) -> Vector2:
	# Within melee range, ignore spread and go straight for the player
	if global_position.distance_to(player_pos) <= _converge_distance:
		return player_pos
	
	# Accumulate a separation vector away from nearby chasers
	var separation := Vector2.ZERO
	for chaser in get_tree().get_nodes_in_group("enemies"):
		if chaser == self or not chaser is Chaser:
			continue
		var offset := global_position - (chaser as Chaser).global_position
		var dist := offset.length()
		if dist > 0.0 and dist < _spread_radius:
			# Weight by proximity: closer chasers push harder
			separation += offset.normalized() * (1.0 - dist / _spread_radius)
	
	# If no nearby chasers, head straight for the player
	if separation.length_squared() == 0.0:
		return player_pos
	
	return player_pos + separation.normalized() * _spread_strength