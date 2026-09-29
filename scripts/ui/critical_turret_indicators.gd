extends Control
class_name CriticalTurretIndicators

## Arrows warning that a turret is critically damaged and pointing the way to it. Each arrow sits next to its
## turret on the player's side, and only while the player is far enough away.

@export var arrow_texture: Texture2D
@export var arrow_shader: Shader
@export var arrow_color := Color(1.0, 1.0, 1.0, 1.0)
## Distance in pixels the arrow keeps from its turret, toward the player.
@export_range(0.0, 256.0, 1.0) var turret_offset := 48.0
## Distance in pixels from the player at which a critical turret gets an arrow.
@export_range(0.0, 1000.0, 10.0) var min_player_distance := 240.0
@export_range(0.1, 4.0, 0.05) var pulse_period := 0.8
@export_range(0.0, 1.0, 0.05) var pulse_min_alpha := 0.35

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var shop_manager: ShopManager = get_tree().get_first_node_in_group("shop_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")

var _arrows: Dictionary[TurretBase, PixelRotatedSprite] = {}
var _pulse_time := 0.0

func _ready() -> void:
	if not arrow_texture:
		push_error("CriticalTurretIndicators needs arrow_texture assigned in the scene")
	if not arrow_shader:
		push_error("CriticalTurretIndicators needs arrow_shader assigned in the scene")
	if shop_manager:
		shop_manager.turret_bought.connect(_on_turret_bought)
	else:
		push_error("CriticalTurretIndicators needs a node in the shop_manager group")
	if game_over_manager:
		game_over_manager.game_over.connect(_on_game_over)
	_track_turrets()

func _on_turret_bought(_price: float) -> void:
	_track_turrets()

## Placed turrets are already in the group by the time the purchase is reported.
func _track_turrets() -> void:
	for turret: TurretBase in get_tree().get_nodes_in_group("turrets"):
		if _arrows.has(turret):
			continue
		var arrow := PixelRotatedSprite.new()
		arrow.pixel_shader = arrow_shader
		arrow.texture = arrow_texture
		arrow.color = arrow_color
		add_child(arrow)
		_arrows[turret] = arrow
		turret.tree_exiting.connect(_on_turret_removed.bind(turret))

func _on_turret_removed(turret: TurretBase) -> void:
	var arrow: PixelRotatedSprite = _arrows.get(turret)
	if arrow:
		arrow.queue_free()
	_arrows.erase(turret)

func _on_game_over() -> void:
	set_process(false)
	for arrow: PixelRotatedSprite in _arrows.values():
		arrow.fade_to(0.0)

func _process(delta: float) -> void:
	if _arrows.is_empty():
		return
	_pulse_time += delta
	modulate.a = lerpf(pulse_min_alpha, 1.0, 0.5 + 0.5 * sin(_pulse_time * TAU / pulse_period))
	var canvas_transform := get_viewport().get_canvas_transform()
	for turret: TurretBase in _arrows:
		_update_arrow(turret, _arrows[turret], canvas_transform)

func _update_arrow(turret: TurretBase, arrow: PixelRotatedSprite, canvas_transform: Transform2D) -> void:
	if not turret.is_critical() or player == null:
		arrow.fade_to(0.0)
		return
	var to_player := player.global_position - turret.global_position
	if to_player.length() < min_player_distance:
		arrow.fade_to(0.0)
		return
	var world_position := turret.global_position + to_player.normalized() * turret_offset
	arrow.position = (canvas_transform * world_position).round()
	arrow.point_at((-to_player).angle())
	arrow.fade_to(1.0)
