extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shoot: ShootComponent = $ShootComponent


# Movement
const SPEED := 150.0

func _ready():
	health.connect("died", Callable(self, "_on_died"))

func _physics_process(delta):
	if health.current_health <= 0:
		health.die()
		return
	
	var input_dir = Input.get_vector("left", "right", "up", "down")

	# --- Movement ---
	if knockback.is_active():
		velocity = knockback.velocity
	else:
		velocity = input_dir * SPEED

	knockback.process(delta)

	# --- Shooting ---
	if Input.is_action_pressed("interact") and shoot.can_shoot():
		shoot.shoot(get_global_mouse_position(), global_position)

	# --- Animation ---
	if input_dir.x != 0:
		animated_sprite.flip_h = input_dir.x < 0

	if input_dir != Vector2.ZERO:
		animated_sprite.play("move")
	else:
		animated_sprite.play("idle")

	move_and_slide()

func apply_knockback(from_position: Vector2, strength: float = 300.0):
	knockback.apply(from_position, strength)
	
func take_damage(amount: int):
	health.take_damage(amount)
	check_and_play_anim("take_damage")

func _on_died():
	# Stop movement and shooting
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)

func check_and_play_anim(anim_name: String):
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		push_warning("Animation \"" + anim_name + "\" does not exist")
