extends CharacterBody2D
class_name Chaser

signal died

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var drop_scrap: DropScrapComponent = $DropScrapComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var navigation: NavigationComponent = $NavigationComponent
@onready var hitbox: HitboxComponent = $HitboxComponent

@export var damage := 20
@export var speed := 30.0
@export var self_knockback := 150.0 ## Recoil knockback when hitting player (lower = heavier enemy)

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	hitbox.hit_target.connect(_on_hit_target)
	
	# Setup contact damage hitbox
	hitbox.damage = damage

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead() or (player and player.is_dead()):
		velocity = Vector2.ZERO
	else:
		velocity = navigation.get_safe_velocity(player.global_position, speed)
	
	knockback.process(delta)
	move_and_slide()

func _get_direction_to_player() -> Vector2:
	return (player.global_position - global_position).normalized()

func _play_anim(anim_name: String) -> void:
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func buff_health(multiplier: float) -> void:
	health.buff_max_health(multiplier)

func buff_damage(multiplier: float) -> void:
	damage = int(damage * multiplier)
	hitbox.damage = damage

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
	
	_play_anim("take_damage")

func _handle_death() -> void:
	remove_from_group("enemies")
	died.emit()
	_play_anim("die")

func _on_hit_target(target: Node) -> void:
	print("Chaser hit: ", target)
	# Apply recoil knockback when hitting something (bidirectional knockback)
	if target and self_knockback > 0:
		knockback.apply(target.global_position, self_knockback)

func despawn() -> void:
	drop_scrap.drop()
	queue_free()

func is_dead() -> bool:
	return health.is_dead()