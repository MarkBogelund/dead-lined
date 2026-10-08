extends Node2D
class_name HealthUIComponent

## Shared entity status: health plus a caller-controlled secondary progress meter.

@export var health_component: HealthComponent
@export var offset := Vector2(0, -18)
## Color of the secondary meter (turret cooldown or boss armor stress).
@export var cooldown_color := Color(0.85904986, 0.85504586, 0.8550441, 1)
## Turrets show their level; bosses can hide the label.
@export var show_level := true

@onready var fill: ColorRect = $HealthFill
@onready var cooldown_fill: ColorRect = $CooldownFill
@onready var level_label: Label = $LevelLabel

var _full_bar_width := 0.0

func _ready() -> void:
	position = offset
	_full_bar_width = fill.size.x
	cooldown_fill.color = cooldown_color
	level_label.visible = show_level
	set_cooldown_progress(1.0)
	if health_component:
		_connect_health_component()

func set_cooldown_progress(progress: float) -> void:
	cooldown_fill.size.x = _full_bar_width * clampf(progress, 0.0, 1.0)

func set_level(level: int) -> void:
	level_label.text = "%d" % level

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

func _on_health_changed(current: int, maximum: int) -> void:
	_update_health_bar(current, maximum)

func _update_health_bar(current: int, maximum: int) -> void:
	var ratio := float(current) / float(maximum) if maximum > 0 else 0.0
	fill.size.x = _full_bar_width * clampf(ratio, 0.0, 1.0)
