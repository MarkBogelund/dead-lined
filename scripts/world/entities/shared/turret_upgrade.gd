extends Node
class_name TurretUpgradeComponent

## Manages turret upgrade level and gates the upgrade menu via wave phase.
## Open/close triggering is handled by TurretUpgradeToggle (ToggleMenuComponent).

@export var upgrade_toggle: ToggleMenuComponent

var level := 1


func _ready() -> void:
	var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
	wave_manager.build_phase_started.connect(func():
		if not upgrade_toggle:
			return
		upgrade_toggle.enabled = true
		if upgrade_toggle.interaction_zone and upgrade_toggle.interaction_zone.is_player_in_range():
			MenuManager.request_open(&"upgrade", get_parent())
	)
	wave_manager.combat_phase_started.connect(func(_i):
		if upgrade_toggle: upgrade_toggle.enabled = false
	)


func apply_health_upgrade() -> void:
	var turret := get_parent()
	level += 1
	turret.health.increase_max_health(turret.stats.health_upgrade_amount)


func apply_damage_upgrade() -> void:
	var turret := get_parent()
	level += 1
	turret.shoot.projectile_damage += turret.stats.damage_upgrade_amount
