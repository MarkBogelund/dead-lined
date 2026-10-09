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
signal turret_unlocked(entry: TurretEntry)

@onready var wave_manager: WaveManager = %WaveManager
@onready var player: Player = %Player
@export var shop_panel: ShopPanel
@export var shop_station: ShopStation
## Every turret in the game; the run roster decides which of them the shop offers.
@export var turret_entries: Array[TurretEntry] = []
@export var roster_settings: ShopRosterSettings
## Where dropped blueprints are added.
@export var pickup_container: Node
@onready var turret_placer: TurretPlacer = $"./TurretPlacer"
@export var max_turrets: int = 6
var turrets_placed := 0

var _roster: TurretRoster
var _rng := RandomNumberGenerator.new()
var _blueprints_dropped_this_wave := 0
## Dropped but uncollected; each reserves one locked turret so no blueprint is ever empty.
var _pending_blueprints := 0
var _pending_unlock_notifications: Array[TurretEntry] = []

func _ready() -> void:
	assert(roster_settings and roster_settings.blueprint_scene and pickup_container, "ShopManager requires roster settings with a blueprint scene, and a pickup container")
	for turret_entry: TurretEntry in turret_entries:
		turret_entry.generate_icon()
	if roster_settings.random_seed != 0:
		_rng.seed = roster_settings.random_seed
	else:
		_rng.randomize()
	_roster = TurretRoster.new(turret_entries, roster_settings.starting_counts, _rng)

	turret_placer.turret_placed.connect(_on_turret_placed)
	turret_placer.placement_started.connect(_on_placement_started)
	turret_placer.placement_ended.connect(_on_placement_ended)

	shop_panel.turret_selected.connect(_on_turret_selected)
	shop_panel.close_requested.connect(func() -> void: shop_station.toggle_menu.close())

	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)

	_configure_shop_toggle.call_deferred()


func _configure_shop_toggle() -> void:
	shop_station.toggle_menu.open_fn = _open_shop_panel
	shop_station.toggle_menu.close_fn = func() -> void: shop_panel.close()
	shop_station.toggle_menu.menu_control = shop_panel

func _open_shop_panel() -> void:
	shop_panel.open(_roster.unlocked, player.can_afford, turrets_placed >= max_turrets)

func get_unlocked_entries() -> Array[TurretEntry]:
	return _roster.unlocked

## Connected to the boss blueprint drop request; drops at most max_blueprints_per_wave while turrets remain locked.
func spawn_blueprint(world_position: Vector2) -> void:
	if _blueprints_dropped_this_wave >= roster_settings.max_blueprints_per_wave:
		return
	if _roster.locked_count() <= _pending_blueprints:
		return
	_blueprints_dropped_this_wave += 1
	_pending_blueprints += 1
	var blueprint := roster_settings.blueprint_scene.instantiate() as Blueprint
	blueprint.collected.connect(_on_blueprint_collected, CONNECT_ONE_SHOT)
	pickup_container.add_child(blueprint)
	blueprint.global_position = world_position
	blueprint.launch(Vector2.from_angle(_rng.randf() * TAU) * 80.0)

func _on_blueprint_collected() -> void:
	_pending_blueprints -= 1
	var entry := _roster.unlock_random()
	if not entry:
		return
	if wave_manager.is_build_phase():
		turret_unlocked.emit(entry)
	else:
		_pending_unlock_notifications.append(entry)
	if shop_panel.is_open():
		_open_shop_panel()


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
	turret.set_panel_colors(turret_entry.outline_start_color, turret_entry.outline_end_color)
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
	for entry: TurretEntry in _pending_unlock_notifications:
		turret_unlocked.emit(entry)
	_pending_unlock_notifications.clear()

func _on_combat_phase_started(_wave: int) -> void:
	_blueprints_dropped_this_wave = 0
	shop_system_disabled.emit()
	turret_placer.cancel()
