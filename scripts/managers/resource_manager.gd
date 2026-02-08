extends Node
class_name ResourceManager

# public property with getter and setter
@export var scrap_amount: int:
	get:
		return scrap_amount
	set(value):
		scrap_amount = max(0, value)
