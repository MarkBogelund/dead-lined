extends Node
class_name ShopManager

signal shop_system_enabled
signal shop_system_disabled
signal turret_placement_started
signal turret_placement_ended

@onready var wave_manager: WaveManager = %WaveManager
@onready var game_over_manager: GameOverManager = %GameOverManager
@export var shop_panel: ShopPanel
@export var shop_station: ShopStation
@onready var resource_manager: ResourceManager = %ResourceManager
@onready var turret_placer: TurretPlacer = $"./TurretPlacer"
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
	
	game_over_manager.game_over.connect(_on_game_over)

func _on_game_over() -> void:
	StatsManager.set_turrets(turrets_placed)

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
	turrets_placed += 1

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
