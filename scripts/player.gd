extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Movement
const SPEED := 150.0

# Shooting
@export var projectile_scene: PackedScene
const muzzle_distance := 20.0  # Offset from player to spawn projectile

func _physics_process(_delta):
	var dir = Input.get_vector("left", "right", "up", "down")
	velocity = dir * SPEED

	# Flip sprite horizontally only when moving horizontally
	if dir.x != 0:
		animated_sprite.flip_h = dir.x < 0

	# Play animations
	if dir != Vector2.ZERO:
		animated_sprite.play("move")
	else:
		animated_sprite.play("idle")
		
	# shoot using the interact input action
	if Input.is_action_just_pressed("interact"):
		shoot()

	move_and_slide()

func shoot():
	if projectile_scene == null:
		push_error("Projectile scene not assigned!")
		return

	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()

	# Instantiate and position projectile slightly away from player
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position + dir * muzzle_distance
	projectile.direction = dir
	projectile.rotation = dir.angle()  # optional: rotate projectile to face mouse

	# Add projectile to scene tree
	get_tree().current_scene.add_child(projectile)
