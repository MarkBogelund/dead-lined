extends Control
class_name UpgradePanel

@onready var background: PanelContainer = $Background
@onready var name_label: Label = $Background/VBox/NameLabel
@onready var level_label: Label = $Background/VBox/LevelLabel
@onready var upgrade_health_button: Button = $Background/VBox/UpgradeHealthButton
@onready var upgrade_damage_button: Button = $Background/VBox/UpgradeDamageButton

var _turret: Turret = null
var _player: Player = null
var _wave_manager: WaveManager = null

func _ready() -> void:
	visible = false
	upgrade_health_button.pressed.connect(_on_upgrade_health_pressed)
	upgrade_damage_button.pressed.connect(_on_upgrade_damage_pressed)

func _process(_delta: float) -> void:
	if not visible or not is_instance_valid(_turret):
		return
	var screen_pos := get_viewport().get_canvas_transform() * _turret.global_position
	background.position = screen_pos + Vector2(-background.size.x * 0.5, -background.size.y - 20.0)

func open(turret: Turret, player: Player, wave_manager: WaveManager) -> void:
	if _turret:
		_disconnect_turret()
	_turret = turret
	_player = player
	_wave_manager = wave_manager
	_turret.interaction_range.player_exited.connect(close)
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
		return
	if _turret.interaction_range.player_exited.is_connected(close):
		_turret.interaction_range.player_exited.disconnect(close)
	if _turret.died.is_connected(close):
		_turret.died.disconnect(close)
	_turret = null
	_player = null
	_wave_manager = null

func _refresh() -> void:
	if not _turret or not _player or not _wave_manager:
		return
	name_label.text = _turret.stats.display_name
	level_label.text = "%d" % _turret.level
	var cost := _turret.stats.upgrade_cost
	upgrade_health_button.text = "HP: %d  (+%d cap)" % [_turret.health.max_health, int(cost)]
	upgrade_damage_button.text = "DMG: %d  (+%d cap)" % [_turret.shoot.projectile_damage, int(cost)]
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
