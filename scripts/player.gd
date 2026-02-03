extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Movement
const SPEED := 150.0

# Shooting
@export var projectile_scene: PackedScene
const muzzle_distance := 20.0  # Offset from player to spawn projectile

# Knockback
var knockback_velocity := Vector2.ZERO
const knockback_friction := 1200.0

func _physics_process(_delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")

	# If player is being knocked back, override movement
	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * _delta)
	else:
		velocity = input_dir * SPEED

	# Flip sprite horizontally only when moving horizontally
	if input_dir.x != 0:
		animated_sprite.flip_h = input_dir.x < 0

	# Play animations
	if input_dir != Vector2.ZERO:
		animated_sprite.play("move")
	else:
		animated_sprite.play("idle")
		
	# Shoot using the interact input action
	if Input.is_action_just_pressed("interact"):
		shoot()

	move_and_slide()

# Public function to apply knockback from any source
func apply_knockback(from_position: Vector2, strength: float = 300.0):
	var dir = (global_position - from_position).normalized()
	knockback_velocity = dir * strength

func shoot():
	if projectile_scene == null:
		push_error("Projectile scene not assigned!")
		return

	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()

	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position + dir * muzzle_distance
	projectile.direction = dir
	projectile.rotation = dir.angle()

	get_tree().current_scene.add_child(projectile)
