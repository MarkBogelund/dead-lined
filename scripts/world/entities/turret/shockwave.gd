extends Node2D
class_name ShockwaveComponent

signal windup_started
signal shockwave_started
signal shockwave_finished
signal shockwave_fade_finished

enum State {READY, WINDUP, EXPANDING, COOLDOWN}

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var shockwave_visual: ColorRect = $ShockwaveVisual

## Trigger distance and blast radius.
@export_group("Wave")
@export_range(0.0, 500.0, 1.0)
var max_range := 120.0
@export_range(1.0, 64.0, 1.0)
var ring_thickness := 8.0
@export_range(0.0, 30.0, 0.01)
var cooldown := 2.5
@export_range(0.01, 5.0, 0.01)
var expansion_duration := 0.6
@export_range(0, 1000, 1)
var damage := 20
@export_range(0.0, 1000.0, 1.0)
var knockback_force := 180.0
## Defaults retain turret waves' player/enemy targets; boss landings can select player/turrets instead.
@export var target_groups: Array[StringName] = [&"player", &"enemies"]
## False = the player no longer starts a pulse, but pulses still damage the player.
var trigger_on_player := true
## False lets an external owner call execute_shockwave() at a locked impact point.
@export var auto_trigger := true

@export_group("Presentation")
@export var pixel_art_shader: Shader
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

func configure(p_max_range: float, p_ring_thickness: float, p_cooldown: float, p_expansion_duration: float, p_damage: int, p_knockback_force: float) -> void:
	max_range = maxf(0.0, p_max_range)
	ring_thickness = maxf(1.0, p_ring_thickness)
	cooldown = maxf(0.0, p_cooldown)
	expansion_duration = maxf(0.01, p_expansion_duration)
	damage = maxi(0, p_damage)
	knockback_force = maxf(0.0, p_knockback_force)
	_apply_radius()

func configure_manual(p_max_range: float, p_expansion_duration: float, p_damage: int, p_knockback_force: float) -> void:
	max_range = maxf(0.0, p_max_range)
	expansion_duration = maxf(0.01, p_expansion_duration)
	damage = maxi(0, p_damage)
	knockback_force = maxf(0.0, p_knockback_force)
	cooldown = shockwave_fade_duration
	_apply_radius()

func set_max_range(value: float) -> void:
	max_range = maxf(0.0, value)
	_apply_radius()

func get_cooldown_progress() -> float:
	var cycle_duration := expansion_duration + cooldown
	if cycle_duration <= 0.0:
		return 1.0
	match _state:
		State.EXPANDING:
			return clampf(_state_time / cycle_duration, 0.0, 1.0)
		State.COOLDOWN:
			return clampf((expansion_duration + _state_time) / cycle_duration, 0.0, 1.0)
		_:
			return 1.0

func _apply_radius() -> void:
	var circle := detection_shape.shape as CircleShape2D
	if circle:
		circle.radius = max_range + ring_thickness * 0.5
	_configure_shockwave_visual()
	queue_redraw()

func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_reset()

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	match _state:
		State.READY:
			if auto_trigger and _has_trigger_target():
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
				_update_shockwave_visual(max_range, shockwave_color.a * _shockwave_fade_time / shockwave_fade_duration)
				queue_redraw()
			if _state_time >= cooldown:
				_state = State.READY
				_state_time = 0.0
				shockwave_visual.hide()
				shockwave_fade_finished.emit()
	if _state == State.WINDUP or _state == State.EXPANDING:
		queue_redraw()

func _ready() -> void:
	if not pixel_art_shader:
		push_error("ShockwaveComponent requires pixel_art_shader")
		return
	# The scene's shape is shared by every Shockwaver; per-turret range upgrades need their own.
	detection_shape.shape = detection_shape.shape.duplicate()
	var shader_material := ShaderMaterial.new()
	shader_material.shader = pixel_art_shader
	shockwave_visual.material = shader_material
	_apply_radius()
	shockwave_visual.hide()

func _configure_shockwave_visual() -> void:
	var pixel_margin := maxf(pixel_size * 2.0, ring_thickness * 0.5 + pixel_size)
	var canvas_radius := max_range + pixel_margin
	shockwave_visual.position = Vector2(-canvas_radius, -canvas_radius)
	shockwave_visual.size = Vector2.ONE * canvas_radius * 2.0
	var shader_material := shockwave_visual.material as ShaderMaterial
	shader_material.set_shader_parameter("canvas_size", shockwave_visual.size)
	shader_material.set_shader_parameter("pixel_size", pixel_size)
	shader_material.set_shader_parameter("center_line_thickness", center_line_thickness)
	shader_material.set_shader_parameter("center_line_color", center_line_color)
	shader_material.set_shader_parameter("ring_thickness", ring_thickness)
	shader_material.set_shader_parameter("shockwave_color", shockwave_color)
	shader_material.set_shader_parameter("current_radius", 0.0)

func _has_trigger_target() -> bool:
	for body: Node2D in detection_area.get_overlapping_bodies():
		if not trigger_on_player and body.is_in_group("player"):
			continue
		if _is_damageable(body) and global_position.distance_to(body.global_position) <= max_range:
			return true
	return false

func _enter_windup() -> void:
	_state = State.WINDUP
	_state_time = 0.0
	windup_started.emit()

## Aborts a windup the owner could not present; the next frame retries while a target is still in range.
func cancel_windup() -> void:
	if _state != State.WINDUP:
		return
	_state = State.READY
	_state_time = 0.0
	queue_redraw()

func execute_shockwave() -> void:
	var manual_ready := not auto_trigger and _state == State.READY
	if not _enabled or (_state != State.WINDUP and not manual_ready):
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
	_wave_radius = max_range * minf(_state_time / expansion_duration, 1.0)
	_update_shockwave_visual(_wave_radius, shockwave_color.a)
	_damage_swept_ring()
	if _state_time >= expansion_duration:
		_state = State.COOLDOWN
		_state_time = 0.0
		_shockwave_fade_time = shockwave_fade_duration
		_update_shockwave_visual(max_range, shockwave_color.a)
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
			if body.has_method("was_hit_bypassing_armor"):
				body.was_hit_bypassing_armor(damage, target_knockback, global_position)
			else:
				body.was_hit(damage, target_knockback, global_position)

func _is_damageable(body: Node2D) -> bool:
	if not body.has_method("was_hit"):
		return false
	if body.has_method("is_dead") and body.is_dead():
		return false
	for group_name: StringName in target_groups:
		if body.is_in_group(group_name):
			return true
	return false

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
	var shader_material := shockwave_visual.material as ShaderMaterial
	shader_material.set_shader_parameter("current_radius", radius)
	var visual_color := shockwave_color
	visual_color.a = alpha
	shader_material.set_shader_parameter("shockwave_color", visual_color)

func _draw() -> void:
	if _state == State.WINDUP:
		var telegraph_color := windup_indicator_color
		telegraph_color.a *= minf(_state_time / windup_indicator_fade_duration, 1.0)
		draw_arc(Vector2.ZERO, max_range, 0.0, TAU, 96, telegraph_color, windup_indicator_width)