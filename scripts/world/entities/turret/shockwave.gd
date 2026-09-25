extends Node2D
class_name ShockwaveComponent

const PIXEL_ART_SHADER := preload("res://shaders/shockwave_pixel_art.gdshader")

signal windup_started
signal shockwave_started
signal shockwave_finished

enum State {READY, WINDUP, EXPANDING, COOLDOWN}

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var shockwave_visual: ColorRect = $ShockwaveVisual

var contact_radius := 48.0
var shockwave_radius := 120.0
var ring_thickness := 8.0
var cooldown := 2.5
var expansion_duration := 0.6
var damage := 20
var knockback_force := 180.0
## False = the player no longer starts a pulse, but pulses still damage the player.
var trigger_on_player := true

@export_group("Presentation")
@export var windup_indicator_color := Color(0.55, 0.25, 0.9, 0.28)
@export_range(1.0, 8.0, 1.0) var windup_indicator_width := 2.0
@export_range(0.01, 2.0, 0.01) var windup_indicator_fade_duration := 0.45
@export_range(0.01, 2.0, 0.01) var shockwave_fade_duration := 0.12
@export var shockwave_color := Color(0.3, 0.9, 1.0, 0.9)
@export_range(1.0, 16.0, 1.0) var pixel_size := 2.0
@export_range(1, 8, 1) var center_line_thickness := 1
@export var center_line_color := Color.WHITE

var _enabled := false
var _state := State.READY
var _state_time := 0.0
var _wave_radius := 0.0
var _previous_wave_radius := 0.0
var _shockwave_fade_time := 0.0
var _hit_targets: Dictionary[int, bool] = {}

func configure(p_contact_radius: float, p_shockwave_radius: float, p_ring_thickness: float, p_cooldown: float, p_expansion_duration: float, p_damage: int, p_knockback_force: float) -> void:
	contact_radius = maxf(0.0, p_contact_radius)
	shockwave_radius = maxf(contact_radius, p_shockwave_radius)
	ring_thickness = maxf(1.0, p_ring_thickness)
	cooldown = maxf(0.0, p_cooldown)
	expansion_duration = maxf(0.01, p_expansion_duration)
	damage = maxi(0, p_damage)
	knockback_force = maxf(0.0, p_knockback_force)
	var circle := detection_shape.shape as CircleShape2D
	if circle:
		circle.radius = shockwave_radius + ring_thickness * 0.5
	_configure_shockwave_visual()
	queue_redraw()

func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_reset()

func apply_damage_upgrade(amount: int) -> void:
	damage += amount

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	match _state:
		State.READY:
			if _has_trigger_target():
				_enter_windup()
		State.WINDUP:
			_state_time += delta
			queue_redraw()
		State.EXPANDING:
			_update_expansion(delta)
		State.COOLDOWN:
			_state_time += delta
			if _shockwave_fade_time > 0.0:
				_shockwave_fade_time = maxf(0.0, _shockwave_fade_time - delta)
				_update_shockwave_visual(shockwave_radius, shockwave_color.a * _shockwave_fade_time / shockwave_fade_duration)
				queue_redraw()
			if _state_time >= cooldown:
				_state = State.READY
				_state_time = 0.0
				shockwave_visual.hide()
	if _state == State.WINDUP or _state == State.EXPANDING:
		queue_redraw()

func _ready() -> void:
	var material := ShaderMaterial.new()
	material.shader = PIXEL_ART_SHADER
	shockwave_visual.material = material
	_configure_shockwave_visual()
	shockwave_visual.hide()

func _configure_shockwave_visual() -> void:
	var pixel_margin := maxf(pixel_size * 2.0, ring_thickness * 0.5 + pixel_size)
	var canvas_radius := shockwave_radius + pixel_margin
	shockwave_visual.position = Vector2(-canvas_radius, -canvas_radius)
	shockwave_visual.size = Vector2.ONE * canvas_radius * 2.0
	var material := shockwave_visual.material as ShaderMaterial
	material.set_shader_parameter("canvas_size", shockwave_visual.size)
	material.set_shader_parameter("pixel_size", pixel_size)
	material.set_shader_parameter("center_line_thickness", center_line_thickness)
	material.set_shader_parameter("center_line_color", center_line_color)
	material.set_shader_parameter("ring_thickness", ring_thickness)
	material.set_shader_parameter("shockwave_color", shockwave_color)
	material.set_shader_parameter("current_radius", 0.0)

func _has_trigger_target() -> bool:
	for body: Node2D in detection_area.get_overlapping_bodies():
		if not trigger_on_player and body.is_in_group("player"):
			continue
		if _is_damageable(body) and global_position.distance_to(body.global_position) <= contact_radius:
			return true
	return false

func _enter_windup() -> void:
	_state = State.WINDUP
	_state_time = 0.0
	windup_started.emit()

func execute_shockwave() -> void:
	if not _enabled or _state != State.WINDUP:
		return
	_state = State.EXPANDING
	_state_time = 0.0
	_wave_radius = 0.0
	_previous_wave_radius = 0.0
	_hit_targets.clear()
	shockwave_visual.show()
	_update_shockwave_visual(0.0, shockwave_color.a)
	queue_redraw()
	shockwave_started.emit()

func _update_expansion(delta: float) -> void:
	_state_time += delta
	_previous_wave_radius = _wave_radius
	_wave_radius = shockwave_radius * minf(_state_time / expansion_duration, 1.0)
	_update_shockwave_visual(_wave_radius, shockwave_color.a)
	_damage_swept_ring()
	if _state_time >= expansion_duration:
		_state = State.COOLDOWN
		_state_time = 0.0
		_shockwave_fade_time = shockwave_fade_duration
		_update_shockwave_visual(shockwave_radius, shockwave_color.a)
		queue_redraw()
		shockwave_finished.emit()

func _damage_swept_ring() -> void:
	var inner_radius := maxf(0.0, _previous_wave_radius - ring_thickness * 0.5)
	var outer_radius := _wave_radius + ring_thickness * 0.5
	for body: Node2D in detection_area.get_overlapping_bodies():
		if not _is_damageable(body):
			continue
		var target_id := body.get_instance_id()
		if _hit_targets.has(target_id):
			continue
		var distance := global_position.distance_to(body.global_position)
		if distance >= inner_radius and distance <= outer_radius:
			_hit_targets[target_id] = true
			var target_knockback := knockback_force if body.is_in_group("enemies") else 0.0
			body.was_hit(damage, target_knockback, global_position)

func _is_damageable(body: Node2D) -> bool:
	if not body.has_method("was_hit"):
		return false
	if body.has_method("is_dead") and body.is_dead():
		return false
	return body.is_in_group("player") or body.is_in_group("enemies")

func _reset() -> void:
	_state = State.READY
	_state_time = 0.0
	_wave_radius = 0.0
	_previous_wave_radius = 0.0
	_shockwave_fade_time = 0.0
	_hit_targets.clear()
	shockwave_visual.hide()
	queue_redraw()

func _update_shockwave_visual(radius: float, alpha: float) -> void:
	var material := shockwave_visual.material as ShaderMaterial
	material.set_shader_parameter("current_radius", radius)
	var visual_color := shockwave_color
	visual_color.a = alpha
	material.set_shader_parameter("shockwave_color", visual_color)

func _draw() -> void:
	if _state == State.WINDUP:
		var telegraph_color := windup_indicator_color
		telegraph_color.a *= minf(_state_time / windup_indicator_fade_duration, 1.0)
		draw_arc(Vector2.ZERO, shockwave_radius, 0.0, TAU, 96, telegraph_color, windup_indicator_width)