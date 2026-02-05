extends EnemyBase
class_name ChargerEnemy

@export var separation_radius := 40.0
@export var separation_force := 120.0
@export var speed := 30.0

func get_desired_velocity() -> Vector2:
	var desired_velocity := get_chase_velocity() + get_separation_velocity()

	if desired_velocity.length() > speed:
		desired_velocity = desired_velocity.normalized() * speed

	return desired_velocity

func get_chase_velocity() -> Vector2:
	var dir := (player.global_position - global_position).normalized()
	return dir * speed

func get_separation_velocity() -> Vector2:
	var push := Vector2.ZERO
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if enemy == self:
			continue
		if enemy.health.is_dead:
			continue

		var offset: Vector2 = global_position - enemy.global_position
		var dist := offset.length()

		if dist > 0.0 and dist < separation_radius:
			var strength := (separation_radius - dist) / separation_radius
			push += offset.normalized() * strength

	return push * separation_force
