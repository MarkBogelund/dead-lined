extends Node2D
class_name DashComponent

signal dash_started(direction: Vector2)
signal dash_ended

enum State {IDLE, DASHING, COOLDOWN}

@export var enabled := true
@export var invincible := true

@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var trail: Trail = $Trail
@onready var flash_vfx: Vfx = $FlashVfx

@export_group("Dash Movement")
@export var dash_distance := 120.0
@export var dash_duration := 0.2
@export var cooldown_time := 0.5
@export var ease_in_power := 4.0 ## High value = snappier start
@export var ease_out_power := 2.0 ## Controls deceleration

var _state := State.IDLE
var _dash_direction := Vector2.ZERO
var _dash_timer := 0.0
var _cooldown_timer := 0.0
var _dash_speed := 0.0

func _ready() -> void:
	_dash_speed = dash_distance / dash_duration

func configure(p_distance: float, p_duration: float, p_cooldown: float) -> void:
	dash_distance = p_distance
	dash_duration = p_duration
	cooldown_time = p_cooldown
	_dash_speed = p_distance / p_duration

func initialize(p_distance: float, p_duration: float, p_cooldown: float) -> void:
	configure(p_distance, p_duration, p_cooldown)

func _process(delta: float) -> void:
	match _state:
		State.DASHING:
			_dash_timer += delta
			if _dash_timer >= dash_duration:
				_end_dash()
		
		State.COOLDOWN:
			_cooldown_timer -= delta
			if _cooldown_timer <= 0.0:
				_state = State.IDLE

func try_dash(direction: Vector2) -> bool:
	if not enabled or _state != State.IDLE:
		return false
	
	if direction.length() < 0.1:
		return false
	
	_start_dash(direction.normalized())
	return true

func is_dashing() -> bool:
	return _state == State.DASHING

func is_invincible() -> bool:
	return invincible and _state == State.DASHING

func get_dash_velocity() -> Vector2:
	if _state != State.DASHING:
		return Vector2.ZERO
	
	var t := _dash_timer / dash_duration
	
	# Ease-out curve (snappy start, smooth end)
	var ease_value := 1.0 - pow(1.0 - t, ease_out_power)
	
	# Apply inverse for speed (fast at start, slow at end)
	var speed_mult := 1.0 - ease_value
	
	return _dash_direction * _dash_speed * speed_mult

func cancel_dash() -> void:
	if _state == State.DASHING:
		_end_dash()

func set_enabled(value: bool) -> void:
	enabled = value

func _start_dash(direction: Vector2) -> void:
	_state = State.DASHING
	_dash_direction = direction
	_dash_timer = 0.0
	
	# Start VFX
	if dash_particles:
		dash_particles.emitting = true
	
	if trail:
		trail.start_tracking()

	if flash_vfx:
		flash_vfx.start()
	
	emit_signal("dash_started", direction)

func _end_dash() -> void:
	_state = State.COOLDOWN
	_cooldown_timer = cooldown_time
	_dash_direction = Vector2.ZERO
	
	# Stop VFX
	if dash_particles:
		dash_particles.emitting = false
	
	if trail:
		trail.stop_tracking()
	
	emit_signal("dash_ended")