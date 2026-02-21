extends Area2D

@onready var vfx_component: VFXComponent = $VFXComponent

var projectile_speed: float
var projectile_damage: float
var projectile_knockback: float
var direction := Vector2.ZERO 

@export var hit_vfx: PackedScene

func get_damage() -> float:
	return projectile_damage

func get_knockback() -> float:
	return projectile_knockback

func _physics_process(delta):
	position += direction * projectile_speed * delta

func _on_body_entered(_body: Node) -> void:
	vfx_component.instantiate_vfx(hit_vfx, position)
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
