extends Control
class_name TurretSlot

signal selected

@onready var background: NinePatchRect = %Background
@onready var name_label: Label = %NameLabel
@onready var buy_button: TextureButton = %BuyButton
@onready var price_label: Label = %PriceLabel
@onready var price_icon: TextureRect = %PriceIcon

const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_HOVER := Color(1.25, 1.2, 1.0, 1.0)
const COLOR_PRESSED := Color(0.8, 0.8, 0.75, 1.0)
const COLOR_DIMMED := Color(0.5, 0.5, 0.5, 0.8)

func _ready() -> void:
	buy_button.pressed.connect(func() -> void: selected.emit())
	buy_button.mouse_entered.connect(_on_hover_enter)
	buy_button.mouse_exited.connect(_on_hover_exit)
	buy_button.button_down.connect(_on_press_down)
	buy_button.button_up.connect(_on_press_up)

## Sets only the data shown in the slot: name, icon, price, and affordability tint.
## All layout and visual styling stays as designed in the scene.
func populate(entry: TurretEntry, can_afford: bool) -> void:
	name_label.text = entry.name
	buy_button.texture_normal = entry.icon
	buy_button.texture_hover = entry.icon
	buy_button.texture_pressed = entry.icon
	buy_button.texture_disabled = entry.icon
	buy_button.disabled = not can_afford
	price_label.text = str(entry.price)
	var tint := COLOR_NORMAL if can_afford else COLOR_DIMMED
	name_label.modulate = tint
	price_label.modulate = tint
	price_icon.modulate = tint

func _on_hover_enter() -> void:
	if buy_button.disabled:
		return
	_tween_bg(COLOR_HOVER, 0.08)

func _on_hover_exit() -> void:
	_tween_bg(COLOR_NORMAL, 0.12)

func _on_press_down() -> void:
	if buy_button.disabled:
		return
	_tween_bg(COLOR_PRESSED, 0.05)
	var t := create_tween()
	t.tween_property(buy_button, "scale", Vector2(0.88, 0.88), 0.06).set_trans(Tween.TRANS_CUBIC)

func _on_press_up() -> void:
	_tween_bg(COLOR_HOVER, 0.08)
	var t := create_tween()
	t.tween_property(buy_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _tween_bg(target: Color, duration: float) -> void:
	var t := create_tween()
	t.tween_property(background, "modulate", target, duration)
