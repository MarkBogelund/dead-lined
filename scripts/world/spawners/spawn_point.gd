extends Marker2D
class_name SpawnPoint

@export_group("Conveyor Entry")
## Direction from this marker to the point where an assigned enemy becomes active.
@export var spawn_intro_direction := Vector2.DOWN
## Distance the assigned enemy is carried before becoming active.
@export var spawn_intro_distance := 96.0
@export var conveyor_settings: ConveyorSettings

func send_in(enemy: EnemyBase) -> void:
	var direction := spawn_intro_direction
	if not direction.is_finite() or direction.is_zero_approx():
		direction = Vector2.DOWN
	var distance := maxf(0.0, spawn_intro_distance)
	var speed := maxf(1.0, conveyor_settings.enemy_movement_speed if conveyor_settings else 120.0)
	var destination := global_position + direction.normalized() * distance
	enemy.play_spawn_intro(destination, distance / speed)