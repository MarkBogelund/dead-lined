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
	if not health_component:
		return
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
