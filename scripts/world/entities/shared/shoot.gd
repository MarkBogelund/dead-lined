extends Node
class_name ShootComponent

@onready var vfx_component: VFXComponent = $"../VFXComponent"
@export var explosion_vfx_scene: PackedScene

@export var projectile_scene: PackedScene
@export var projectile_damage := 10
@export var projectile_knockback := 200
@export var muzzle_distance := 20.0
@export var shoot_cooldown := 0.5
@export var projectile_speed := 300.0
@export var projectile_collision_layers: Array[int] = []
@export var projectile_collision_masks: Array[int] = []

var _shoot_timer := 0.0
var shooting_activated := true

func _process(delta: float):
	if _shoot_timer > 0.0:
		_shoot_timer -= delta

func set_enabled(enabled: bool):
	shooting_activated = enabled

func try_shoot(target_pos: Vector2, shooter_pos: Vector2) -> bool:
	if _shoot_timer > 0.0 or not shooting_activated:
		return false

	if projectile_scene == null:
		push_error("No projectile scene assigned to ShootComponent")
		return false

	var projectile := projectile_scene.instantiate()
	var dir = (target_pos - shooter_pos).normalized()
	
	projectile.set_collision_layers(projectile_collision_layers, projectile_collision_masks)
	projectile.set_orientation(shooter_pos + dir * muzzle_distance, dir.angle(), dir)
	projectile.set_parameters(projectile_speed, projectile_damage, projectile_knockback)

	get_tree().current_scene.add_child(projectile)
	_shoot_timer = shoot_cooldown
	
	return true
