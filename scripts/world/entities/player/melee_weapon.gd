extends Area2D
class_name MeleeWeapon

signal slash_started(target_position: Vector2)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trail: Line2D = $Trail
@onready var glimmer_particles: GPUParticles2D = $GlimmerParticles

@export var damage := 10
@export var target_knockback := 200.0
@export var slash_radius := 24.0
@export var arc_angle := PI
@export var slash_duration := 0.25
@export var slash_cooldown := 0.3

## Visual settings
@export var ease_power := 3
@export var flash_intensity := 1.0

var _enabled := true
var _cooldown_timer := 0.0
var _time := 0.0
var _start_angle := 0.0
var _direction := 1
var _slashing := false

func _ready() -> void:
	_reset()

func _reset() -> void:
	_time = 0.0
	_slashing = false
	sprite.visible = false
	monitoring = false
	monitorable = false
	if trail:
		trail.stop_tracking()
	if glimmer_particles:
		glimmer_particles.emitting = false

func get_damage() -> int:
	return damage

func get_knockback() -> float:
	return target_knockback

func set_enabled(enabled: bool) -> void:
	_enabled = enabled

func try_slash(target_pos: Vector2) -> void:
	if _cooldown_timer > 0.0 or not _enabled:
		return
	
	_cooldown_timer = slash_cooldown
	_reset()
	
	# Random swing direction
	_direction = -1 if randf() < 0.5 else 1
	
	# Calculate starting angle
	var dir := (target_pos - global_position).normalized()
	var center_angle := dir.angle()
	_start_angle = center_angle - (_direction * arc_angle * 0.5)
	
	# Activate weapon
	_slashing = true
	sprite.visible = true
	monitoring = true
	monitorable = true
	
	# Start trail and glimmer particles
	if trail:
		trail.start_tracking()
	if glimmer_particles:
		glimmer_particles.emitting = true
	
	emit_signal("slash_started", target_pos)

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
	
	if _slashing:
		_update_slash(delta)

func _update_slash(delta: float) -> void:
	_time += delta
	var t := _time / slash_duration
	
	if t >= 1.0:
		if trail:
			trail.stop_tracking()
		_reset()
		sprite.modulate = Color.WHITE
		return
	
	# Apply ease-out curve for snappier motion
	var t_eased := 1.0 - pow(1.0 - t, ease_power)
	
	# Arc animation with easing
	var angle := _start_angle + (_direction * arc_angle * t_eased)
	rotation = angle + PI / 2
	
	# Flash/glow effect (pulses during swing)
	var flash := sin(t * PI) * flash_intensity
	sprite.modulate = Color(1.0 + flash, 1.0 + flash, 1.0 + flash, 1.0)
	position = Vector2.RIGHT.rotated(angle) * slash_radius
