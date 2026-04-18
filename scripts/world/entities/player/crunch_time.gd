extends Node
class_name CrunchTimeComponent

## Manages crunch time activation, duration, and buff calculations
## Emits signals for Player to apply/remove buffs

signal crunch_time_started(buffs: Dictionary)
signal crunch_time_ended(buffs: Dictionary)
signal drain_tick

## Buff multipliers (configurable in inspector)
@export_group("Buff Multipliers")
@export var damage_multiplier := 3.0
@export var radius_multiplier := 2.0
@export var speed_multiplier := 1.5
@export var arc_angle_multiplier := 2.0
@export var weapon_size_multiplier := 2.0
@export var cooldown_multiplier := 0.5 # 0.5 = half cooldown (faster)

@export_group("Deactivation")
@export var activation_cost: float = 10.0
@export var deactivation_threshold: float = 1.0
@export var drain_seconds_per_unit: float = 0.2

## State
var is_active := false
var _is_build_phase := true
var _drain_timer: float = 0.0

func _process(delta: float) -> void:
	if not is_active:
		_drain_timer = 0.0
		return
	_drain_timer -= delta
	if _drain_timer <= 0.0:
		_drain_timer = drain_seconds_per_unit
		emit_signal("drain_tick")

func set_build_phase(is_build: bool) -> void:
	_is_build_phase = is_build
	if is_build and is_active:
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
