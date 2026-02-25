extends Node
class_name ResourceManager

signal scrap_amount_changed(amount)

@onready var game_over_manager: GameOverManager = %GameOverManager

func _ready() -> void:
	game_over_manager.game_over.connect(_on_game_over)

func _on_game_over() -> void:
	StatsManager.set_scrap(scrap_amount)

# public property with getter and setter
@export var scrap_amount: int:
	get:
		return scrap_amount
	set(value):
		scrap_amount = max(0, value)
		emit_signal("scrap_amount_changed", value)

func can_buy(price: int) -> bool:
	return scrap_amount >= price

func add_scrap(amount: int) -> void:
	scrap_amount += amount

func subtract_scrap(amount: int) -> void:
	if amount > scrap_amount:
		push_error("ResourceManager: Attempted to subtract more scrap than available")
		return
	
	scrap_amount -= amount
