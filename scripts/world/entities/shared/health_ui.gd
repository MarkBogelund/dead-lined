extends Node2D
class_name HealthUIComponent

@export var health_component: HealthComponent
@export var offset := Vector2(0, -18)

@onready var fill: ColorRect = $Fill

const BAR_WIDTH := 24.0
var _player_in_range := false

func _ready() -> void:
	position = offset
	visible = true
	if health_component:
		_connect_health_component()

func setup(component: HealthComponent) -> void:
	if health_component == component:
		if is_node_ready():
			_update_health_bar(component.get_current_health(), component.max_health)
		return
	if health_component and health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.disconnect(_on_health_changed)
	health_component = component
	if is_node_ready():
		_connect_health_component()

func _connect_health_component() -> void:
	if not health_component:
		return
	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)
	_update_health_bar(health_component.get_current_health(), health_component.max_health)

func set_player_in_range(in_range: bool) -> void:
	_player_in_range = in_range
	visible = not in_range

func _on_health_changed(current: int, maximum: int) -> void:
	_update_health_bar(current, maximum)

func _update_health_bar(current: int, maximum: int) -> void:
	var ratio := float(current) / float(maximum) if maximum > 0 else 0.0
	fill.size.x = BAR_WIDTH * clampf(ratio, 0.0, 1.0)
