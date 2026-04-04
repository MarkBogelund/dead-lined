extends Node
class_name GameOverManager

signal game_over

@export var game_over_ui: Control
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var animation_player: AnimationPlayer = $"./AnimationPlayer"

func _ready() -> void:
	add_to_group("game_over_manager")
	
	# Connect to player death
	if player.has_signal("died"):
		player.died.connect(_on_player_died)

func _on_player_died() -> void:
	game_over.emit()
	animation_player.play("play_death_sequence")

func _on_enemy_died() -> void:
	StatsManager.record_enemy_death()

## Resets game over state
func reset() -> void:
	StatsManager.reset()
