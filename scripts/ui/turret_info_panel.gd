extends Control
class_name TurretInfoPanel

@onready var background: PanelContainer = $Background
@onready var level_label: Label = $Background/VBox/LevelLabel
@onready var health_label: Label = $Background/VBox/HealthLabel
@onready var damage_label: Label = $Background/VBox/DamageLabel

var _turret: Turret = null

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if not visible or not is_instance_valid(_turret):
		return
	var screen_pos := get_viewport().get_canvas_transform() * _turret.global_position
	background.position = screen_pos + Vector2(-background.size.x * 0.5, -background.size.y - 20.0)
	_update_labels()

func open(turret: Turret) -> void:
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
	level_label.text = "%d" % _turret.level
	health_label.text = "HP: %d/%d" % [_turret.health.get_current_health(), _turret.health.max_health]
	damage_label.text = "DMG: %d" % _turret.shoot.projectile_damage
