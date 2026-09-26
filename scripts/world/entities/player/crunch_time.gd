extends Node
class_name CrunchTimeComponent

## Manages crunch time activation, duration, and buff calculations
## Emits signals for Player to apply/remove buffs

signal crunch_time_started(buffs: Dictionary)
signal crunch_time_ended(buffs: Dictionary, duration: float)

## Buff multipliers (configurable in inspector)
@export_group("Buff Multipliers")
@export var damage_multiplier := 3.0
@export var radius_multiplier := 2.0
@export var speed_multiplier := 1.5
@export var arc_angle_multiplier := 2.0
@export var weapon_size_multiplier := 2.0
@export var cooldown_multiplier := 0.5 # 0.5 = half cooldown (faster)

@export_group("Activation")
@export var activation_cost: float = 50.0
@export var duration: float = 5.0

@export_group("Camera")
@export var effects: CrunchTimeEffects = preload("res://resources/crunch_time_effects.tres")

## State
var is_active := false
var _is_build_phase := true
var _active_duration: float = 0.0
var _camera: GameCamera

const CAMERA_ZOOM_SOURCE := &"crunch_time"

func initialize(p_activation_cost: float, p_duration: float, p_damage: float, p_radius: float, p_speed: float, p_arc_angle: float, p_weapon_size: float, p_cooldown: float, p_camera: GameCamera) -> void:
	activation_cost = p_activation_cost
	duration = p_duration
	damage_multiplier = p_damage
	radius_multiplier = p_radius
	speed_multiplier = p_speed
	arc_angle_multiplier = p_arc_angle
	weapon_size_multiplier = p_weapon_size
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
	if is_build and is_active:
		deactivate()

## Toggle crunch time — activates if can_activate is true, deactivates if already active
func toggle(can_activate: bool) -> void:
	if not is_active and can_activate:
		activate()

## Activate crunch time with buffs
func activate() -> void:
	if is_active or _is_build_phase:
		return # Already active or in build phase
	
	is_active = true
	_active_duration = 0.0
	_apply_camera_zoom(effects.camera_zoom_active.x if effects else 1.75)
		
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
	_apply_camera_zoom(1.0)
		
	# Build buff dictionary and emit for Player to reverse buffs
	var buffs := {
		"damage": damage_multiplier,
		"radius": radius_multiplier,
		"speed": speed_multiplier,
		"arc_angle": arc_angle_multiplier,
		"weapon_size": weapon_size_multiplier,
		"cooldown": cooldown_multiplier
	}
	crunch_time_ended.emit(buffs, _active_duration)

## Public API for checking if crunch time is active
func is_crunch_time_active() -> bool:
	return is_active

func _apply_camera_zoom(factor: float) -> void:
	if not _camera:
		return
	_camera.set_zoom_factor(CAMERA_ZOOM_SOURCE, factor, effects.camera_zoom_duration if effects else 0.35)
