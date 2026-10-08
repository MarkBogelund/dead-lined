extends Node2D
class_name DashComponent

## Press to dash; holding past charge_delay starts a charge (the owner slows time) that sets the distance.

## Hold passed charge_delay: the charge (slow-motion) begins.
signal charge_started
## Charge reached max_charge_time; the owner should call release().
signal charge_maxed
## Emitted when a started charge is released or cancelled.
signal charge_ended
signal dash_started(direction: Vector2)
signal dash_ended

## HOLDING = pressed but still inside the tap window; releasing here is a plain min-distance dash.
enum State {IDLE, HOLDING, CHARGING, DASHING, COOLDOWN}

@export var enabled := true
@export var invincible := true
@export var invincible_while_charging := true

@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var trail: Trail = $Trail

@export_group("Dash Movement")
@export var min_distance := 120.0
@export var max_distance := 300.0
## Starting speed; the dash eases out to 0 over its duration.
@export var dash_speed := 1750.0
## Real-time seconds the button must be held before charging starts.
@export var charge_delay := 0.15
## Real-time seconds from press until a charge fires automatically.
@export var max_charge_time := 0.5
@export var cooldown_time := 0.5
@export var ease_out_power := 2.0 ## Controls deceleration

var _state := State.IDLE
var _dash_direction := Vector2.ZERO
var _dash_timer := 0.0
var _dash_duration := 0.0
var _dash_distance := 0.0
var _cooldown_timer := 0.0
var _charge_time := 0.0
var _charge_maxed := false

func initialize(p_min_distance: float, p_max_distance: float, p_speed: float, p_charge_delay: float, p_max_charge_time: float, p_cooldown: float) -> void:
	min_distance = p_min_distance
	max_distance = maxf(p_min_distance, p_max_distance)
	dash_speed = p_speed
	charge_delay = maxf(0.0, p_charge_delay)
	max_charge_time = maxf(charge_delay + 0.01, p_max_charge_time)
	cooldown_time = p_cooldown

func _process(delta: float) -> void:
	match _state:
		State.HOLDING, State.CHARGING:
			# Real time: the owner slows Engine.time_scale while charging.
			if Engine.time_scale > 0.0:
				_charge_time += delta / Engine.time_scale
			if _state == State.HOLDING and _charge_time >= charge_delay:
				_state = State.CHARGING
				charge_started.emit()
			if _state == State.CHARGING and _charge_time >= max_charge_time and not _charge_maxed:
				_charge_maxed = true
				charge_maxed.emit()
		State.COOLDOWN:
			_cooldown_timer -= delta
			if _cooldown_timer <= 0.0:
				_state = State.IDLE

func try_press() -> bool:
	if not enabled or _state != State.IDLE:
		return false
	_state = State.HOLDING
	_charge_time = 0.0
	_charge_maxed = false
	return true

## Fires the dash: min_distance from the tap window, otherwise scaled by charge time.
func release(direction: Vector2) -> bool:
	if _state != State.HOLDING and _state != State.CHARGING:
		return false
	var distance := lerpf(min_distance, max_distance, get_charge_ratio())
	var was_charging := _state == State.CHARGING
	_state = State.IDLE
	if was_charging:
		charge_ended.emit()
	if direction.length() < 0.1:
		return false
	_start_dash(direction.normalized(), distance)
	return true

## Drops the press/charge without dashing or starting the cooldown.
func cancel_charge() -> void:
	var was_charging := _state == State.CHARGING
	if _state == State.HOLDING or was_charging:
		_state = State.IDLE
	if was_charging:
		charge_ended.emit()

func get_charge_ratio() -> float:
	return clampf((_charge_time - charge_delay) / (max_charge_time - charge_delay), 0.0, 1.0)

## Real-time seconds a started charge takes to reach max distance.
func get_charge_duration() -> float:
	return max_charge_time - charge_delay

## True while the button is held (tap window or charging); blocks other actions.
func is_holding() -> bool:
	return _state == State.HOLDING or _state == State.CHARGING

func is_charging() -> bool:
	return _state == State.CHARGING

func is_dashing() -> bool:
	return _state == State.DASHING

func is_invincible() -> bool:
	return (invincible and _state == State.DASHING) or (invincible_while_charging and is_holding())

## Call once per physics step while dashing; returns the velocity that covers exactly this step's share of the distance.
func step_dash(delta: float) -> Vector2:
	if _state != State.DASHING or delta <= 0.0:
		return Vector2.ZERO
	var t0 := _dash_timer / _dash_duration
	_dash_timer = minf(_dash_timer + delta, _dash_duration)
	var t1 := _dash_timer / _dash_duration
	var step_distance := _dash_distance * (_eased_progress(t1) - _eased_progress(t0))
	var velocity := _dash_direction * step_distance / delta
	if _dash_timer >= _dash_duration:
		_end_dash()
	return velocity

# Fraction of the distance covered at normalized time t when speed decays as (1 - t)^p.
func _eased_progress(t: float) -> float:
	return 1.0 - pow(1.0 - t, ease_out_power + 1.0)

func cancel_dash() -> void:
	if _state == State.DASHING:
		_end_dash()

func set_enabled(value: bool) -> void:
	enabled = value
	if not value:
		cancel_charge()

func _start_dash(direction: Vector2, distance: float) -> void:
	_state = State.DASHING
	_dash_direction = direction
	_dash_timer = 0.0
	_dash_distance = distance
	# Speed decays as (1 - t)^p, which covers 1 / (p + 1) of dash_speed * duration.
	_dash_duration = distance * (ease_out_power + 1.0) / dash_speed

	if dash_particles:
		dash_particles.emitting = true
	if trail:
		trail.start_tracking()

	dash_started.emit(direction)

func _end_dash() -> void:
	_state = State.COOLDOWN
	_cooldown_timer = cooldown_time
	_dash_direction = Vector2.ZERO

	if dash_particles:
		dash_particles.emitting = false
	if trail:
		trail.stop_tracking()

	dash_ended.emit()
