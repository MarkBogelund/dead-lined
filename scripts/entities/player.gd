extends CharacterBody2D
class_name Player

signal damaged(curret_health)

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var resource_manager: ResourceManager = get_tree().get_first_node_in_group("resource_manager")

@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var slash: SlashComponent = $SlashComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var animation: AnimationComponent = $AnimationComponent

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var build_phase := false
var can_move := true

func _ready():
	health.died.connect(_on_died)

	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)

func _physics_process(delta):

	var input_dir = Input.get_vector("left", "right", "up", "down")
		
	_process_movement(input_dir, delta)
	knockback.process(delta)
	move_and_slide()

	_update_animation()
	_update_flip()

func _process_movement(input_dir: Vector2, delta: float) -> void:

	if knockback.is_active():
		velocity = knockback.velocity
	elif can_move:
		velocity = movement.calculate_velocity(
			velocity,
			input_dir,
			delta
		)
	else:
		velocity = Vector2.ZERO

func _update_animation() -> void:

	if health.is_dead:
		animation.set_state(AnimationComponent.State.DIE)
		return

	# Only set base states here
	if velocity.length() > 10.0:
		animation.set_state(AnimationComponent.State.MOVE)
	else:
		animation.set_state(AnimationComponent.State.IDLE)

func _update_flip():

	# Do not override slash direction while slashing
	if animation.current_state == AnimationComponent.State.SLASH:
		return

	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

func _unhandled_input(event: InputEvent):

	if event.is_action_pressed("shoot") \
	and shoot.can_shoot() \
	and resource_manager.scrap_amount >= shoot.scrap_value:

		resource_manager.scrap_amount -= shoot.scrap_value
		shoot.shoot(get_global_mouse_position(), global_position)

	if event.is_action_pressed("slash"):
		slash.start_slash(get_global_mouse_position())

func on_slash_started() -> void:

	_face_towards(get_global_mouse_position())
	animation.set_state(AnimationComponent.State.SLASH)

func _face_towards(world_pos: Vector2) -> void:
	var dir_x = world_pos.x - global_position.x
	if dir_x != 0:
		animated_sprite.flip_h = dir_x < 0

func _on_died():
	collision_shape.set_deferred("disabled", true)
	can_move = false
	activate_shooting(false)
	activate_slashing(false)
	animation.set_state(AnimationComponent.State.DIE)

func _on_build_phase_started():
	build_phase = true

func _on_combat_phase_started(_wave_index: int):
	build_phase = false

func take_damage(amount: int):
	animation.set_state(AnimationComponent.State.DAMAGE)
	health.take_damage(amount)
	emit_signal("damaged", get_health())

func apply_knockback(from_position: Vector2, strength: float):
	knockback.apply(from_position, strength)

func activate_shooting(activated: bool):
	shoot.activate_shooting(activated)

func activate_slashing(activated: bool):
	slash.activate_slashing(activated)

func is_dead():
	return health.is_dead

func get_health():
	return health.current_health
