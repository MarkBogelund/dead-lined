extends Node
class_name TurretHUD

## Owns the turret's upgrade panel: opens on proximity + open action in build phase, placed beside the turret.
## Forwards panel requests to the turret.

signal opened
signal closed

@onready var panel: TurretPanel = %TurretPanel
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var actions: Control = $CanvasLayer/Actions
@onready var toggle_menu: ToggleMenuComponent = $ToggleMenu

var _turret: TurretBase = null

func setup(turret: TurretBase) -> void:
	_turret = turret
	toggle_menu.open_fn = func() -> void: panel.open(_turret)
	toggle_menu.close_fn = panel.close
	toggle_menu.interaction_zone = turret.interaction_range
	toggle_menu.menu_control = panel
	toggle_menu.opened.connect(opened.emit)
	toggle_menu.closed.connect(closed.emit)
	panel.upgrade_requested.connect(turret.try_upgrade)
	panel.upgrade_hold_started.connect(turret.start_upgrade_charge)
	panel.upgrade_hold_ended.connect(turret.stop_upgrade_charge)
	panel.sell_requested.connect(turret.sell)
	panel.close_requested.connect(toggle_menu.close)
	turret.died.connect(_on_turret_removed)
	turret.sold.connect(_on_turret_sold)

func set_outline_colors(start_color: Color, end_color: Color) -> void:
	panel.set_outline_colors(start_color, end_color)

func _process(_delta: float) -> void:
	if not is_instance_valid(_turret):
		return
	canvas_layer.offset = _turret.get_viewport().get_canvas_transform() * _turret.global_position
	panel.place_beside(canvas_layer.offset.x)
	actions.position = Vector2(-actions.size.x * 0.5, 28.0)

func _on_turret_sold(_refund: float) -> void:
	_on_turret_removed()

func _on_turret_removed() -> void:
	toggle_menu.close()
	queue_free()
