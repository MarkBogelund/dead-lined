extends Node2D
class_name BeamComponent

signal windup_started
signal firing_started

enum State {IDLE, WINDUP, FIRING}

@onready var beam_area: Area2D = $BeamArea
@onready var beam_shape: CollisionShape2D = $BeamArea/CollisionShape2D
@onready var speed_particles: GPUParticles2D = $SpeedParticles

@export var pixel_rotate_shader: Shader
@export var beam_color: Color = Color(0.2, 0.85, 1.0, 1.0):
	set(value):
		beam_color = value
		if is_instance_valid(_beam_visual):
			_beam_visual.texture = _create_beam_texture()
@export var beam_center_color: Color = Color(0.85, 1.0, 1.0, 1.0):
	set(value):
		beam_center_color = value
		if is_instance_valid(_beam_visual):
			_beam_visual.texture = _create_beam_texture()

var beam_length := 180.0
var beam_width := 12.0
var damage_interval := 0.3
var windup_duration := 0.55
var lock_break_distance := 5.0
var damage := 4
var knockback := 0.0
var sweep_speed := deg_to_rad(45.0)
var tracking_speed := deg_to_rad(24.0)

var _enabled := false
var _state := State.IDLE
var _state_time := 0.0
var _sweep_angle := 0.0
var _locked_target: Node2D
var _target_cooldowns: Dictionary[int, float] = {}
var _beam_visual: PixelRotatedSprite

const BEAM_START_OFFSET := 6.0
const BEAM_TEXTURE_HEIGHT := 16
const BEAM_EDGE_RADIUS := 8.0

func _ready() -> void:
	beam_shape.shape = RectangleShape2D.new()
	if not pixel_rotate_shader:
		push_error("%s requires pixel_rotate_shader" % name)
		return
	_beam_visual = PixelRotatedSprite.new()
	_beam_visual.name = "BeamVisual"
	_beam_visual.pixel_shader = pixel_rotate_shader
	_beam_visual.start_offset = BEAM_START_OFFSET
	add_child(_beam_visual)
	_update_geometry()

func configure(p_range: float, p_width: float, p_damage_interval: float, p_windup_duration: float, p_lock_break_distance: float, p_damage: int, p_knockback: float, p_sweep_speed_degrees: float, p_tracking_speed_degrees: float) -> void:
	beam_length = maxf(1.0, p_range)
	beam_width = maxf(1.0, p_width)
	damage_interval = maxf(0.05, p_damage_interval)
	windup_duration = maxf(0.05, p_windup_duration)
	lock_break_distance = maxf(0.0, p_lock_break_distance)
	damage = maxi(0, p_damage)
	knockback = maxf(0.0, p_knockback)
	sweep_speed = deg_to_rad(p_sweep_speed_degrees)
	tracking_speed = deg_to_rad(p_tracking_speed_degrees)
	_update_geometry()

func set_enabled(value: bool) -> void:
	if _enabled == value:
		return
	_enabled = value
	_state_time = 0.0
	_locked_target = null
	_target_cooldowns.clear()
	if not value:
		_state = State.IDLE
		_beam_visual.fade_to(0.0)
		return
	_state = State.WINDUP
	_beam_visual.fade_to(0.0)
	windup_started.emit()

func set_range(value: float) -> void:
	beam_length = maxf(1.0, value)
	_update_geometry()

func set_damage(value: int) -> void:
	damage = maxi(0, value)

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	_update_aim(delta)
	_update_sweep_transforms()
	_state_time += delta
	match _state:
		State.WINDUP:
			if _state_time >= windup_duration:
				_state = State.FIRING
				_state_time = 0.0
				_target_cooldowns.clear()
				_beam_visual.fade_to(1.0)
				firing_started.emit()
		State.FIRING:
			_damage_overlapped_targets(delta)

func _update_geometry() -> void:
	if not is_node_ready():
		return
	var shape := beam_shape.shape as RectangleShape2D
	shape.size = Vector2(beam_length, beam_width)
	_beam_visual.texture = _create_beam_texture()
	_update_sweep_transforms()

func _update_sweep_transforms() -> void:
	beam_area.global_rotation = global_rotation + _sweep_angle
	beam_area.global_position = global_position + Vector2(beam_length * 0.5, 0.0).rotated(global_rotation + _sweep_angle)
	speed_particles.position = Vector2.ZERO
	speed_particles.rotation = _sweep_angle
	if is_instance_valid(_beam_visual):
		_beam_visual.point_at(_sweep_angle)

func _create_beam_texture() -> Texture2D:
	var texture_width := maxi(1, ceili(beam_length - BEAM_START_OFFSET))
	var image := Image.create(texture_width, BEAM_TEXTURE_HEIGHT, false, Image.FORMAT_RGBA8)
	var center_y := float(BEAM_TEXTURE_HEIGHT) * 0.5
	var segment_start := minf(BEAM_EDGE_RADIUS, float(texture_width) * 0.5)
	var segment_end := maxf(segment_start, float(texture_width) - BEAM_EDGE_RADIUS)
	for y in range(BEAM_TEXTURE_HEIGHT):
		for x in range(texture_width):
			var sample_x := float(x) + 0.5
			var closest_x := clampf(sample_x, segment_start, segment_end)
			var distance := Vector2(sample_x - closest_x, float(y) + 0.5 - center_y).length()
			if distance > BEAM_EDGE_RADIUS:
				continue
			if distance <= 2.0:
				var core_color := beam_center_color
				core_color.a *= 0.95
				image.set_pixel(x, y, core_color)
			else:
				var glow_alpha := lerpf(0.4, 0.12, (distance - 2.0) / (BEAM_EDGE_RADIUS - 2.0))
				var glow_color := beam_color
				glow_color.a *= glow_alpha
				image.set_pixel(x, y, glow_color)
	return ImageTexture.create_from_image(image)

func _update_aim(delta: float) -> void:
	if is_instance_valid(_locked_target):
		if _can_track_target(_locked_target):
			var target_angle := (_locked_target.global_position - global_position).angle()
			_sweep_angle = rotate_toward(_sweep_angle, target_angle, tracking_speed * delta)
			return
		_locked_target = null
	_sweep_angle = wrapf(_sweep_angle + sweep_speed * delta, -PI, PI)

func _damage_overlapped_targets(delta: float) -> void:
	var active_targets: Dictionary[int, bool] = {}
	for body: Node2D in beam_area.get_overlapping_bodies():
		if not _is_damageable(body):
			continue
		var target_id := body.get_instance_id()
		active_targets[target_id] = true
		var time_left: float = maxf(0.0, _target_cooldowns.get(target_id, 0.0) - delta)
		if time_left > 0.0:
			_target_cooldowns[target_id] = time_left
			continue
		if not _has_clear_path(body.global_position):
			_target_cooldowns.erase(target_id)
			continue
		if not is_instance_valid(_locked_target):
			_locked_target = body
		var target_knockback := knockback if body.is_in_group("enemies") else 0.0
		body.was_hit(damage, target_knockback, global_position)
		_target_cooldowns[target_id] = damage_interval
	for target_id: int in _target_cooldowns.keys():
		if not active_targets.has(target_id):
			_target_cooldowns.erase(target_id)

func _is_damageable(body: Node2D) -> bool:
	if not body.has_method("was_hit"):
		return false
	if body.has_method("is_dead") and body.is_dead():
		return false
	return body.is_in_group("player") or body.is_in_group("enemies")

func _can_track_target(body: Node2D) -> bool:
	return _is_damageable(body) \
		and global_position.distance_squared_to(body.global_position) <= beam_length * beam_length \
		and _has_clear_path(body.global_position) \
		and (beam_area.get_overlapping_bodies().has(body) or _distance_from_beam(body.global_position) <= lock_break_distance)

func _distance_from_beam(target_position: Vector2) -> float:
	var beam_direction := Vector2.from_angle(global_rotation + _sweep_angle)
	var along_beam := clampf((target_position - global_position).dot(beam_direction), 0.0, beam_length)
	var closest_point := global_position + beam_direction * along_beam
	return maxf(0.0, target_position.distance_to(closest_point) - beam_width * 0.5)

func _has_clear_path(target_position: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target_position, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()