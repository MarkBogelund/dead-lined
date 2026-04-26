extends Node2D
class_name MeleeWeapon

@onready var sprite: Sprite2D = $Sprite2D
@onready var trail: Line2D = $Trail
@onready var glimmer_particles: GPUParticles2D = $GlimmerParticles
@onready var hitbox: HitboxComponent = $HitboxComponent
@export var camera_shake_manager: CameraShakeManager

signal hit_obstacle(hit_position: Vector2, self_knockback: float)

@export_group("Slash Settings")
@export var damage := 20
@export var knockback := 200.0
@export var self_knockback := 150.0
@export var slash_radius := 24.0
@export var arc_angle := PI
@export var slash_duration := 0.25
@export var slash_cooldown := 0.3

@export_group("Visual Effects")
@export var ease_power := 3
@export var flash_intensity := 1.0
@export var camera_shake_intensity := 0.2
@export var camera_shake_duration := 0.15

var _enabled := true
var _cooldown_timer := 0.0
var _time := 0.0
var _start_angle := 0.0
var _direction := 1
var _slashing := false

func _ready() -> void:
	hitbox.damage = damage
	hitbox.knockback = knockback
	_reset()
	hitbox.hit_target.connect(_on_hit_target)

func initialize(p_damage: int, p_knockback: float, p_self_knockback: float, p_radius: float, p_arc_angle: float, p_duration: float, p_cooldown: float) -> void:
	damage = p_damage
	knockback = p_knockback
	self_knockback = p_self_knockback
	slash_radius = p_radius
	arc_angle = p_arc_angle
	slash_duration = p_duration
	slash_cooldown = p_cooldown
	hitbox.damage = p_damage
	hitbox.knockback = p_knockback

func _reset() -> void:
	_time = 0.0
	_slashing = false
	sprite.visible = false
	hitbox.disable()
	if trail:
		trail.stop_tracking()
	if glimmer_particles:
		glimmer_particles.emitting = false

func set_enabled(enabled: bool) -> void:
	_enabled = enabled

func try_slash(target_pos: Vector2) -> bool:
	if _cooldown_timer > 0.0 or not _enabled:
		return false
	
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
	hitbox.enable()
	
	# Start trail and glimmer particles
	if trail:
		trail.start_tracking()
	if glimmer_particles:
		glimmer_particles.emitting = true
	
	return true

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

func _on_hit_target(target: Node) -> void:
	camera_shake_manager.shake_screen(camera_shake_duration, camera_shake_intensity)
	if not target.has_method("was_hit"):
		emit_signal("hit_obstacle", hitbox.global_position, self_knockback)
