extends Area2D

@export var speed := 500.0
var direction := Vector2.ZERO

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.apply_knockback(global_position, 200)
		#body.queue_free() # remove later when you add health

	queue_free()
