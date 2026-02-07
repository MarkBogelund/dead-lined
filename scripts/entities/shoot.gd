extends Node
class_name ShootComponent

@export var projectile_scene: PackedScene
@export var projectile_damage := 10
@export var projectile_knockback := 200
@export var muzzle_distance := 20.0
@export var shoot_cooldown := 0.5
@export var projectile_speed := 300.0
@export var projectile_collision_layers: Array[int] = []
@export var projectile_collision_masks: Array[int] = []
@export var explosion_vfx_scene: PackedScene

var _shoot_timer := 0.0
var shooting_activated := true

func _process(delta: float):
	if _shoot_timer > 0.0:
		_shoot_timer -= delta

func can_shoot():
	return _shoot_timer <= 0.0 and shooting_activated == true

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
		
	if !projectile.has_method("set_parameters"):
		push_error("Projectile does not have set_parameters")
		return
	
	var dir = (target_pos - shooter_pos).normalized()
	
	projectile.set_collision_layers(projectile_collision_layers, projectile_collision_masks)

	projectile.set_orientation(shooter_pos + dir * muzzle_distance, dir.angle(), dir)
	
	projectile.set_parameters(projectile_speed, projectile_damage, projectile_knockback)

	get_tree().current_scene.add_child(projectile)

	_shoot_timer = shoot_cooldown
	
	if explosion_vfx_scene != null:
		var explosion = explosion_vfx_scene.instantiate()
		explosion.position = shooter_pos
		get_tree().current_scene.add_child(explosion)

	
