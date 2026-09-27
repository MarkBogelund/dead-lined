extends Control
class_name OffscreenTurretIndicators

## Screen-edge arrows pointing at critically damaged turrets that are currently off-camera.

@export var arrow_texture: Texture2D = preload("res://assets/sprites/ui/turret_critical_arrow.png")
@export var arrow_color := Color(1.0, 1.0, 1.0, 1.0)
## How far the arrows sit from the screen edge toward the centre, as a fraction of the half-screen.
@export_range(0.0, 0.9, 0.01) var center_inset := 0.2
## Inset on the on-screen test: arrows already appear while the turret is this close to the screen edge.
@export_range(0.0, 160.0, 1.0) var visible_margin := 80.0
@export_range(0.1, 4.0, 0.05) var pulse_period := 0.8
@export_range(0.0, 1.0, 0.05) var pulse_min_alpha := 0.35

@onready var shop_manager: ShopManager = get_tree().get_first_node_in_group("shop_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")

var _arrows: Dictionary[TurretBase, PixelRotatedSprite] = {}
var _pulse_time := 0.0

func _ready() -> void:
	if shop_manager:
		shop_manager.turret_bought.connect(_on_turret_bought)
	else:
		push_error("OffscreenTurretIndicators needs a node in the shop_manager group")
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
	var rect := get_viewport_rect()
	var canvas_transform := get_viewport().get_canvas_transform()
	for turret: TurretBase in _arrows:
		_update_arrow(turret, _arrows[turret], rect, canvas_transform)

func _update_arrow(turret: TurretBase, arrow: PixelRotatedSprite, rect: Rect2, canvas_transform: Transform2D) -> void:
	var screen_position := canvas_transform * turret.global_position
	if not turret.is_critical() or rect.grow(-visible_margin).has_point(screen_position):
		arrow.fade_to(0.0)
		return
	var center := rect.size * 0.5
	var offset := screen_position - center
	if offset.is_zero_approx():
		return
	# Push the arrow out along the turret's direction until it hits the inset screen border.
	var half := center * (1.0 - center_inset)
	var reach := INF
	if not is_zero_approx(offset.x):
		reach = half.x / absf(offset.x)
	if not is_zero_approx(offset.y):
		reach = minf(reach, half.y / absf(offset.y))
	arrow.position = (center + offset * reach).round()
	arrow.point_at(offset.angle())
	arrow.fade_to(1.0)
