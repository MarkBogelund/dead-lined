extends Area2D

var projectile_speed: float
var projectile_damage: float
var projectile_knockback: float
var direction := Vector2.ZERO 

@export var hit_vfx: PackedScene

func _physics_process(delta):
	position += direction * projectile_speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies") or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(projectile_damage)

		if body.has_method("apply_knockback"):
			body.apply_knockback(global_position, projectile_knockback)
			
	add_hit_vfx(position)
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

func add_hit_vfx(hit_position: Vector2):
	if hit_vfx == null:
		push_error("No hit vfx scene attached")
		return
	
	var hit = hit_vfx.instantiate()
	hit.position = hit_position
	get_tree().current_scene.add_child(hit)
