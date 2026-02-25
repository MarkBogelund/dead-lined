extends Node

@onready var game_over_manager: GameOverManager = %GameOverManager

func _ready() -> void:
	game_over_manager.reset()
