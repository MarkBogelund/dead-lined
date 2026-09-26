extends Node
class_name ShopManager

signal shop_system_enabled
signal shop_system_disabled
signal turret_placement_started
signal turret_placement_ended
signal turret_bought(price: float)
signal turret_lost
signal turret_upgraded(cost: float)
signal turret_sold(refund: float)

@onready var wave_manager: WaveManager = %WaveManager
@onready var player: Player = %Player
@export var shop_panel: ShopPanel
@export var shop_station: ShopStation
@export var turret_entries: Array[TurretEntry] = []
@onready var turret_placer: TurretPlacer = $"./TurretPlacer"
@export var max_turrets: int = 6
var turrets_placed := 0

func _ready() -> void:
	turret_placer.turret_placed.connect(_on_turret_placed)
	turret_placer.placement_started.connect(_on_placement_started)
	turret_placer.placement_ended.connect(_on_placement_ended)

	shop_panel.turret_selected.connect(_on_turret_selected)

	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)

	_configure_shop_toggle.call_deferred()


func _configure_shop_toggle() -> void:
	shop_station.toggle_menu.open_fn = func() -> void: shop_panel.open(turret_entries, player.can_afford)
	shop_station.toggle_menu.close_fn = func() -> void: shop_panel.close()
	shop_station.toggle_menu.menu_control = shop_panel


func _on_turret_selected(turret_entry: TurretEntry) -> void:
	if not player.can_afford(turret_entry.price):
		return
	if turrets_placed >= max_turrets:
		return

	turret_placer.start_placement(turret_entry)
	shop_station.toggle_menu.close()

func _on_turret_placed(placed: Node, turret_entry: TurretEntry) -> void:
	var turret := placed as TurretBase
	turrets_placed += 1
	turret.set_purchase_price(turret_entry.price)
	turret.set_exclusion_radius(turret_entry.exclusion_radius)
	turret_bought.emit(turret_entry.price)
	turret.died.connect(_on_turret_destroyed)
	turret.sold.connect(_on_turret_sold)
	turret.upgrade_purchased.connect(turret_upgraded.emit)

func _on_turret_destroyed() -> void:
	turrets_placed -= 1
	turret_lost.emit()

func _on_turret_sold(refund: float) -> void:
	turrets_placed -= 1
	turret_sold.emit(refund)

func _on_placement_started() -> void:
	turret_placement_started.emit()

func _on_placement_ended() -> void:
	turret_placement_ended.emit()

func _on_build_phase_started() -> void:
	shop_system_enabled.emit()

func _on_combat_phase_started(_wave: int) -> void:
	shop_system_disabled.emit()
	turret_placer.cancel()
