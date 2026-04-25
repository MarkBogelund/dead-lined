extends Control
class_name UpgradePanel

@onready var background: PanelContainer = $Background
@onready var upgrade_health_button: Button = $Background/VBox/UpgradeHealthButton
@onready var upgrade_damage_button: Button = $Background/VBox/UpgradeDamageButton
@onready var repair_button: Button = $Background/VBox/RepairButton

var _turret: Turret = null
var _player: Player = null
var _wave_manager: WaveManager = null
var _info_panel: TurretInfoPanel = null
var _repairing := false
var _repair_accumulator := 0.0

func _ready() -> void:
	visible = false
	upgrade_health_button.pressed.connect(_on_upgrade_health_pressed)
	upgrade_damage_button.pressed.connect(_on_upgrade_damage_pressed)
	repair_button.button_down.connect(func(): _repairing = true)
	repair_button.button_up.connect(func(): _repairing = false; _repair_accumulator = 0.0)

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(_turret) or not is_instance_valid(_info_panel):
		_repairing = false
		return
	var info_bg := _info_panel.background
	background.custom_minimum_size.x = info_bg.size.x
	background.position = Vector2(
		info_bg.position.x + info_bg.size.x * 0.5 - background.size.x * 0.5,
		info_bg.position.y + info_bg.size.y + 4.0
	)
	_handle_repair(delta)
	repair_button.disabled = _turret.health.is_full() or not _player.capacity.can_afford(delta * _turret.stats.capacity_drain_rate)

func open(turret: Turret, player: Player, wave_manager: WaveManager, info_panel: TurretInfoPanel) -> void:
	if _turret:
		_disconnect_turret()
	_turret = turret
	_player = player
	_wave_manager = wave_manager
	_info_panel = info_panel
	_turret.died.connect(close)
	_turret.health_ui.set_upgrade_open(true)
	_turret.set_upgrade_panel_open(true)
	_refresh()
	visible = true

func close() -> void:
	if is_instance_valid(_turret):
		_turret.health_ui.set_upgrade_open(false)
		_turret.set_upgrade_panel_open(false)
	_disconnect_turret()
	visible = false

func _disconnect_turret() -> void:
	if not is_instance_valid(_turret):
		_turret = null
		_player = null
		_wave_manager = null
		_info_panel = null
		return
	if _turret.died.is_connected(close):
		_turret.died.disconnect(close)
	_turret = null
	_player = null
	_wave_manager = null
	_info_panel = null

func _refresh() -> void:
	if not _turret or not _player or not _wave_manager:
		return
	var cost := _turret.stats.upgrade_cost
	upgrade_health_button.text = "+%d HP (%d cap)" % [_turret.stats.health_upgrade_amount, int(cost)]
	upgrade_damage_button.text = "+%d DMG (%d cap)" % [_turret.stats.damage_upgrade_amount, int(cost)]
	var can_upgrade := _turret.level < _wave_manager.current_wave \
		and _player.capacity.can_afford(cost)
	upgrade_health_button.disabled = not can_upgrade
	upgrade_damage_button.disabled = not can_upgrade

func _on_upgrade_health_pressed() -> void:
	if not _turret or not _player:
		return
	_turret.apply_health_upgrade()
	_player.capacity.spend(_turret.stats.upgrade_cost)
	_refresh()

func _on_upgrade_damage_pressed() -> void:
	if not _turret or not _player:
		return
	_turret.apply_damage_upgrade()
	_player.capacity.spend(_turret.stats.upgrade_cost)
	_refresh()

func _handle_repair(delta: float) -> void:
	if not _repairing or not _turret or not _player:
		return
	if _turret.health.is_full():
		_repairing = false
		_repair_accumulator = 0.0
		return
	var drain := _turret.stats.capacity_drain_rate * delta
	if not _player.capacity.can_afford(drain):
		_repairing = false
		_repair_accumulator = 0.0
		return
	_player.capacity.spend(drain)
	_repair_accumulator += _turret.stats.health_restore_rate * delta
	var heal_amount := int(_repair_accumulator)
	if heal_amount > 0:
		_turret.health.heal(heal_amount)
		_repair_accumulator -= heal_amount

