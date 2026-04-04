extends Node
class_name StressLevelManager

## Manages stress level that increases during combat phase
## Growth rate increases with enemy and turret counts

signal stress_changed(new_stress: float)
signal crunch_time_available()
signal crunch_time_activated()

## Base growth rate in stress % per second
@export var base_growth_rate := 1.0

## Additional growth % per enemy
@export var enemy_growth_modifier := 1.0

## Additional growth % per turret
@export var turret_growth_modifier := 5.0

@onready var wave_manager: WaveManager = %WaveManager
@onready var turret_placer: TurretPlacer = %TurretPlacer
@onready var player: CharacterBody2D = %Player
@onready var score_manager: ScoreManager = %ScoreManager

## Current stress level (0-100)
var current_stress := 0.0

## Entity counts
var enemy_count := 0
var turret_count := 0

## Phase tracking
var is_combat_phase := false

## Crunch time availability flag
var crunch_time_ready := false

func _ready() -> void:
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	
	# Connect to player death
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	
	# Connect to all enemy spawners in the scene
	var enemy_spawners := get_tree().get_nodes_in_group("enemy_spawners")
	for spawner in enemy_spawners:
		if spawner.has_signal("enemy_spawned"):
			spawner.enemy_spawned.connect(_on_enemy_spawned)
	
	# Connect to turret placer
	turret_placer.turret_placed.connect(_on_turret_placed)

func _process(delta: float) -> void:
	if not is_combat_phase:
		return
	
	# Calculate growth rate based on entity counts
	var growth_rate := _calculate_growth_rate()
	
	# Increase stress
	current_stress += growth_rate * delta
	
	# Cap at 100 and notify when crunch time becomes available
	if current_stress >= 100.0:
		current_stress = 100.0
		if not crunch_time_ready:
			crunch_time_ready = true
			crunch_time_available.emit()
			print("Crunch time available! Press button to activate.")
	
	stress_changed.emit(current_stress)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("crunch_time"):
		activate_crunch_time()

func _calculate_growth_rate() -> float:
	# Base rate + (enemies * modifier) + (turrets * modifier)
	return base_growth_rate + (enemy_count * enemy_growth_modifier) + (turret_count * turret_growth_modifier)

func _on_combat_phase_started(_wave_index: int) -> void:
	is_combat_phase = true
	crunch_time_ready = false
	
	# Count all existing turrets in the scene
	turret_count = _count_existing_turrets()
	
	# Enemies spawn during combat, so start at 0
	enemy_count = 0
	
	stress_changed.emit(current_stress)

func _on_build_phase_started() -> void:
	# Reset stress to 0
	current_stress = 0.0
	crunch_time_ready = false
	stress_changed.emit(current_stress)
	is_combat_phase = false

## Manually activate crunch time (called by button press)
func activate_crunch_time() -> void:
	if not crunch_time_ready or current_stress < 100.0:
		return  # Can only activate when stress is at 100
	
	# Reset stress and add crunch time
	current_stress = 0.0
	crunch_time_ready = false
	score_manager.add_crunch_time(10.0)
	print("Crunch time activated! +10s")
	crunch_time_activated.emit()
	stress_changed.emit(current_stress)

func _on_player_died() -> void:
	# Stop stress growth when player dies
	is_combat_phase = false

func _on_enemy_spawned(enemy: Node) -> void:
	enemy_count += 1
	# Connect to enemy's death signal
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemy_count = max(0, enemy_count - 1)

func _on_turret_placed(turret: Node, _turret_entry) -> void:
	turret_count += 1
	# Connect to turret's death signal
	if turret.has_signal("died"):
		turret.died.connect(_on_turret_died)
	stress_changed.emit(current_stress)

func _on_turret_died() -> void:
	turret_count = max(0, turret_count - 1)

## Count turrets in the scene at combat start
func _count_existing_turrets() -> int:
	var count := 0
	# Get all nodes in "turrets" group
	var turrets := get_tree().get_nodes_in_group("turrets")
	count = turrets.size()
	return count
