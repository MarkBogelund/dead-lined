extends Control
class_name UpgradePanel

@onready var upgrade_health_button: BaseButton = %UpgradeHealthButton
@onready var upgrade_damage_button: BaseButton = %UpgradeDamageButton
# @onready var repair_button: BaseButton = %RepairButton
@onready var upgrade_health_label: Label = %UpgradeHealthLabel
@onready var upgrade_damage_label: Label = %UpgradeDamageLabel

var _turret: Node = null
var _player: Player = null
var _wave_manager: WaveManager = null
var _repairing := false

func _ready() -> void:
	visible = false
	upgrade_health_button.pressed.connect(_on_upgrade_health_pressed)
	upgrade_damage_button.pressed.connect(_on_upgrade_damage_pressed)
	# repair_button.button_down.connect(_on_repair_button_down)
	# repair_button.button_up.connect(_on_repair_button_up)

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
	if _repairing and is_instance_valid(_turret):
		_turret.repair.deactivate()
	_repairing = false
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

func _on_repair_button_down() -> void:
	if not is_instance_valid(_turret):
		return
	_repairing = true
	_turret.repair.activate()

func _on_repair_button_up() -> void:
	_repairing = false
	if is_instance_valid(_turret):
		_turret.repair.deactivate()

func _refresh() -> void:
	if not _turret or not _wave_manager:
		return
	var hp_data: TurretUpgrade = _turret.upgrader.health_upgrade_data()
	var dmg_data: TurretUpgrade = _turret.upgrader.damage_upgrade_data()
	upgrade_health_label.text = "%d" % int(hp_data.cost) if hp_data else "MAX"
	upgrade_damage_label.text = "%d" % int(dmg_data.cost) if dmg_data else "MAX"

func _update_button_states(delta: float) -> void:
	var hp_data: TurretUpgrade = _turret.upgrader.health_upgrade_data()
	var dmg_data: TurretUpgrade = _turret.upgrader.damage_upgrade_data()
	var level_ok: bool = _turret.upgrader.level <= _wave_manager.current_wave
	upgrade_health_button.disabled = hp_data == null \
		or not level_ok \
		or not _player.capacity.can_afford(hp_data.cost)
	upgrade_damage_button.disabled = dmg_data == null \
		or not level_ok \
		or not _player.capacity.can_afford(dmg_data.cost)
	# repair_button.disabled = _turret.health.is_full() \
	# 	or not _player.capacity.can_afford(_turret.stats.capacity_drain_rate * delta)

func _handle_repair(delta: float) -> void:
	if not _repairing:
		return
	if _turret.health.is_full() or not _player.capacity.can_afford(_turret.stats.capacity_drain_rate * delta):
		_repairing = false
		_turret.repair.deactivate()
		return
	_turret.repair.try_repair(delta, _player.capacity.get_current())

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
