extends Node
class_name CrunchTimeComponent

## Manages crunch time activation, duration, and buff calculations
## Emits signals for Player to apply/remove buffs

signal crunch_time_started(buffs: Dictionary)
signal crunch_time_ended(buffs: Dictionary)

## Duration
@export var duration := 10.0

## Buff multipliers (configurable in inspector)
@export_group("Buff Multipliers")
@export var damage_multiplier := 3.0
@export var radius_multiplier := 2.0
@export var speed_multiplier := 1.5
@export var arc_angle_multiplier := 2.0
@export var weapon_size_multiplier := 2.0
@export var cooldown_multiplier := 0.5 # 0.5 = half cooldown (faster)

## State
var is_active := false
var time_remaining := 0.0

var stress_manager: StressLevelManager
var wave_manager: WaveManager
var player: Player

func _ready() -> void:
	# Get references using group system (can't use % from inside Player node)
	stress_manager = get_tree().get_first_node_in_group("stress_level_manager")
	wave_manager = get_tree().get_first_node_in_group("wave_manager")
	player = get_parent() as Player
	
	# Connect to activation triggers
	stress_manager.crunch_time_activated.connect(activate)
	
	# Connect to deactivation triggers
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	player.died.connect(_on_player_died)

func _process(delta: float) -> void:
	if not is_active:
		return
	
	time_remaining -= delta
	
	if time_remaining <= 0.0:
		deactivate()

func _on_build_phase_started() -> void:
	if is_active:
		deactivate()

func _on_player_died() -> void:
	if is_active:
		deactivate()

## Activate crunch time with buffs
func activate() -> void:
	if is_active:
		return # Already active
	
	is_active = true
	time_remaining = duration
		
	# Build buff dictionary and emit for Player to apply
	var buffs := {
		"damage": damage_multiplier,
		"radius": radius_multiplier,
		"speed": speed_multiplier,
		"arc_angle": arc_angle_multiplier,
		"weapon_size": weapon_size_multiplier,
		"cooldown": cooldown_multiplier
	}
	crunch_time_started.emit(buffs)

## Deactivate crunch time and reset
func deactivate() -> void:
	if not is_active:
		return # Already inactive
	
	is_active = false
	time_remaining = 0.0
		
	# Build buff dictionary and emit for Player to reverse buffs
	var buffs := {
		"damage": damage_multiplier,
		"radius": radius_multiplier,
		"speed": speed_multiplier,
		"arc_angle": arc_angle_multiplier,
		"weapon_size": weapon_size_multiplier,
		"cooldown": cooldown_multiplier
	}
	crunch_time_ended.emit(buffs)

## Public API for checking if crunch time is active
func is_crunch_time_active() -> bool:
	return is_active

## Get remaining time (for UI display)
func get_time_remaining() -> float:
	return time_remaining
