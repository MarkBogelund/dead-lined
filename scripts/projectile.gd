extends Area2D

var projectile_speed: float
var projectile_damage: float
var projectile_knockback: float
var direction := Vector2.ZERO 

func _physics_process(delta):
	position += direction * projectile_speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies") or body.is_in_group("player"):
		body.apply_knockback(global_position, projectile_knockback)
		body.take_damage(projectile_damage)

	queue_free()

func set_orientation(pos, rot, dir):
	global_position = pos
	rotation = rot
	direction = dir
	
func set_parameters(speed, damage, knockback):
	projectile_speed = speed
	projectile_damage = damage
	projectile_knockback = knockback

func set_collision_layers(layers: Array, masks: Array) -> void:
	collision_layer = 0
	collision_mask = 0

	for l in layers:
		collision_layer |= 1 << int(l - 1)  # convert to int
	for m in masks:
		collision_mask |= 1 << int(m - 1)
