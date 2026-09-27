extends Node
class_name CrunchTimeComponent

## Manages the Crunch Time charge, activation, duration, and buff calculations.
## A charge comes from a collected CrunchPowerup; the player can carry one at a time.
## Emits signals for Player to apply/remove buffs

signal crunch_time_started(buffs: Dictionary)
signal crunch_time_ended(buffs: Dictionary, duration: float)
signal charge_gained
## The charge was used to activate Crunch Time.
signal charge_spent
## The charge was taken away (hit, death, or the round ending) without being used.
signal charge_lost

## Buff multipliers (configurable in inspector)
@export_group("Buff Multipliers")
@export var damage_multiplier := 3.0
@export var radius_multiplier := 2.0
@export var speed_multiplier := 1.5
@export var arc_angle_multiplier := 2.0
@export var cooldown_multiplier := 0.5 # 0.5 = half cooldown (faster)

@export_group("Activation")
@export var duration: float = 5.0

## State
var is_active := false
var _has_charge := false
var _is_build_phase := true
var _active_duration: float = 0.0
var _camera: GameCamera

func initialize(p_duration: float, p_damage: float, p_radius: float, p_speed: float, p_arc_angle: float, p_cooldown: float, p_camera: GameCamera) -> void:
	duration = p_duration
	damage_multiplier = p_damage
	radius_multiplier = p_radius
	speed_multiplier = p_speed
	arc_angle_multiplier = p_arc_angle
	cooldown_multiplier = p_cooldown
	_camera = p_camera

func _process(delta: float) -> void:
	if not is_active:
		return
	_active_duration += delta
	if _active_duration >= duration:
		deactivate()

func set_build_phase(is_build: bool) -> void:
	_is_build_phase = is_build
	if is_build:
		deactivate()
		lose_charge()

func has_charge() -> bool:
	return _has_charge

## Returns false if Crunch Time is running or a charge is already carried, so the powerup stays on the ground.
func add_charge() -> bool:
	if is_active or _has_charge:
		return false
	_has_charge = true
	charge_gained.emit()
	return true

func lose_charge() -> void:
	if not _has_charge:
		return
	_has_charge = false
	charge_lost.emit()

## Spends the carried charge to start Crunch Time.
func try_activate() -> bool:
	if is_active or _is_build_phase or not _has_charge:
		return false
	_has_charge = false
	charge_spent.emit()
	activate()
	return true

## Activate crunch time with buffs
func activate() -> void:
	if is_active or _is_build_phase:
		return # Already active or in build phase
	
	is_active = true
	_active_duration = 0.0
	if _camera:
		_camera.set_crunch_time_active(true)
		
	# Build buff dictionary and emit for Player to apply
	var buffs := {
		"damage": damage_multiplier,
		"radius": radius_multiplier,
		"speed": speed_multiplier,
		"arc_angle": arc_angle_multiplier,
		"cooldown": cooldown_multiplier
	}
	crunch_time_started.emit(buffs)

## Deactivate crunch time and reset
func deactivate() -> void:
	if not is_active:
		return # Already inactive
	
	is_active = false
	if _camera:
		_camera.set_crunch_time_active(false)
		
	# Build buff dictionary and emit for Player to reverse buffs
	var buffs := {
		"damage": damage_multiplier,
		"radius": radius_multiplier,
		"speed": speed_multiplier,
		"arc_angle": arc_angle_multiplier,
		"cooldown": cooldown_multiplier
	}
	crunch_time_ended.emit(buffs, _active_duration)

## Public API for checking if crunch time is active
func is_crunch_time_active() -> bool:
	return is_active

