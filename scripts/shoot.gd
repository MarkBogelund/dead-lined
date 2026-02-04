extends Node
class_name ShootComponent

@export var projectile_scene: PackedScene
@export var muzzle_distance := 20.0
@export var shoot_cooldown := 0.5
@export var projectile_speed := 300.0
@export var projectile_collision_layers: Array[int] = []
@export var projectile_collision_masks: Array[int] = []

var _shoot_timer := 0.0

func _process(delta: float):
	if _shoot_timer > 0.0:
		_shoot_timer -= delta

func can_shoot():
	return _shoot_timer <= 0.0

func shoot(target_pos: Vector2, shooter_pos: Vector2 = Vector2.ZERO):
	if not can_shoot():
		return

	if projectile_scene == null:
		push_error("No projectile scene assigned to ShootComponent")
		return

	var projectile := projectile_scene.instantiate()
	if not projectile.has_method("set_orientation"):
		push_error("Projectile does not have set_orientation()")
		return

	if !projectile.has_method("set_collision_layers"):
		push_error("Projectile does not have set_collision_layers")
		return
	
	var dir = (target_pos - shooter_pos).normalized()
	
	projectile.set_collision_layers(projectile_collision_layers, projectile_collision_masks)
	print(projectile_collision_masks)

	projectile.set_orientation(
		shooter_pos + dir * muzzle_distance,
		dir.angle(),
		dir,
		projectile_speed
	)

	get_tree().current_scene.add_child(projectile)

	_shoot_timer = shoot_cooldown
