extends AnimatableBody2D
class_name DirectionalShieldComponent

## Frontal shield: facing, damage reduction, stress/break timer, sprite tint, projectile collider, ram hitbox, and flung wave.

## Stress 0-1; while broken it counts the remaining break time down from 1 so meters refill smoothly.
signal stress_changed(progress: float)
signal broken_changed(broken: bool)
signal shield_hit(amount: int, from_position: Vector2)

## Lives under the drop-animated visuals so it falls with the body; only its rotation is driven here.
@export var sprite: Sprite2D
@export var collision_polygon: CollisionPolygon2D
@export var contact_hitbox: HitboxComponent
## Top-level partial ring; gameplay comes from stats, only its look is edited on that node.
@export var wave: RadialWaveComponent

@export_group("Colors")
@export var armored_color := Color.WHITE
@export var stress_color := Color(1.0, 0.15, 0.1, 1.0)
@export var broken_color := Color(1.0, 0.25, 0.15, 0.4)
@export_range(0.01, 1.0, 0.01) var hit_flash_duration := 0.12

var facing_angle := 0.0
var _turn_speed := deg_to_rad(60.0)
var _half_arc := deg_to_rad(60.0)
var _reduction := 0.75
var _threshold := 30.0
var _decay_delay := 1.0
var _decay_speed := 5.0
var _broken_duration := 4.0
var _stress := 0.0
var _quiet_time := 0.0
var _broken_remaining := 0.0
var _enabled := true
var _hit_flash_tween: Tween

func _ready() -> void:
	assert(sprite and sprite.material is ShaderMaterial and collision_polygon and contact_hitbox and wave, "DirectionalShieldComponent requires its sprite (with hit-flash material), collider, hitbox, and wave")
	# The hit flash writes the sprite's own material; the owner may switch to the body material on death.
	sprite.use_parent_material = false
	wave.set_enabled(true)
	_update_color()

func configure(stats: BulwarkStats) -> void:
	_turn_speed = deg_to_rad(stats.turn_speed_degrees)
	_half_arc = deg_to_rad(stats.armor_arc_degrees * 0.5)
	_reduction = clampf(stats.frontal_damage_reduction, 0.0, 0.95)
	_threshold = maxf(1.0, stats.stress_threshold)
	_decay_delay = maxf(0.0, stats.stress_decay_delay)
	_decay_speed = maxf(0.0, stats.stress_decay_per_second)
	_broken_duration = maxf(0.05, stats.armor_broken_duration)
	contact_hitbox.initialize(stats.shield_damage, stats.shield_knockback)
	wave.ring_thickness = stats.shield_wave_width
	wave.arc_degrees = stats.shield_wave_arc_degrees
	wave.configure_manual(stats.shield_wave_range, stats.shield_wave_range / stats.shield_wave_speed, stats.shield_wave_damage, stats.shield_wave_knockback)
	_stress = 0.0
	_quiet_time = 0.0
	_broken_remaining = 0.0
	_update_color()
	_update_collision()
	stress_changed.emit(0.0)
	broken_changed.emit(false)

func set_enabled(value: bool) -> void:
	_enabled = value
	_update_collision()

func is_broken() -> bool:
	return _broken_remaining > 0.0

func is_active() -> bool:
	return _enabled and not is_broken()

func get_stress_progress() -> float:
	return clampf(_stress / _threshold, 0.0, 1.0)

func set_facing(angle: float) -> void:
	facing_angle = angle
	global_rotation = angle
	sprite.global_rotation = angle

func turn_toward(target_position: Vector2, delta: float) -> void:
	var direction := target_position - global_position
	if _enabled and direction.is_finite() and not direction.is_zero_approx():
		set_facing(rotate_toward(facing_angle, direction.angle(), _turn_speed * delta))

func protects_from(from_position: Vector2) -> bool:
	if not is_active():
		return false
	var incoming := from_position - global_position
	return incoming.is_finite() and not incoming.is_zero_approx() \
		and absf(angle_difference(facing_angle, incoming.angle())) <= _half_arc

## Adds stress and returns the reduced damage; breaks the shield at the threshold.
func resolve_shield_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	if not is_active():
		return amount
	_stress = minf(_threshold, _stress + float(amount))
	_quiet_time = 0.0
	stress_changed.emit(get_stress_progress())
	if _stress >= _threshold:
		_broken_remaining = _broken_duration
		_update_collision()
		broken_changed.emit(true)
	_update_color()
	return maxi(1, ceili(float(amount) * (1.0 - _reduction)))

func was_hit(amount: int, _knockback_force: float, from_position: Vector2) -> void:
	if is_active():
		shield_hit.emit(amount, from_position)

## The shield and its owner's body count as one target for one-hit-per-swing attacks.
func get_hit_receiver() -> Node:
	return get_parent()

func flash_hit() -> void:
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	sprite.material.set_shader_parameter("flash_amount", 1.0)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(sprite.material, "shader_parameter/flash_amount", 0.0, hit_flash_duration)

func launch_wave() -> void:
	if not is_active():
		return
	wave.global_position = global_position
	wave.arc_direction = facing_angle
	wave.execute_shockwave()

func _update_collision() -> void:
	var active := is_active()
	collision_polygon.set_deferred("disabled", not active)
	contact_hitbox.enabled = active
	contact_hitbox.set_deferred("monitoring", active)

func _update_color() -> void:
	sprite.modulate = broken_color if is_broken() else armored_color.lerp(stress_color, get_stress_progress())

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	if is_broken():
		_broken_remaining = maxf(0.0, _broken_remaining - delta)
		if not is_broken():
			_stress = 0.0
			_quiet_time = 0.0
			_update_color()
			_update_collision()
			broken_changed.emit(false)
		stress_changed.emit(_broken_remaining / _broken_duration)
		return
	var previous_quiet_time := _quiet_time
	_quiet_time += delta
	if _stress > 0.0 and _quiet_time > _decay_delay:
		var decay_time := _quiet_time - maxf(previous_quiet_time, _decay_delay)
		_stress = maxf(0.0, _stress - _decay_speed * decay_time)
		_update_color()
		stress_changed.emit(get_stress_progress())

func _exit_tree() -> void:
	if _hit_flash_tween:
		_hit_flash_tween.kill()
