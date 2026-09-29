extends Control
class_name TurretCard

## One turret icon in the radial shop. The owning ShopPanel decides which card is highlighted.

## Pixels the card slides outward, away from the shop center, at full pop.
@export var pop_distance := 8.0
## Keyed by the highlight/settle/reject clips: 0 = resting, 1 = fully popped out.
@export var pop_amount := 0.0:
	set = _set_pop_amount

const COLOR_UNAVAILABLE := Color(0.5, 0.5, 0.5, 0.8)

@onready var visual: Control = $Visual
@onready var icon: TextureRect = %Icon
@onready var animation_handler: AnimationHandler = $AnimationHandler

var _direction := Vector2.ZERO
var _rest_position := Vector2.ZERO

func _ready() -> void:
	_rest_position = visual.position
	animation_handler.configure_animation("settle", 0, false)
	animation_handler.configure_animation("highlight", 1, false)
	animation_handler.configure_animation("reject", 2, false)

## direction points from the shop center to this card and sets which way it pops out.
func populate(entry: TurretEntry, available: bool, direction: Vector2) -> void:
	icon.texture = entry.icon
	icon.self_modulate = Color.WHITE if available else COLOR_UNAVAILABLE
	_direction = direction
	# Gives the first highlight a previous clip to blend from.
	animation_handler.play_animation("settle")

func set_highlighted(highlighted: bool) -> void:
	animation_handler.play_animation("highlight" if highlighted else "settle")

func reject() -> void:
	animation_handler.restart_animation("reject")

func _set_pop_amount(value: float) -> void:
	pop_amount = value
	if is_node_ready():
		visual.position = _rest_position + _direction * pop_distance * pop_amount
