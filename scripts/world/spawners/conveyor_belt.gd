@tool
extends Area2D
class_name ConveyorBelt

@export var belt_size := Vector2(64.0, 160.0):
	set(value):
		belt_size = Vector2(maxf(1.0, value.x), maxf(1.0, value.y))
		_update_collision_shape()

@export var settings: ConveyorSettings

var _riders: Dictionary[int, Node] = {}

func _ready() -> void:
	_update_collision_shape()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	for rider in _riders.values():
		if is_instance_valid(rider) and rider.has_method("clear_conveyor_velocity"):
			rider.clear_conveyor_velocity()

func _on_body_entered(body: Node) -> void:
	if not body.has_method("set_conveyor_velocity"):
		return
	_riders[body.get_instance_id()] = body
	body.set_conveyor_velocity(Vector2.DOWN * _get_movement_speed())

func _on_body_exited(body: Node) -> void:
	_riders.erase(body.get_instance_id())
	if body.has_method("clear_conveyor_velocity"):
		body.clear_conveyor_velocity()

func _update_riders() -> void:
	if Engine.is_editor_hint():
		return
	for rider in _riders.values():
		if is_instance_valid(rider):
			rider.set_conveyor_velocity(Vector2.DOWN * _get_movement_speed())

func _get_movement_speed() -> float:
	return settings.movement_speed if settings else 120.0

func _update_collision_shape() -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not collision_shape:
		return
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle:
		rectangle.size = belt_size
