extends Node
class_name ShopManager

signal shop_system_enabled
signal shop_system_disabled
signal turret_placement_started
signal turret_placement_ended
signal turret_bought(price: float)
signal turret_lost

@onready var wave_manager: WaveManager = %WaveManager
@onready var player: Player = %Player
@export var shop_panel: ShopPanel
@export var shop_station: ShopStation
@export var turret_info_panel: TurretInfoPanel
@export var upgrade_panel: UpgradePanel
@onready var turret_placer: TurretPlacer = $"./TurretPlacer"
@export var max_turrets: int = 6
var turrets_placed := 0

func _ready() -> void:
	turret_placer.turret_placed.connect(_on_turret_placed)
	turret_placer.placement_started.connect(_on_placement_started)
	turret_placer.placement_ended.connect(_on_placement_ended)
	
	shop_station.station_opened.connect(_on_station_interacted)
	shop_station.station_closed.connect(_on_station_closed)
	
	shop_panel.turret_selected.connect(_on_turret_selected)
	
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	
func _on_station_interacted():
	shop_panel.open()

func _on_station_closed():
	shop_panel.close()

func _on_turret_selected(turret_entry: TurretEntry):
	if not player.can_afford(turret_entry.price):
		return
	if turrets_placed >= max_turrets:
		return

	turret_placer.start_placement(turret_entry)
	shop_panel.close()

func _on_turret_placed(turret: Node, turret_entry: TurretEntry):
	turrets_placed += 1
	turret_bought.emit(turret_entry.price)
	if turret.has_signal("died"):
		turret.died.connect(_on_turret_destroyed)
	if turret.has_node("TurretUpgradeComponent"):
		var upgrader: TurretUpgradeComponent = turret.get_node("TurretUpgradeComponent")
		upgrader.info_panel_requested.connect(_on_info_panel_requested)
		upgrader.info_panel_dismissed.connect(_on_info_panel_dismissed)
		upgrader.upgrade_panel_requested.connect(_on_upgrade_panel_requested)
		upgrader.upgrade_panel_dismissed.connect(func(): upgrade_panel.close())

func _on_turret_destroyed() -> void:
	turrets_placed -= 1
	turret_lost.emit()

func _on_placement_started() -> void:
	emit_signal("turret_placement_started")

func _on_placement_ended() -> void:
	emit_signal("turret_placement_ended")

func _on_build_phase_started() -> void:
	emit_signal("shop_system_enabled")

func _on_combat_phase_started(_wave: int) -> void:
	emit_signal("shop_system_disabled")
	turret_placer.cancel()
	shop_panel.close()
	if upgrade_panel:
		upgrade_panel.close()

func _on_info_panel_requested(turret: Node) -> void:
	if turret_info_panel:
		turret_info_panel.open(turret)

func _on_info_panel_dismissed() -> void:
	if turret_info_panel:
		turret_info_panel.close()
	if upgrade_panel:
		upgrade_panel.close()

func _on_upgrade_panel_requested(turret: Node) -> void:
	if not upgrade_panel or not turret_info_panel:
		return
	shop_panel.close()
	upgrade_panel.open(turret, player, wave_manager, turret_info_panel)
