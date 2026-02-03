extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED := 150.0

func _physics_process(_delta):
	var dir = Input.get_vector(
		"left", 
		"right", 
		"up", 
	    "down"
	)

	velocity = dir * SPEED
#
	if dir.x != 0:
		animated_sprite.flip_h = dir.x < 0

	if dir != Vector2.ZERO:
		animated_sprite.play("move")
	else:
		animated_sprite.play("idle")

	move_and_slide()
