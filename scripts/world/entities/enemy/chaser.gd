extends CharacterBody2D
class_name Chaser

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var drop_scrap: DropScrapComponent = $DropScrapComponent
@onready var chase: ChaseComponent = $ChaseComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_particles: GPUParticles2D = $HitParticles

@export var damage := 20
@export var enemy_knockback := 200.0
@export var player_knockback := 100.0

func _ready() -> void:
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	hurtbox.hit.connect(_on_hurtbox_hit)

func _physics_process(delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead() or (chase.target and chase.target.is_dead()):
		velocity = Vector2.ZERO
	else:
		velocity = chase.get_velocity()
	
	knockback.process(delta)
	move_and_slide()

func _play_anim(anim_name: String) -> void:
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func buff_health(multiplier: float) -> void:
	health.max_health *= multiplier
	health.current_health = health.max_health

func buff_damage(multiplier: float) -> void:
	damage *= multiplier

func get_damage() -> int:
	return damage

func get_knockback() -> float:
	return player_knockback

func _on_hurtbox_hit(attacker: Node) -> void:
	if is_dead():
		return

	# Distinguish between weapon attacks and body collisions
	if attacker.is_in_group("player_attacks"):
		# Weapon attack: take damage + knockback
		health.take_damage(attacker.get_damage())
		knockback.apply(attacker.global_position, attacker.get_knockback())
		
		# Trigger hit particles (if they exist)
		if hit_particles:
			hit_particles.restart()
	elif attacker.is_in_group("player"):
		# Body collision: knockback only, no damage
		knockback.apply(attacker.global_position, attacker.get_knockback())

func _on_damaged(_amount: int) -> void:
	if not is_dead():
		_play_anim("take_damage")

func _on_died() -> void:
	remove_from_group("enemies")
	wave_manager.call_deferred("check_for_wave_clear")
	collision_shape.set_deferred("disabled", true)
	_play_anim("die")

func despawn() -> void:
	drop_scrap.drop()
	queue_free()

func is_dead() -> bool:
	return health.is_dead
