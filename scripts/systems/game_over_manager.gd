extends Node
class_name GameOverManager

signal game_over

@export var game_over_ui: Control

var is_game_over := false

## Called by enemies when they die
func _on_enemy_died() -> void:
	StatsManager.record_enemy_death()

## Called by player when they die
func player_died() -> void:
	is_game_over = true
	StatsManager.stop_time_tracking()
	game_over.emit()
	
	# Give managers time to push their stats
	await get_tree().process_frame
	
	# Show stats on UI
	if game_over_ui:
		game_over_ui.show_stats(StatsManager.current_run.to_dict())

## Resets game over state
func reset() -> void:
	is_game_over = false
	StatsManager.reset()
