extends Node
class_name ShopSystem

var wave_manager: WaveManager
var player: Player
var shop_panel: ShopPanel
var turret_placer: TurretPlacer
var shop_station: ShopStation
var resource_manager: ResourceManager

func _ready() -> void:
	# Wait one frame to ensure all siblings have added themselves to groups
	await get_tree().process_frame
	
	wave_manager = get_tree().get_first_node_in_group("wave_manager")
	player = get_tree().get_first_node_in_group("player")
	shop_panel = get_tree().get_first_node_in_group("shop_panel")
	turret_placer = get_tree().get_first_node_in_group("turret_placer")
	shop_station = get_tree().get_first_node_in_group("shop_stations")
	resource_manager = get_tree().get_first_node_in_group("resource_manager")
	
	if shop_panel:
		shop_panel.visible = false
	
	if turret_placer:
		turret_placer.player = player
	
	if shop_station:
		shop_station.shop_opened.connect(_on_shop_opened)
		shop_station.shop_closed.connect(_on_shop_closed)
	
	if shop_panel:
		shop_panel.turret_selected.connect(_on_turret_selected)
	
	if turret_placer:
		turret_placer.turret_placed.connect(_on_turret_placed)
		turret_placer.turret_placement_cancelled.connect(_on_turret_cancelled)
		turret_placer.placement_started.connect(_on_placement_started)
		turret_placer.placement_ended.connect(_on_placement_ended)
	
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)

func _on_shop_opened():
	if shop_panel:
		shop_panel.open()

func _on_shop_closed():
	if shop_panel:
		shop_panel.close()

func _on_turret_selected(turret_entry: TurretEntry):
	if resource_manager.scrap_amount < turret_entry.price:
		print("Not enough scrap")
		return
	
	if turret_placer:
		turret_placer.start_placement(turret_entry)
	if shop_panel:
		shop_panel.close()
	if shop_station:
		shop_station.close_shop()

func _on_turret_placed(turret_entry: TurretEntry):
	print("Turret purchased: " + turret_entry.name)
	resource_manager.scrap_amount -= turret_entry.price
	
func _on_turret_cancelled():
	print("Turret cancelled")

func _on_placement_started():
	if player:
		player.set_shooting_enabled(false)
		player.set_slashing_enabled(false)

func _on_placement_ended():
	if player:
		player.set_shooting_enabled(true)
		player.set_slashing_enabled(true)
	
func _on_build_phase_started() -> void:
	if shop_station:
		shop_station.enable()

func _on_combat_phase_started(_wave: int) -> void:
	if shop_station:
		shop_station.disable()
	if turret_placer:
		turret_placer.cancel()
	if shop_panel:
		shop_panel.close()
