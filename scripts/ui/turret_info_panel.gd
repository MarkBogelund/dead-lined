extends Control
class_name TurretInfoPanel

@onready var level_label: Label = %LevelLabel
@onready var health_label: Label = %HealthLabel
@onready var damage_label: Label = %DamageLabel

var _turret: Node = null

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if not visible or not is_instance_valid(_turret):
		return
	_update_labels()

func open(turret: Node) -> void:
	if _turret:
		_disconnect_turret()
	_turret = turret
	_turret.died.connect(close)
	_update_labels()
	visible = true

func close() -> void:
	_disconnect_turret()
	visible = false

func _disconnect_turret() -> void:
	if not is_instance_valid(_turret):
		_turret = null
		return
	if _turret.died.is_connected(close):
		_turret.died.disconnect(close)
	_turret = null

func _update_labels() -> void:
	if not _turret:
		return
	level_label.text = "%d" % _turret.upgrader.level
	health_label.text = "HP: %d/%d" % [_turret.health.get_current_health(), _turret.health.max_health]
	damage_label.text = "DMG: %d" % _turret.get_damage_value()
