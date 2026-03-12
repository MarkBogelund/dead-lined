extends CharacterBody2D
class_name Chaser

signal died

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var drop_scrap: DropScrapComponent = $DropScrapComponent
@onready var chase: ChaseComponent = $ChaseComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var navigation: NavigationComponent = $NavigationComponent

@export var damage := 20
@export var speed := 30.0
@export var enemy_knockback := 200.0
@export var player_knockback := 100.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	hurtbox.hit.connect(_on_hurtbox_hit)

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead() or (player and player.is_dead()):
		velocity = Vector2.ZERO
	else:
		var target_velocity := navigation.get_velocity_to(player.global_position, speed)
		velocity = velocity.lerp(target_velocity, 0.1)
	
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

func _on_hurtbox_hit(attacker: Node) -> void:
	if is_dead():
		return

	if attacker.is_in_group("player_attacks"):
		health.take_damage(attacker.get_damage())
		knockback.apply(attacker.global_position, attacker.get_knockback())
		
		if hit_particles:
			hit_particles.restart()

	elif attacker.is_in_group("player"):
		knockback.apply(attacker.global_position, attacker.get_knockback())

	elif attacker.is_in_group("projectiles"):
		health.take_damage(attacker.get_damage())
		knockback.apply(attacker.global_position, attacker.get_knockback())
		
		if hit_particles:
			hit_particles.restart()

func _on_damaged(_amount: int) -> void:
	if not is_dead():
		_play_anim("take_damage")

func _on_died() -> void:
	remove_from_group("enemies")
	died.emit()
	
	collision_shape.set_deferred("disabled", true)
	_play_anim("die")

func despawn() -> void:
	drop_scrap.drop()
	queue_free()

func is_dead() -> bool:
	return health.is_dead()

func get_damage() -> int:
	return damage

func get_knockback() -> float:
	return player_knockback