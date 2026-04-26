extends Node
class_name TurretHUD

## Manages TurretInfoPanel and UpgradePanel for a single turret.
## Lives as a child of the turret scene.
## Show/hide is driven by the turret's InteractionZone and wave phase.

@onready var info_panel: TurretInfoPanel = %InfoPanel
@onready var upgrade_panel: UpgradePanel = %UpgradePanel
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var toggle_menu: ToggleMenuComponent = $ToggleMenuUpgrade
@onready var _toggle_info: ToggleMenuComponent = $ToggleMenuInfo

var _turret: Node = null
var _player: Player = null
var _wave_manager: WaveManager = null
var _build_phase := false

func setup(turret: Node, player: Player, wave_manager: WaveManager) -> void:
	_turret = turret
	_player = player
	_wave_manager = wave_manager
	_build_phase = wave_manager.is_build_phase()

	toggle_menu.open_fn = func(): upgrade_panel.open(_turret, _player, _wave_manager)
	toggle_menu.close_fn = func(): upgrade_panel.close()
	toggle_menu.interaction_zone = turret.interaction_range
	toggle_menu.menu_control = upgrade_panel
	toggle_menu.enabled = _build_phase

	_toggle_info.open_fn = func(): info_panel.open(_turret)
	_toggle_info.close_fn = func(): info_panel.close()
	_toggle_info.interaction_zone = turret.interaction_range

	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	turret.died.connect(_on_turret_died)

func _process(_delta: float) -> void:
	if not is_instance_valid(_turret):
		return
	canvas_layer.offset = _turret.get_viewport().get_canvas_transform() * _turret.global_position

func _on_build_phase_started() -> void:
	_build_phase = true
	toggle_menu.enabled = true

func _on_combat_phase_started(_wave: int) -> void:
	_build_phase = false
	toggle_menu.enabled = false

func _on_turret_died() -> void:
	toggle_menu.close()
	_toggle_info.close()
	queue_free()
