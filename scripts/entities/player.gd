extends CharacterBody2D

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shoot: ShootComponent = $ShootComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var slash: Slash = $Slash

# Movement
const SPEED := 150.0
var build_phase := false
var can_buy_turrets := false

func _ready():
	health.connect("died", Callable(self, "_on_died"))
	health.connect("damaged", Callable(self, "_on_damaged"))

	wave_manager.connect("build_phase_started", Callable(self, "_on_build_phase_started"))
	wave_manager.connect("combat_phase_started", Callable(self, "_on_combat_phase_started"))


func _physics_process(delta):
	
	var input_dir = Input.get_vector("left", "right", "up", "down")

	if knockback.is_active():
		velocity = knockback.velocity
	elif health.is_dead:
		velocity = Vector2.ZERO
		return
	else:
		velocity = input_dir * SPEED
		play_run_anim(input_dir)

	knockback.process(delta)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and shoot.can_shoot():
		shoot.shoot(get_global_mouse_position(), global_position)
	if event.is_action_pressed("slash"):
		slash.start_slash(get_global_mouse_position())

func play_run_anim(input_dir):
	if input_dir.x != 0:
		animated_sprite.flip_h = input_dir.x < 0

	if input_dir != Vector2.ZERO:
		animated_sprite.play("move")
	else:
		animated_sprite.play("idle")

func play_anim(anim_name: String):
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		push_warning("Animation \"" + anim_name + "\" does not exist")

func _on_died():
	collision_shape.set_deferred("disabled", true)
	animated_sprite.play("die")
	
func _on_damaged():
	play_anim("take_damage")

func _on_build_phase_started() -> void:
	build_phase = true

func _on_combat_phase_started(_wave_index: int) -> void:
	build_phase = false
	
func take_damage(amount: int):
	health.take_damage(amount)

func apply_knockback(from_position: Vector2, strength: float):
	knockback.apply(from_position, strength)

func shooting_activated(activated: bool):
	shoot.shooting_activated = activated

func is_dead():
	return health.is_dead
