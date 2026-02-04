extends Area2D

var projectile_speed: float
var direction := Vector2.ZERO 

func _physics_process(delta):
	position += direction * projectile_speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.apply_knockback(global_position, 200)
		body.take_damage(10)

	queue_free()

func set_orientation(pos, rot, dir, speed):
	global_position = pos
	rotation = rot
	direction = dir
	projectile_speed = speed

func set_collision_layers(layers: Array, masks: Array) -> void:
	collision_layer = 0
	collision_mask = 0

	for l in layers:
		collision_layer |= 1 << int(l - 1)  # convert to int
	for m in masks:
		collision_mask |= 1 << int(m - 1)
