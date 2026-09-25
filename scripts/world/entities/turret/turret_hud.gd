extends Node
class_name TurretHUD

## Owns the turret's panel. Opens by proximity in both phases; action buttons show in build phase only.
## Forwards panel requests to the turret.

@onready var panel: TurretPanel = %TurretPanel
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var toggle_menu: ToggleMenuComponent = $ToggleMenu

var _turret: TurretBase = null

func setup(turret: TurretBase, wave_manager: WaveManager) -> void:
	_turret = turret
	toggle_menu.open_fn = func() -> void: panel.open(_turret)
	toggle_menu.close_fn = func() -> void: panel.close()
	toggle_menu.interaction_zone = turret.interaction_range
	toggle_menu.menu_control = panel
	panel.set_actions_visible(wave_manager.is_build_phase())
	panel.upgrade_requested.connect(turret.try_upgrade)
	panel.sell_requested.connect(turret.sell)
	if turret.interaction_range.is_player_in_range():
		toggle_menu.open()

	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	turret.died.connect(_on_turret_removed)
	turret.sold.connect(_on_turret_sold)

func _process(_delta: float) -> void:
	if not is_instance_valid(_turret):
		return
	canvas_layer.offset = _turret.get_viewport().get_canvas_transform() * _turret.global_position

func _on_build_phase_started() -> void:
	panel.set_actions_visible(true)

func _on_combat_phase_started(_wave: int) -> void:
	panel.set_actions_visible(false)

func _on_turret_sold(_refund: float) -> void:
	_on_turret_removed()

func _on_turret_removed() -> void:
	toggle_menu.close()
	queue_free()
