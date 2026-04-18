extends Node
class_name GameOverManager

signal game_over

@export var game_over_ui: Control
@onready var player: Player = %Player
@onready var animation_player: AnimationPlayer = $"./AnimationPlayer"
@onready var score_manager: ScoreManager = %ScoreManager

func _ready() -> void:
	add_to_group("game_over_manager")
	player.died.connect(_on_player_died)
	game_over_ui.restart_game.connect(_on_restart_pressed)

func _on_player_died() -> void:
	game_over.emit()
	animation_player.play("play_death_sequence")

## Called by animation to show score breakdown
func show_score_breakdown() -> void:
	var breakdown: Dictionary = score_manager.get_score_breakdown()
	game_over_ui.show_stats_with_fade(breakdown)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
