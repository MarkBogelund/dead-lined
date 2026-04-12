extends Node
class_name StressLevelManager

## Manages stress level that increases during combat phase
## Growth rate increases with enemy and turret counts

signal stress_changed(new_stress: float)
signal crunch_time_available()
signal crunch_time_activated()

## Multiplier applied to each enemy drop per turret on screen
@export var turret_growth_modifier := 1.5

@onready var wave_manager: WaveManager = %WaveManager
@onready var turret_placer: TurretPlacer = %TurretPlacer
@onready var player: CharacterBody2D = %Player
@onready var score_manager: ScoreManager = %ScoreManager

## Current stress level (0-50)
var current_stress := 31.0

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("crunch_time"):
		activate_crunch_time()

func _on_combat_phase_started(_wave_index: int) -> void:
	is_combat_phase = true
	crunch_time_ready = false
	
	# If stress carried over at max, immediately mark crunch time as available
	if current_stress >= 50.0:
		crunch_time_ready = true
		crunch_time_available.emit()
	
	# Count all existing turrets in the scene
	turret_count = _count_existing_turrets()
	
	# Enemies spawn during combat, so start at 0
	enemy_count = 0
	
	stress_changed.emit(current_stress)

func _on_build_phase_started() -> void:
	# Stress carries over into build phase so it can be spent on turrets
	crunch_time_ready = false
	is_combat_phase = false

## Manually activate crunch time (called by button press)
func activate_crunch_time() -> void:
	if not is_combat_phase:
		return # Cannot activate during build phase
	if not crunch_time_ready or current_stress < 50.0:
		return # Can only activate when stress is at 50
	
	# Reset stress to 25 and add crunch time
	current_stress = 25.0
	crunch_time_ready = false
	score_manager.add_crunch_time(10.0)
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

## --- Prototype: stress-as-resource API ---

func can_afford(cost: float) -> bool:
	return current_stress >= cost

## Returns true only if the action leaves at least 1 stress remaining
func can_afford_safe(cost: float) -> bool:
	return current_stress - cost >= 1.0

func add_stress(amount: float) -> void:
	current_stress = minf(current_stress + amount, 50.0)
	if current_stress >= 50.0 and not crunch_time_ready:
		crunch_time_ready = true
		crunch_time_available.emit()
	stress_changed.emit(current_stress)

func subtract_stress(amount: float) -> void:
	current_stress = maxf(current_stress - amount, 0.0)
	stress_changed.emit(current_stress)
