extends Node

## Tracks all game statistics
## Separated from game flow logic for maintainability and testing

class RunStats:
	var time := 0.0
	var kills := 0
	var waves := 0
	var turrets := 0
	var scrap := 0
	
	func to_dict() -> Dictionary:
		return {
			"time": time,
			"kills": kills,
			"waves": waves,
			"turrets": turrets,
			"scrap": scrap
		}
	
	func reset() -> void:
		time = 0.0
		kills = 0
		waves = 0
		turrets = 0
		scrap = 0

var current_run := RunStats.new()
var is_time_tracking := false

func _process(delta: float) -> void:
	if is_time_tracking:
		current_run.time += delta

func start_time_tracking() -> void:
	if not is_time_tracking:
		is_time_tracking = true

func stop_time_tracking() -> void:
	is_time_tracking = false

func record_enemy_death() -> void:
	current_run.kills += 1

func set_waves(count: int) -> void:
	current_run.waves = count

func set_scrap(amount: int) -> void:
	current_run.scrap = amount

func set_turrets(count: int) -> void:
	current_run.turrets = count

func reset() -> void:
	current_run.reset()
	is_time_tracking = false
