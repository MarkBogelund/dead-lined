extends CharacterBody2D
class_name Stalker

signal died

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var drop_scrap: DropScrapComponent = $DropScrapComponent
@onready var chase: ChaseComponent = $ChaseComponent
@onready var navigation: NavigationComponent = $NavigationComponent
@onready var circle_movement: CircleMovementComponent = $CircleMovementComponent
@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_particles: GPUParticles2D = $HitParticles

@export var damage := 15
@export var speed := 25.0
@export var min_range := 120.0
@export var max_range := 180.0
@export var shoot_cooldown := 1.5
@export var aim_rotation_speed := 4.0
@export var aim_accuracy_angle := 0.25

var current_aim_angle := 0.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	
	if shoot:
		shoot.shoot_cooldown = shoot_cooldown

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead() or (player and player.is_dead()):
		velocity = Vector2.ZERO
	else:
		var distance := global_position.distance_to(player.global_position)
		var has_line_of_sight := line_of_sight.can_see(player.global_position)
		
		var target_angle := (player.global_position - global_position).angle()
		current_aim_angle = lerp_angle(current_aim_angle, target_angle, aim_rotation_speed * delta)
		
		if not has_line_of_sight:
			var direction := navigation.get_velocity_to(player.global_position, speed).normalized()
			velocity = chase.move_towards(direction)
		elif distance > max_range:
			var direction := navigation.get_velocity_to(player.global_position, speed).normalized()
			velocity = chase.move_towards(direction)
		elif distance < min_range:
			var retreat_direction := (global_position - player.global_position).normalized()
			velocity = chase.move_towards(retreat_direction)
		else:
			var hover_direction := circle_movement.get_hover_direction(player.global_position, min_range, max_range)
			velocity = chase.move_towards(hover_direction * circle_movement.drift_speed_multiplier)
		
		if has_line_of_sight and distance <= max_range:
			var angle_diff: float = abs(angle_difference(current_aim_angle, target_angle))
			if angle_diff < aim_accuracy_angle:
				shoot.try_shoot(player.global_position, global_position)
	
	knockback.process(delta)
	move_and_slide()

func _play_anim(anim_name: String) -> void:
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func buff_health(multiplier: float) -> void:
	health.buff_max_health(multiplier)

func buff_damage(multiplier: float) -> void:
	damage = int(damage * multiplier)
	if shoot:
		shoot.projectile_damage = damage

func take_damage(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead():
		return
	
	health.take_damage(amount)
	knockback.apply(from_position, knockback_force)
	
	if hit_particles:
		hit_particles.restart()
	
	if not is_dead():
		_play_anim("take_damage")

func _on_damaged(_amount: int) -> void:
	pass

func _on_died() -> void:
	remove_from_group("enemies")
	died.emit()
	_play_anim("die")

func despawn() -> void:
	drop_scrap.drop()
	queue_free()

func is_dead() -> bool:
	return health.is_dead()
