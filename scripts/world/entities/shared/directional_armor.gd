extends Node2D
class_name DirectionalArmorComponent

signal stress_changed(progress: float)
signal armor_changed(broken: bool)
signal facing_changed(angle: float)

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

func configure(stats: BulwarkStats) -> void:
	_turn_speed = deg_to_rad(stats.turn_speed_degrees)
	_half_arc = deg_to_rad(stats.armor_arc_degrees * 0.5)
	_reduction = clampf(stats.frontal_damage_reduction, 0.0, 0.95)
	_threshold = maxf(1.0, stats.stress_threshold)
	_decay_delay = maxf(0.0, stats.stress_decay_delay)
	_decay_speed = maxf(0.0, stats.stress_decay_per_second)
	_broken_duration = maxf(0.05, stats.armor_broken_duration)
	_stress = 0.0
	_quiet_time = 0.0
	_broken_remaining = 0.0
	stress_changed.emit(0.0)
	armor_changed.emit(false)

func set_enabled(value: bool) -> void:
	_enabled = value

func turn_toward(target_position: Vector2, delta: float) -> void:
	var direction := target_position - global_position
	if not _enabled or not direction.is_finite() or direction.is_zero_approx():
		return
	facing_angle = rotate_toward(facing_angle, direction.angle(), _turn_speed * delta)
	facing_changed.emit(facing_angle)

func get_stress_progress() -> float:
	return clampf(_stress / _threshold, 0.0, 1.0)

func is_broken() -> bool:
	return _broken_remaining > 0.0

func resolve_damage(amount: int, from_position: Vector2, bypass_armor := false) -> int:
	if amount <= 0:
		return 0
	if not _enabled or bypass_armor or is_broken():
		return amount
	var incoming := from_position - global_position
	if not incoming.is_finite() or incoming.is_zero_approx():
		return amount
	if absf(angle_difference(facing_angle, incoming.angle())) > _half_arc:
		return amount
	_stress = minf(_threshold, _stress + float(amount))
	_quiet_time = 0.0
	stress_changed.emit(get_stress_progress())
	if _stress >= _threshold:
		_broken_remaining = _broken_duration
		armor_changed.emit(true)
	return maxi(1, ceili(float(amount) * (1.0 - _reduction)))

func _physics_process(delta: float) -> void:
	if not _enabled:
		return
	if is_broken():
		_broken_remaining = maxf(0.0, _broken_remaining - delta)
		if not is_broken():
			_stress = 0.0
			_quiet_time = 0.0
			armor_changed.emit(false)
			stress_changed.emit(0.0)
		return
	var previous_quiet_time := _quiet_time
	_quiet_time += delta
	if _stress > 0.0 and _quiet_time > _decay_delay:
		var decay_time := _quiet_time - maxf(previous_quiet_time, _decay_delay)
		_stress = maxf(0.0, _stress - _decay_speed * decay_time)
		stress_changed.emit(get_stress_progress())