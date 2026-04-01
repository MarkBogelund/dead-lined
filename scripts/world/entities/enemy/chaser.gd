extends CharacterBody2D
class_name Chaser

signal died

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var drop_scrap: DropScrapComponent = $DropScrapComponent
@onready var chase: ChaseComponent = $ChaseComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var navigation: NavigationComponent = $NavigationComponent
@onready var hitbox: HitboxComponent = $HitboxComponent

@export var damage := 20
@export var speed := 30.0
@export var enemy_knockback := 250.0  ## Knockback received when hit by weapons
@export var player_knockback := 250.0  ## Knockback applied to player on contact
@export var self_knockback := 150.0  ## Recoil knockback when hitting player (lower = heavier enemy)

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	hitbox.hit_target.connect(_on_hit_target)
	
	# Setup contact damage hitbox
	hitbox.damage = damage
	hitbox.knockback = player_knockback

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead() or (player and player.is_dead()):
		velocity = Vector2.ZERO
	else:
		var direction := navigation.get_velocity_to(player.global_position, speed).normalized()
		velocity = chase.move_towards(direction)
	
	knockback.process(delta)
	move_and_slide()

func _get_direction_to_player() -> Vector2:
	return navigation.get_velocity_to(player.global_position, speed).normalized()

func _play_anim(anim_name: String) -> void:
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func buff_health(multiplier: float) -> void:
	health.buff_max_health(multiplier)

func buff_damage(multiplier: float) -> void:
	damage = int(damage * multiplier)
	hitbox.damage = damage

func take_damage(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead():
		return
	
	# Ignore friendly fire from other enemies (check via collision layers instead)
	# Note: This is handled by collision masks, but we keep this as a safety check
	
	health.take_damage(amount)
	knockback.apply(from_position, knockback_force)
	
	if hit_particles:
		hit_particles.restart()
	
	if not is_dead():
		_play_anim("take_damage")

func _on_damaged(_amount: int) -> void:
	# Health component emits this signal, but we handle animation in take_damage directly now
	pass

func _on_hit_target(target: Node) -> void:
	print("Chaser hit: ", target)
	# Apply recoil knockback when hitting something (bidirectional knockback)
	if target and self_knockback > 0:
		knockback.apply(target.global_position, self_knockback)

func _on_died() -> void:
	remove_from_group("enemies")
	died.emit()
	
	#collision_shape.set_deferred("disabled", true)
	_play_anim("die")

func despawn() -> void:
	drop_scrap.drop()
	queue_free()

func is_dead() -> bool:
	return health.is_dead()