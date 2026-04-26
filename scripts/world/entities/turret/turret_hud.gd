extends Node
class_name TurretHUD

## Manages TurretInfoPanel and UpgradePanel for a single turret.
## Lives as a child of the turret scene.
## Show/hide is driven by the turret's InteractionZone and wave phase.

@onready var info_panel: TurretInfoPanel = $CanvasLayer/TurretInfoPanel
@onready var upgrade_panel: UpgradePanel = $CanvasLayer/UpgradePanel

var _turret: Node = null
var _player: Player = null
var _wave_manager: WaveManager = null
var _player_in_range := false
var _build_phase := false

func setup(turret: Node, player: Player, wave_manager: WaveManager) -> void:
	_turret = turret
	_player = player
	_wave_manager = wave_manager

	_build_phase = wave_manager.is_build_phase()

	turret.interaction_range.player_entered.connect(_on_player_entered)
	turret.interaction_range.player_exited.connect(_on_player_exited)
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	turret.died.connect(_on_turret_died)

func _on_player_entered() -> void:
	_player_in_range = true
	info_panel.open(_turret)
	if _build_phase:
		upgrade_panel.open(_turret, _player, _wave_manager, info_panel)

func _on_player_exited() -> void:
	_player_in_range = false
	info_panel.close()
	upgrade_panel.close()

func _on_build_phase_started() -> void:
	_build_phase = true
	if _player_in_range:
		upgrade_panel.open(_turret, _player, _wave_manager, info_panel)

func _on_combat_phase_started(_wave: int) -> void:
	_build_phase = false
	upgrade_panel.close()

func _on_turret_died() -> void:
	queue_free()
