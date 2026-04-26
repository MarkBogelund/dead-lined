extends Node
class_name TurretUpgradeComponent

## Manages turret upgrade level.

var level := 1


func apply_health_upgrade() -> void:
	var turret := get_parent()
	level += 1
	turret.health.increase_max_health(turret.stats.health_upgrade_amount)


func apply_damage_upgrade() -> void:
	var turret := get_parent()
	level += 1
	turret.shoot.projectile_damage += turret.stats.damage_upgrade_amount
