extends Node
class_name TurretUpgradeComponent

## Tracks the turret's level along a single upgrade track. Level 1 = no upgrades applied.

signal upgraded(upgrade: TurretUpgrade)

var level := 1
var _upgrades: Array[TurretUpgrade] = []

func initialize(upgrades: Array[TurretUpgrade]) -> void:
	_upgrades = upgrades
	level = 1

func next_upgrade() -> TurretUpgrade:
	if is_max_level():
		return null
	return _upgrades[level - 1]

func is_max_level() -> bool:
	return level - 1 >= _upgrades.size()

func apply_next() -> void:
	var upgrade := next_upgrade()
	if not upgrade:
		return
	level += 1
	upgraded.emit(upgrade)
