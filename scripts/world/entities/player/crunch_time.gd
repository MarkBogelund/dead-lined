extends Node
class_name CrunchTimeComponent

## Manages crunch time activation, duration, and buff calculations
## Emits signals for Player to apply/remove buffs

signal crunch_time_started(buffs: Dictionary)
signal crunch_time_ended(buffs: Dictionary)

## Buff multipliers (configurable in inspector)
@export_group("Buff Multipliers")
@export var damage_multiplier := 3.0
@export var radius_multiplier := 2.0
@export var speed_multiplier := 1.5
@export var arc_angle_multiplier := 2.0
@export var weapon_size_multiplier := 2.0
@export var cooldown_multiplier := 0.5 # 0.5 = half cooldown (faster)

@export_group("Deactivation")
@export var deactivation_threshold: float = 1.0

## State
var is_active := false
var _is_build_phase := true

var wave_manager: WaveManager
var player: Player

func _ready() -> void:
	wave_manager = get_tree().get_first_node_in_group("wave_manager")
	player = get_parent() as Player
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	player.died.connect(_on_player_died)

func _on_build_phase_started() -> void:
	_is_build_phase = true
	if is_active:
		deactivate()

func _on_combat_phase_started(_wave_index: int) -> void:
	_is_build_phase = false

func _on_player_died() -> void:
	if is_active:
		deactivate()

## Toggle crunch time — activates if can_activate is true, deactivates if already active
func toggle(can_activate: bool) -> void:
	if is_active:
		deactivate()
	elif can_activate:
		activate()

## Activate crunch time with buffs
func activate() -> void:
	if is_active or _is_build_phase:
		return # Already active or in build phase
	
	is_active = true
		
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


