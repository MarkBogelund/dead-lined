extends Control
class_name TurretInfoPanel

## Center panel of the radial shop: shows the highlighted turret's name, price and stats.

const COLOR_UNAVAILABLE := Color(0.6, 0.6, 0.6, 1.0)

## Keyed by the refresh clip: blend from the previous turret's outline colors (0) to the highlighted one's (1).
@export_range(0.0, 1.0, 0.01) var outline_fill := 1.0:
	set = _set_outline_fill

@onready var name_label: Label = %NameLabel
@onready var price_label: Label = %PriceLabel
@onready var stats_view: TurretStatsView = %TurretStatsView
@onready var limit_label: Label = %LimitLabel
@onready var content: Control = %Content
@onready var animation_handler: AnimationHandler = $AnimationHandler
@onready var _outlines: Array[CanvasItem] = [%PanelOutline, %StatsOutline]

var _from_start := Color.WHITE
var _from_end := Color.WHITE
var _to_start := Color.WHITE
var _to_end := Color.WHITE

func _ready() -> void:
	animation_handler.configure_animation("refresh", 0, false)
	# The outline material is shared with the HUD, so each outline gets its own copy.
	for outline in _outlines:
		outline.material = outline.material.duplicate()
	var shader_material := _outlines[0].material as ShaderMaterial
	_to_start = shader_material.get_shader_parameter("start_color")
	_to_end = shader_material.get_shader_parameter("end_color")

func show_entry(entry: TurretEntry, can_afford: bool, limit_reached: bool) -> void:
	_set_outline_colors(entry.outline_start_color, entry.outline_end_color)
	name_label.text = entry.name
	price_label.text = str(entry.price)
	stats_view.show_stats(TurretStatValues.from_stats(entry.stats))
	price_label.self_modulate = Color.WHITE if can_afford else Color.RED
	content.modulate = Color.WHITE if can_afford and not limit_reached else COLOR_UNAVAILABLE
	limit_label.visible = limit_reached
	animation_handler.restart_animation("refresh")

## Starts a blend from the colors currently shown to the new ones.
func _set_outline_colors(start_color: Color, end_color: Color) -> void:
	_from_start = _from_start.lerp(_to_start, outline_fill)
	_from_end = _from_end.lerp(_to_end, outline_fill)
	_to_start = start_color
	_to_end = end_color
	# AnimationHandler starts clips a frame later; without this the new colors would flash fully.
	outline_fill = 0.0

func _set_outline_fill(value: float) -> void:
	outline_fill = value
	if not is_node_ready():
		return
	for outline in _outlines:
		var shader_material := outline.material as ShaderMaterial
		shader_material.set_shader_parameter("start_color", _from_start.lerp(_to_start, value))
		shader_material.set_shader_parameter("end_color", _from_end.lerp(_to_end, value))
