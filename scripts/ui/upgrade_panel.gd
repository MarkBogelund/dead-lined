extends Control
class_name UpgradePanel

@onready var upgrade_health_button: Button = %UpgradeHealthButton
@onready var upgrade_damage_button: Button = %UpgradeDamageButton
@onready var repair_button: Button = %RepairButton

var _turret: Node = null
var _player: Player = null
var _wave_manager: WaveManager = null
var _repairing := false
var _repair_accumulator := 0.0

func _ready() -> void:
	visible = false
	upgrade_health_button.pressed.connect(_on_upgrade_health_pressed)
	upgrade_damage_button.pressed.connect(_on_upgrade_damage_pressed)
	repair_button.button_down.connect(func(): _repairing = true)
	repair_button.button_up.connect(func(): _repairing = false; _repair_accumulator = 0.0)

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(_turret):
		_repairing = false
		return
	_handle_repair(delta)
	_update_button_states(delta)

func open(turret: Node, player: Player, wave_manager: WaveManager) -> void:
	if _turret:
		_disconnect_turret()
	_turret = turret
	_player = player
	_wave_manager = wave_manager
	_turret.died.connect(close)
	_refresh()
	visible = true

func close() -> void:
	_repairing = false
	_repair_accumulator = 0.0
	_disconnect_turret()
	visible = false

func is_open() -> bool:
	return visible

func _disconnect_turret() -> void:
	if not is_instance_valid(_turret):
		_turret = null
		_player = null
		_wave_manager = null
		return
	if _turret.died.is_connected(close):
		_turret.died.disconnect(close)
	_turret = null
	_player = null
	_wave_manager = null

func _refresh() -> void:
	if not _turret or not _wave_manager:
		return
	var hp_data: TurretUpgrade = _turret.upgrader.health_upgrade_data()
	var dmg_data: TurretUpgrade = _turret.upgrader.damage_upgrade_data()
	upgrade_health_button.text = "+%d HP (%d cap)" % [hp_data.value, int(hp_data.cost)] if hp_data else "Max HP"
	upgrade_damage_button.text = "+%d DMG (%d cap)" % [dmg_data.value, int(dmg_data.cost)] if dmg_data else "Max DMG"

func _update_button_states(delta: float) -> void:
	var hp_data: TurretUpgrade = _turret.upgrader.health_upgrade_data()
	var dmg_data: TurretUpgrade = _turret.upgrader.damage_upgrade_data()
	var level_ok = _turret.upgrader.level < _wave_manager.current_wave
	upgrade_health_button.disabled = hp_data == null \
		or not level_ok \
		or not _player.capacity.can_afford(hp_data.cost)
	upgrade_damage_button.disabled = dmg_data == null \
		or not level_ok \
		or not _player.capacity.can_afford(dmg_data.cost)
	repair_button.disabled = _turret.health.is_full() \
		or not _player.capacity.can_afford(_turret.stats.capacity_drain_rate * delta)

func _handle_repair(delta: float) -> void:
	if not _repairing:
		return
	if _turret.health.is_full():
		_repairing = false
		_repair_accumulator = 0.0
		return
	var drain = _turret.stats.capacity_drain_rate * delta
	if not _player.capacity.can_afford(drain):
		_repairing = false
		_repair_accumulator = 0.0
		return
	_player.capacity.spend(drain)
	_repair_accumulator += _turret.stats.health_restore_rate * delta
	var to_heal := int(_repair_accumulator)
	if to_heal > 0:
		_turret.health.heal(to_heal)
		_repair_accumulator -= float(to_heal)

func _on_upgrade_health_pressed() -> void:
	if not _turret or not _player:
		return
	var data: TurretUpgrade = _turret.upgrader.health_upgrade_data()
	if not data:
		return
	_player.capacity.spend(data.cost)
	_turret.upgrader.apply_health_upgrade()
	_refresh()

func _on_upgrade_damage_pressed() -> void:
	if not _turret or not _player:
		return
	var data: TurretUpgrade = _turret.upgrader.damage_upgrade_data()
	if not data:
		return
	_player.capacity.spend(data.cost)
	_turret.upgrader.apply_damage_upgrade()
	_refresh()
