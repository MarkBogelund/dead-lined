extends Node
class_name GameOverManager

signal game_over

@export var game_over_ui: Control
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var animation_player: AnimationPlayer = $"./AnimationPlayer"

func _ready() -> void:
	add_to_group("game_over_manager")
	player.died.connect(_on_player_died)
	game_over_ui.restart_game.connect(_on_restart_pressed)

func _on_player_died() -> void:
	game_over.emit()
	animation_player.play("play_death_sequence")

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
