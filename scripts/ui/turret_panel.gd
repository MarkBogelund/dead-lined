extends Control
class_name TurretPanel

## Per-turret action panel: upgrade/sell hold buttons (level and health live in HealthUIComponent).
## Emits requests only; the turret performs upgrades and sales.

signal upgrade_requested
signal sell_requested

@onready var actions: Control = %Actions
@onready var upgrade_button: HoldButton = %UpgradeButton
@onready var sell_button: HoldButton = %SellButton
@onready var upgrade_label: Label = %UpgradeLabel
@onready var sell_label: Label = %SellLabel

var _turret: TurretBase

func _ready() -> void:
	visible = false
	upgrade_button.hold_completed.connect(upgrade_requested.emit)
	sell_button.hold_completed.connect(sell_requested.emit)

func _process(_delta: float) -> void:
	if visible:
		_refresh()

func open(turret: TurretBase) -> void:
	_turret = turret
	_refresh()
	visible = true

func close() -> void:
	visible = false

func set_actions_visible(value: bool) -> void:
	actions.visible = value

func _refresh() -> void:
	if _turret.is_max_level():
		upgrade_label.text = "MAX"
		upgrade_button.disabled = true
	else:
		upgrade_label.text = "%d" % int(_turret.get_upgrade_cost())
		upgrade_button.disabled = not _turret.can_upgrade()
	sell_label.text = "%d" % int(_turret.get_sell_value())
	sell_button.disabled = not _turret.can_sell()
