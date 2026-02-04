extends Node2D

@onready var canon: Sprite2D = $Canon
@onready var muzzle: Marker2D = $Canon/Muzzle
@export var projectile_scene: PackedScene

@export var detection_range: float = 500.0		# in pixels
@export var rotation_speed: float = 6.0			# radians per second
@export var fire_rate: float = 0.5				# seconds per shot

const UP_FACING_OFFSET := PI / 2

var fire_timer := 0.0

func _process(delta):
	fire_timer -= delta

	var target := get_closest_enemy_in_range()
	if target == null:
		return

	rotate_towards(target.global_position, delta)

	if can_fire_at(target):
		fire_projectile()

func get_closest_enemy_in_range() -> CharacterBody2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: CharacterBody2D = null
	var closest_dist := detection_range * detection_range

	for enemy in enemies:
		if is_target_dead(enemy):
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist <= closest_dist:
			closest_dist = dist
			closest = enemy

	return closest

func is_target_dead(target: CharacterBody2D) -> bool:
	var health := target.get_node_or_null("HealthComponent")
	if health == null:
		return true # assume alive if no health component
	return health.is_dead

func rotate_towards(target_pos: Vector2, delta: float):
	var dir := target_pos - canon.global_position
	var target_angle := dir.angle() + UP_FACING_OFFSET

	canon.rotation = lerp_angle(
		canon.rotation,
		target_angle,
		rotation_speed * delta
	)

func can_fire_at(target: Node2D) -> bool:
	if fire_timer > 0:
		return false

	var dir := target.global_position - canon.global_position
	var target_angle := dir.angle() + UP_FACING_OFFSET

	return abs(angle_difference(canon.rotation, target_angle)) < 0.1

func fire_projectile():
	fire_timer = fire_rate

	var projectile = projectile_scene.instantiate()
	projectile.global_position = muzzle.global_position
	projectile.rotation = canon.rotation
	projectile.direction = Vector2.UP.rotated(canon.rotation)

	get_tree().current_scene.add_child(projectile)
