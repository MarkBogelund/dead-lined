extends Node
class_name ScoreManager

## Manages scoring system based on player performance
## Tracks: drones destroyed, turrets destroyed, waves survived, crunch time

## Score values
const DRONE_VALUE := 100
const TURRET_VALUE := 100
const CRUNCH_TIME_VALUE := 100 # Per 10 seconds
const WAVE_VALUE := 500

## Metrics
var drones_destroyed := 0
var turrets_destroyed := 0
var waves_survived := 0
var crunch_time_spent := 0.0 # In seconds

@onready var wave_manager: WaveManager = %WaveManager
@onready var turret_placer: TurretPlacer = %TurretPlacer

func _ready() -> void:
	# Connect to wave manager for wave tracking
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	
	# Connect to turret placer for turret death tracking
	turret_placer.turret_placed.connect(_on_turret_placed)
	
	# Connect to all enemy spawners for enemy death tracking
	var enemy_spawners := get_tree().get_nodes_in_group("enemy_spawners")
	for spawner in enemy_spawners:
		if spawner.has_signal("enemy_spawned"):
			spawner.enemy_spawned.connect(_on_enemy_spawned)

func _on_combat_phase_started(wave_index: int) -> void:
	waves_survived = wave_index

func _on_enemy_spawned(enemy: Node) -> void:
	# Connect to enemy's death signal
	if enemy.has_signal("died"):
		enemy.died.connect(_on_drone_destroyed)

func _on_drone_destroyed() -> void:
	drones_destroyed += 1

func _on_turret_placed(turret: Node, _turret_entry) -> void:
	# Connect to turret's death signal
	if turret.has_signal("died"):
		turret.died.connect(_on_turret_destroyed)

func _on_turret_destroyed() -> void:
	turrets_destroyed += 1

## Called by StressLevelManager when crunch time is triggered
func add_crunch_time(seconds: float = 10.0) -> void:
	crunch_time_spent += seconds

## Calculate total score based on formula
func calculate_score() -> int:
	var drone_score := drones_destroyed * DRONE_VALUE
	var turret_score := turrets_destroyed * TURRET_VALUE
	var crunch_score := int((crunch_time_spent / 10.0) * CRUNCH_TIME_VALUE)
	var wave_score := waves_survived * WAVE_VALUE
	
	return drone_score + turret_score + crunch_score + wave_score

## Get formatted score breakdown for UI
func get_score_breakdown() -> Dictionary:
	return {
		"drones_destroyed": drones_destroyed,
		"drones_score": drones_destroyed * DRONE_VALUE,
		"turrets_destroyed": turrets_destroyed,
		"turrets_score": turrets_destroyed * TURRET_VALUE,
		"crunch_time_spent": crunch_time_spent,
		"crunch_time_score": int((crunch_time_spent / 10.0) * CRUNCH_TIME_VALUE),
		"waves_survived": waves_survived,
		"waves_score": waves_survived * WAVE_VALUE,
		"total_score": calculate_score()
	}

## Reset all metrics
func reset() -> void:
	drones_destroyed = 0
	turrets_destroyed = 0
	waves_survived = 0
	crunch_time_spent = 0.0
