extends Node
class_name ShootComponent

@export var explosion_vfx_scene: PackedScene

@export var projectile_scene: PackedScene
@export var projectile_damage := 10
@export var projectile_knockback := 200
@export var shoot_cooldown := 0.5
@export var projectile_speed := 300.0

var _shoot_timer := 0.0
var shooting_activated := true

func _process(delta: float):
	if _shoot_timer > 0.0:
		_shoot_timer -= delta

func set_enabled(enabled: bool):
	shooting_activated = enabled

func try_shoot(from_pos: Vector2, direction: Vector2) -> bool:
	if _shoot_timer > 0.0 or not shooting_activated:
		return false

	if projectile_scene == null:
		push_error("No projectile scene assigned to ShootComponent")
		return false

	var projectile := projectile_scene.instantiate()
	projectile.set_orientation(from_pos, direction.angle(), direction)
	projectile.set_parameters(projectile_speed, projectile_damage, projectile_knockback)

	get_tree().current_scene.add_child(projectile)
	_shoot_timer = shoot_cooldown
	
	return true
