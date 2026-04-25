extends Node
class_name TurretUpgradeComponent

## Self-contained upgrade component. Drop onto any turret scene.
## Parent turret must expose: stats (SeekerStats), health (HealthComponent), shoot (ShootComponent), is_dead().
## In the parent's _ready, wire:
##   interaction_range.player_entered.connect(upgrader.on_player_entered)
##   interaction_range.player_exited.connect(upgrader.on_player_exited)

signal info_panel_requested(turret: Node)
signal info_panel_dismissed
signal upgrade_panel_requested(turret: Node)
signal upgrade_panel_dismissed

var level := 1
var _is_build_phase := true

func _ready() -> void:
	var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
	wave_manager.build_phase_started.connect(func(): _is_build_phase = true)
	wave_manager.combat_phase_started.connect(func(_i): _is_build_phase = false)

func on_player_entered() -> void:
	var turret := get_parent()
	if turret.is_dead():
		return
	info_panel_requested.emit(turret)
	if _is_build_phase:
		upgrade_panel_requested.emit(turret)

func on_player_exited() -> void:
	info_panel_dismissed.emit()
	upgrade_panel_dismissed.emit()

func apply_health_upgrade() -> void:
	var turret := get_parent()
	level += 1
	turret.health.increase_max_health(turret.stats.health_upgrade_amount)

func apply_damage_upgrade() -> void:
	var turret := get_parent()
	level += 1
	turret.shoot.projectile_damage += turret.stats.damage_upgrade_amount
