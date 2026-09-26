extends Node2D
class_name DashComponent

## Hold to charge (the owner slows time), release to dash; charge time sets the distance.

signal charge_started
## Charge reached max_charge_time; the owner should call release_charge().
signal charge_maxed
## Emitted when a charge is released or cancelled.
signal charge_ended
signal dash_started(direction: Vector2)
signal dash_ended

enum State {IDLE, CHARGING, DASHING, COOLDOWN}

@export var enabled := true
@export var invincible := true
@export var invincible_while_charging := true

@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var trail: Trail = $Trail
@onready var flash_vfx: Vfx = $FlashVfx

@export_group("Dash Movement")
@export var min_distance := 120.0
@export var max_distance := 300.0
## Starting speed; the dash eases out to 0 over its duration.
@export var dash_speed := 1750.0
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

func initialize(p_min_distance: float, p_max_distance: float, p_speed: float, p_max_charge_time: float, p_cooldown: float) -> void:
	min_distance = p_min_distance
	max_distance = maxf(p_min_distance, p_max_distance)
	dash_speed = p_speed
	max_charge_time = maxf(0.01, p_max_charge_time)
	cooldown_time = p_cooldown

func _process(delta: float) -> void:
	match _state:
		State.CHARGING:
			# Charge in real time: the owner slows Engine.time_scale while charging.
			if Engine.time_scale > 0.0:
				_charge_time += delta / Engine.time_scale
			if _charge_time >= max_charge_time and not _charge_maxed:
				_charge_maxed = true
				charge_maxed.emit()
		State.COOLDOWN:
			_cooldown_timer -= delta
			if _cooldown_timer <= 0.0:
				_state = State.IDLE

func try_begin_charge() -> bool:
	if not enabled or _state != State.IDLE:
		return false
	_state = State.CHARGING
	_charge_time = 0.0
	_charge_maxed = false
	charge_started.emit()
	return true

func release_charge(direction: Vector2) -> bool:
	if _state != State.CHARGING:
		return false
	var distance := lerpf(min_distance, max_distance, get_charge_ratio())
	_state = State.IDLE
	charge_ended.emit()
	if direction.length() < 0.1:
		return false
	_start_dash(direction.normalized(), distance)
	return true

## Drops the charge without dashing or starting the cooldown.
func cancel_charge() -> void:
	if _state == State.CHARGING:
		_state = State.IDLE
		charge_ended.emit()

func get_charge_ratio() -> float:
	return clampf(_charge_time / max_charge_time, 0.0, 1.0)

func is_charging() -> bool:
	return _state == State.CHARGING

func is_dashing() -> bool:
	return _state == State.DASHING

func is_invincible() -> bool:
	return (invincible and _state == State.DASHING) or (invincible_while_charging and _state == State.CHARGING)

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
	if flash_vfx:
		flash_vfx.start()

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
