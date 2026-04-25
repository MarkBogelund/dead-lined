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
@onready var turret_placer: TurretPlacer = $"./TurretPlacer"
@export var max_turrets: int = 6
@export var upgrade_panel: UpgradePanel
@export var turret_info_panel: TurretInfoPanel
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
	if upgrade_panel:
		upgrade_panel.close()
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
	if turret.has_signal("upgrade_requested"):
		turret.upgrade_requested.connect(_on_upgrade_requested)
	if turret.has_signal("upgrade_dismissed"):
		turret.upgrade_dismissed.connect(func(): upgrade_panel.close())
	if turret.has_signal("info_requested"):
		turret.info_requested.connect(_on_info_requested)
	if turret.has_signal("info_dismissed"):
		turret.info_dismissed.connect(_on_info_dismissed)

func _on_turret_destroyed() -> void:
	turrets_placed -= 1
	turret_lost.emit()

func _on_upgrade_requested(turret: Turret) -> void:
	if not upgrade_panel:
		return
	shop_panel.close()
	upgrade_panel.open(turret, player, wave_manager, turret_info_panel)

func _on_info_requested(turret: Turret) -> void:
	if turret_info_panel:
		turret_info_panel.open(turret)

func _on_info_dismissed() -> void:
	if turret_info_panel:
		turret_info_panel.close()
	if upgrade_panel:
		upgrade_panel.close()

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
