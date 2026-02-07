extends Node
class_name TurretShopManager

@onready var turret_shop_ui: TurretShopUI = $TurretShopUI
@onready var turret_placement_manager: TurretPlacementManager = $TurretPlacementManager
@onready var player: CharacterBody2D = $"../Player"

var active_spawner: Node = null

func _ready() -> void:
	turret_shop_ui.visible = false
	turret_shop_ui.turret_selected.connect(_on_turret_selected)

	var spawners := get_tree().get_nodes_in_group("turret_spawners")
	for spawner in spawners:
		spawner.shop_opened.connect(_on_shop_opened.bind(spawner))
		spawner.shop_closed.connect(_on_shop_closed.bind(spawner))

func _on_shop_opened(spawner: Node) -> void:
	active_spawner = spawner
	turret_shop_ui.visible = true

func _on_shop_closed(spawner: Node) -> void:
	if spawner != active_spawner:
		return

	active_spawner = null
	turret_shop_ui.visible = false

func _on_turret_selected(turret_scene: PackedScene) -> void:
	turret_placement_manager.start_placement(turret_scene, player.position)

	print("Turret selected")

	turret_shop_ui.visible = false
	if active_spawner:
		active_spawner.close_menu()
