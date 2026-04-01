extends Node
class_name GameOverManager

signal game_over

@export var game_over_ui: Control

var is_game_over := false

## Called by enemies when they die
func _on_enemy_died() -> void:
	StatsManager.record_enemy_death()

## Called by DeathSequenceController after death sequence
func trigger_game_over() -> void:
	is_game_over = true
	StatsManager.stop_time_tracking()
	game_over.emit()
	
	# Give managers time to push their stats
	await get_tree().process_frame
	
	# Show stats on UI
	if game_over_ui:
		game_over_ui.show_stats_with_fade(StatsManager.current_run.to_dict())

## Called directly by player (for backward compatibility)
func player_died() -> void:
	# DeathSequenceController handles the sequence now
	pass

## Resets game over state
func reset() -> void:
	is_game_over = false
	StatsManager.reset()
