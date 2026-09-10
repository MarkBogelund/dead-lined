extends Node
class_name ScoreManager

## Manages scoring system based on player performance
## Tracks: drones destroyed, crunch time (exact seconds), current wave

signal score_earned(points: int, world_position: Vector2, color: Color)

## Score values
const DRONE_VALUE := 100
const CRUNCH_TIME_VALUE := 10 # Per second in crunch time
const WAVE_VALUE := 500

## Metrics
var drones_destroyed := 0
var crunch_time_spent := 0.0 # Exact seconds in crunch time
var last_wave_survived := 0

@onready var wave_manager: WaveManager = %WaveManager
@onready var _player: Player = %Player

func _ready() -> void:
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	call_deferred("_connect_player_signals")
	# Connect to all enemy spawners for enemy death tracking
	var enemy_spawners := get_tree().get_nodes_in_group("enemy_spawners")
	for spawner in enemy_spawners:
		if spawner.has_signal("enemy_spawned"):
			spawner.enemy_spawned.connect(_on_enemy_spawned)

func _connect_player_signals() -> void:
	_player.crunch_time.crunch_time_ended.connect(_on_crunch_time_ended)

func _on_build_phase_started() -> void:
	var current_wave := wave_manager.get_current_wave()
	if current_wave > 0:
		last_wave_survived = current_wave

func _on_enemy_spawned(enemy: Node) -> void:
	# Connect to enemy's death signal, capturing the enemy reference for position
	if enemy.has_signal("died"):
		enemy.died.connect(func(): _on_drone_destroyed(enemy))

func _on_drone_destroyed(enemy: Node) -> void:
	drones_destroyed += 1
	var world_pos: Vector2 = enemy.global_position if is_instance_valid(enemy) else Vector2.ZERO
	score_earned.emit(DRONE_VALUE, world_pos, Color.WHITE)

## Called each frame while player is in crunch time
func add_crunch_time(seconds: float) -> void:
	crunch_time_spent += seconds

func _on_crunch_time_ended(_buffs: Dictionary, duration: float) -> void:
	crunch_time_spent += duration
	var session_score := int(duration * CRUNCH_TIME_VALUE)
	if session_score > 0:
		score_earned.emit(session_score, _player.global_position, Color.ORANGE)

## Calculate total score based on formula
func calculate_score() -> int:
	var drone_score := drones_destroyed * DRONE_VALUE
	var crunch_score := int(crunch_time_spent * CRUNCH_TIME_VALUE)
	var wave_score := last_wave_survived * WAVE_VALUE
	return drone_score + crunch_score + wave_score

## Get formatted score breakdown for UI
func get_score_breakdown() -> Dictionary:
	return {
		"drones_destroyed": drones_destroyed,
		"drones_score": drones_destroyed * DRONE_VALUE,
		"crunch_time_spent": crunch_time_spent,
		"crunch_time_score": int(crunch_time_spent * CRUNCH_TIME_VALUE),
		"current_wave": last_wave_survived,
		"wave_score": last_wave_survived * WAVE_VALUE,
		"total_score": calculate_score()
	}

## Reset all metrics
func reset() -> void:
	drones_destroyed = 0
	crunch_time_spent = 0.0
	last_wave_survived = 0
