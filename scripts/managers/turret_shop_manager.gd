extends Node
class_name TurretShopManager

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var turret_shop_ui: TurretShopUI = $TurretShopUI
@onready var turret_placement_manager: TurretPlacementManager = $TurretPlacementManager
@onready var turret_spawner: TurretSpawner = $"../TurretSpawner"

func _ready() -> void:
	turret_shop_ui.visible = false
	
	turret_spawner.shop_opened.connect(_on_shop_opened)
	turret_spawner.shop_closed.connect(_on_shop_closed)
	
	turret_shop_ui.turret_selected.connect(_on_turret_selected)
	
	turret_placement_manager.turret_placed.connect(_on_turret_placed)
	
	turret_placement_manager.turret_placement_cancelled.connect(_on_turret_cancelled)
	
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)

func _on_shop_opened():
	turret_shop_ui.open()

func _on_shop_closed():
	turret_shop_ui.close()

func _on_turret_selected(turret_entry: TurretEntry):
	turret_placement_manager.start_placement(turret_entry)
	turret_shop_ui.close()
	turret_spawner.close_shop()

func _on_turret_placed(turret_entry: TurretEntry):
	print("Turret purchased: " + turret_entry.name)
	
func _on_turret_cancelled():
	print("Turret cancelled")
	
func _on_build_phase_started() -> void:
	turret_spawner.build_phase_started()

func _on_combat_phase_started(_wave: int) -> void:
	turret_spawner.combat_phase_started()
	turret_placement_manager.cancel()
	turret_shop_ui.close()
