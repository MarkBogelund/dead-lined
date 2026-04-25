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

func _process(_delta: float) -> void:
	visible = not _player_in_range
	if not health_component:
		return
	var ratio := float(health_component.get_current_health()) / float(health_component.max_health)
	fill.size.x = BAR_WIDTH * clampf(ratio, 0.0, 1.0)

func set_player_in_range(in_range: bool) -> void:
	_player_in_range = in_range
