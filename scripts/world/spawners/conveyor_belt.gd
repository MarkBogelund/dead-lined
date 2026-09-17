extends Area2D
class_name ConveyorBelt

@export var settings: ConveyorSettings
@export var movement_direction := Vector2.DOWN:
	set(value):
		movement_direction = value
		_update_riders()

var _riders: Dictionary[int, Node] = {}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	for rider: Node in _riders.values():
		if is_instance_valid(rider) and rider.has_method("clear_conveyor_velocity"):
			rider.clear_conveyor_velocity()

func _on_body_entered(body: Node) -> void:
	if not body.has_method("set_conveyor_velocity"):
		return
	_riders[body.get_instance_id()] = body
	body.set_conveyor_velocity(_get_movement_velocity(body))

func _on_body_exited(body: Node) -> void:
	_riders.erase(body.get_instance_id())
	if body.has_method("clear_conveyor_velocity"):
		body.clear_conveyor_velocity()

func _update_riders() -> void:
	if Engine.is_editor_hint():
		return
	for rider: Node in _riders.values():
		if is_instance_valid(rider):
			rider.set_conveyor_velocity(_get_movement_velocity(rider))

func _get_movement_speed(body: Node) -> float:
	if body.is_in_group("player"):
		return settings.player_movement_speed if settings else 35.0
	return settings.enemy_movement_speed if settings else 120.0

func _get_movement_velocity(body: Node) -> Vector2:
	if not movement_direction.is_finite() or movement_direction.is_zero_approx():
		return Vector2.DOWN * _get_movement_speed(body)
	return movement_direction.normalized() * _get_movement_speed(body)