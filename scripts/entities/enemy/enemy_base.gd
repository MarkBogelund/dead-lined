extends CharacterBody2D
class_name EnemyBase

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var damage := 20
@export var enemy_knockback := 200.0
@export var player_knockback := 100.0

@export var scrap_drop_amount := 1
@export var scrap_drop_radius := 0.0
@export var scrap_scene: PackedScene

var player: Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead() or player.is_dead():
		velocity = Vector2.ZERO
	else:
		velocity = get_desired_velocity()

	knockback.process(delta)
	move_and_slide()

# Virtual methods (override in subclasses)
func get_desired_velocity() -> Vector2:
	return Vector2.ZERO

func _on_hitbox_body_entered(body: Node2D) -> void:
	if health.is_dead:
		return

	if !body.is_in_group("player"):
		return
	
	health.take_damage(damage)
	knockback.apply(body.global_position, enemy_knockback)

	if body.has_method("take_damage"):
		body.take_damage(damage)

	if body.has_method("apply_knockback"):
		body.apply_knockback(global_position, player_knockback)

func play_anim(anim_name: String) -> void:
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		push_warning("Animation \"%s\" does not exist" % anim_name)

func buff_health(multiplier):
	health.max_health *= multiplier
	health.current_health = health.max_health

func buff_damage(multiplier) -> void:
	damage *= multiplier
	
func _on_damaged() -> void:
	if not health.is_dead:
		play_anim("take_damage")
	
func _on_died() -> void:
	remove_from_group("enemies")
	wave_manager.call_deferred("check_for_wave_clear")
	collision_shape.set_deferred("disabled", true)
	hitbox_collision_shape.set_deferred("disabled", true)
	play_anim("die")

func drop_scrap():
	for i in scrap_drop_amount:
		var scrap = scrap_scene.instantiate()
		scrap.set_explosion(global_position, scrap_drop_radius)
		get_tree().current_scene.add_child(scrap)

func _is_player_dead() -> bool:
	return player.health.is_dead

func take_damage(amount: int):
	health.take_damage(amount)

func apply_knockback(from_position: Vector2, strength: float):
	knockback.apply(from_position, strength)

func is_dead():
	return health.is_dead
