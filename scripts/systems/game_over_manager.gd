extends Node

## Manages game over flow and state
## Stats tracking delegated to StatsManager

signal game_over

var is_game_over := false

## Called by enemies when they die
func enemy_died() -> void:
	StatsManager.record_enemy_death()

## Called by player when they die
func player_died() -> void:
	is_game_over = true
	StatsManager.stop_time_tracking()
	game_over.emit()
	
	# Give managers time to push their stats
	await get_tree().process_frame
	
	# Get UI and show stats
	var game_over_ui := get_tree().get_first_node_in_group("game_over_ui")
	if game_over_ui and game_over_ui.has_method("show_stats"):
		game_over_ui.show_stats(StatsManager.current_run.to_dict())

## Resets game over state
func reset() -> void:
	is_game_over = false
	StatsManager.reset()
