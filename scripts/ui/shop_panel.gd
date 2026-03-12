extends Control
class_name ShopPanel

signal turret_selected(turret_entry: TurretEntry)

@onready var price: Label = $Background/PriceLabel

@export var turret_entry: TurretEntry

func _ready() -> void:
	visible = false
	add_to_group("shop_panel")

func open() -> void:
	visible = true

func close() -> void:
	visible = false
	
func set_price(amount):
	price.text = String(amount)

func _on_select_button_pressed() -> void:
	if turret_entry == null:
		push_error("ShopPanel: turret_entry not assigned")
		return

	emit_signal("turret_selected", turret_entry)
