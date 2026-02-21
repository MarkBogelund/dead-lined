extends Node
class_name ShopManager

signal shop_system_enabled
signal shop_system_disabled

@onready var wave_manager: WaveManager = $"/root/Game/Systems/WaveManager"
@onready var shop_panel: ShopPanel = $"/root/Game/UI/ShopPanel"
@onready var turret_placer: TurretPlacer = $"./TurretPlacer"

var shop_station: ShopStation
var resource_manager: ResourceManager

func _ready() -> void:
	shop_station = get_tree().get_first_node_in_group("shop_stations")
	resource_manager = get_tree().get_first_node_in_group("resource_manager")
	
	turret_placer.turret_placed.connect(_on_turret_placed)
	
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
	if not resource_manager.can_buy(turret_entry.price):
		return
	
	turret_placer.start_placement(turret_entry)
	shop_panel.close()

func _on_turret_placed(turret_entry: TurretEntry):
	resource_manager.subtract_scrap(turret_entry.price)

func _on_build_phase_started() -> void:
	emit_signal("shop_system_enabled")

func _on_combat_phase_started(_wave: int) -> void:
	emit_signal("shop_system_disabled")
	turret_placer.cancel()
	shop_panel.close()
