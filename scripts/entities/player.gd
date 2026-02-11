extends CharacterBody2D
class_name Player

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var resource_manager: ResourceManager = get_tree().get_first_node_in_group("resource_manager")

@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var slash: SlashComponent = $SlashComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var movement: MovementComponent = $MovementComponent

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Movement
@export var speed := 170.0
@export var acceleration := 3000.0
@export var friction := 4500.0

var build_phase := false
var can_move := true
var is_slashing := false

func _ready():
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)

	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")

	if health.is_dead:
		velocity = Vector2.ZERO
	else:
		_process_movement(input_dir, delta)

	knockback.process(delta)
	move_and_slide()

	update_movement_animation()

func _process_movement(input_dir: Vector2, delta: float) -> void:
	if knockback.is_active():
		velocity = knockback.velocity
	elif can_move:
		velocity = movement.calculate_velocity(
			velocity,
			input_dir,
			delta
		)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and shoot.can_shoot() and resource_manager.scrap_amount >= shoot.scrap_value:
		resource_manager.scrap_amount -= shoot.scrap_value
		shoot.shoot(get_global_mouse_position(), global_position)

	if event.is_action_pressed("slash"):
		slash.start_slash(get_global_mouse_position())

func update_movement_animation() -> void:
	if health.is_dead or is_slashing:
		return

	if velocity.length() > 10.0:
		play_move()
	else:
		play_idle()

func play_move() -> void:
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

	animated_sprite.play("move")

func play_idle() -> void:
	animated_sprite.play("idle")

func play_slash() -> void:
	animation_player.play("slash")

func play_damage() -> void:
	animation_player.play("take_damage")

func play_die() -> void:
	animation_player.play("die")

func on_slash_started() -> void:
	is_slashing = true
	_face_towards(get_global_mouse_position())
	play_slash()

func on_slash_finished() -> void:
	is_slashing = false

func _face_towards(world_pos: Vector2) -> void:
	var dir_x = world_pos.x - global_position.x
	if dir_x != 0:
		animated_sprite.flip_h = dir_x < 0

func _on_died():
	collision_shape.set_deferred("disabled", true)
	can_move = false
	activate_shooting(false)
	activate_slashing(false)
	play_die()

func _on_damaged():
	play_damage()

func _on_build_phase_started():
	build_phase = true

func _on_combat_phase_started(_wave_index: int):
	build_phase = false
	
func take_damage(amount: int):
	health.take_damage(amount)

func apply_knockback(from_position: Vector2, strength: float):
	knockback.apply(from_position, strength)

func activate_shooting(activated: bool):
	shoot.activate_shooting(activated)

func activate_slashing(activated: bool):
	slash.activate_slashing(activated)

func is_dead():
	return health.is_dead
