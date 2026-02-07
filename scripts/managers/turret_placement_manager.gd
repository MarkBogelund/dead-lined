extends Node2D
class_name TurretPlacementManager

@export var max_place_distance := 250.0

var ghost_turret: Node2D = null
var active := false
var anchor_position: Vector2


func _process(delta: float) -> void:
	if active:
		update_position(get_global_mouse_position())
#
func start_placement(ghost_scene: PackedScene, player_position: Vector2):
	clear()
	anchor_position = player_position
	
	ghost_turret = ghost_scene.instantiate()
	get_tree().current_scene.add_child(ghost_turret)

	active = true

func update_position(mouse_world_pos: Vector2) -> void:
	if not ghost_turret:
		return

	var direction := mouse_world_pos - anchor_position
	var distance := direction.length()

	if distance > max_place_distance:
		direction = direction.normalized() * max_place_distance

	ghost_turret.global_position = anchor_position + direction

func clear() -> void:
	if ghost_turret:
		ghost_turret.queue_free()
		ghost_turret = null
	active = false
