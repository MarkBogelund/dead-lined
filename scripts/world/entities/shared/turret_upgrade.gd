extends Node
class_name TurretUpgradeComponent

## Manages independent health and damage upgrade tracks with a shared level counter.
## level increments on every upgrade regardless of type.
## Wave cap check uses level.

var level := 1
var _health_index := 0
var _damage_index := 0


## Returns the next health upgrade, or null if fully upgraded.
func health_upgrade_data() -> TurretUpgrade:
	var upgrades: Array = get_parent().stats.health_upgrades
	if _health_index >= upgrades.size():
		return null
	return upgrades[_health_index]


## Returns the next damage upgrade, or null if fully upgraded.
func damage_upgrade_data() -> TurretUpgrade:
	var upgrades: Array = get_parent().stats.damage_upgrades
	if _damage_index >= upgrades.size():
		return null
	return upgrades[_damage_index]


func apply_health_upgrade() -> void:
	var data := health_upgrade_data()
	if not data:
		return
	var turret := get_parent()
	level += 1
	_health_index += 1
	turret.health.increase_max_health(data.value)
	turret.health.restore_to_max()


func apply_damage_upgrade() -> void:
	var data := damage_upgrade_data()
	if not data:
		return
	var turret := get_parent()
	level += 1
	_damage_index += 1
	turret.shoot.projectile_damage += data.value
