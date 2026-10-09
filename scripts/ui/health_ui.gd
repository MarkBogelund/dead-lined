extends Node2D
class_name HealthUIComponent

## Two-bar status display: the primary bar follows a HealthComponent, the secondary bar shows any
## 0-1 progress signal. Bar position, size, scale and color are authored on the bar nodes.

enum FillMode {FILL, DRAIN}
enum FillDirection {LEFT_TO_RIGHT, RIGHT_TO_LEFT}

@export var health_component: HealthComponent
@export var primary_bar: ColorRect
@export var secondary_bar: ColorRect
## Optional level readout.
@export var level_label: Label

@export_group("Secondary Bar")
## Fill: the bar grows as progress rises. Drain: it empties as progress rises.
@export var secondary_fill_mode := FillMode.FILL
@export var secondary_fill_direction := FillDirection.LEFT_TO_RIGHT
@export_range(0.0, 1.0, 0.01) var secondary_initial_progress := 1.0

## Authored (left edge, full width) per bar, captured before any fill is applied.
var _layouts: Dictionary[ColorRect, Vector2] = {}

func _ready() -> void:
	for bar: ColorRect in [primary_bar, secondary_bar]:
		if bar:
			_layouts[bar] = Vector2(bar.position.x, bar.size.x)
	set_secondary_progress(secondary_initial_progress)
	if health_component:
		_connect_health_component()

func set_secondary_progress(progress: float) -> void:
	var value := clampf(progress, 0.0, 1.0)
	if secondary_fill_mode == FillMode.DRAIN:
		value = 1.0 - value
	_set_bar_ratio(secondary_bar, value, secondary_fill_direction)

func get_full_width(bar: ColorRect) -> float:
	return _layouts[bar].y if _layouts.has(bar) else 0.0

func set_level(level: int) -> void:
	if level_label:
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
	_set_bar_ratio(primary_bar, ratio, FillDirection.LEFT_TO_RIGHT)

func _set_bar_ratio(bar: ColorRect, ratio: float, direction: FillDirection) -> void:
	if not bar or not _layouts.has(bar):
		return
	var layout := _layouts[bar]
	var width := layout.y * clampf(ratio, 0.0, 1.0)
	bar.size.x = width
	# Right-to-left pins the right edge; the shift is in parent space, so it includes the bar's scale.
	bar.position.x = layout.x + (layout.y - width) * bar.scale.x if direction == FillDirection.RIGHT_TO_LEFT else layout.x
