extends Node
class_name ResourceManager

signal scrap_amount_changed(amount)

# public property with getter and setter
@export var scrap_amount: int:
	get:
		return scrap_amount
	set(value):
		scrap_amount = max(0, value)
		emit_signal("scrap_amount_changed", value)
