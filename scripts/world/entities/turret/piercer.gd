extends TurretBase
class_name Piercer

@onready var targeting: TargetingComponent = $TargetingComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var laser: PiercerLaser = $LaserComponent

@export var stats: PiercerStats

var _damage := 0
var _attack_range := 0.0
var _attack_cooldown := 0.0
var _cooldown_remaining := 0.0
var _charging := false
var _laser_active := false
var _has_fired := false
var _charge_remaining := 0.0
var _locked_origin := Vector2.ZERO
var _locked_direction := Vector2.RIGHT

func _ready() -> void:
	_initialize()
	laser.visual_finished.connect(_on_laser_visual_finished)
	animation.configure_animation("charge", 2, true)
	super._ready()

func _initialize() -> void:
	if not stats:
		push_error("%s requires a PiercerStats resource" % name)
		return
	initialize_base(stats)
	targeting.initialize(stats.attack_range)
	targeting.configure(stats.targeting)
	aiming.initialize(stats.aim_speed, stats.aim_tolerance)
	_damage = stats.damage
	_attack_range = stats.attack_range
	_attack_cooldown = stats.attack_cooldown

func _process(delta: float) -> void:
	if _has_fired and is_turret_active():
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	if _charging:
		if not is_turret_active():
			_cancel_charge()
			return
		_charge_remaining -= delta
		if _charge_remaining <= 0.0:
			_fire_locked_shot()
		return
	if _laser_active:
		return
	if not is_turret_active():
		return
	if not _has_fired:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	var target := targeting.get_best_target(global_position, _is_visible_target)
	if not target:
		return
	aiming.aim_at(target.global_position, delta)
	if _cooldown_remaining <= 0.0 \
			and aiming.is_aimed_at(target.global_position) \
			and aiming.is_visual_aim_settled():
		_begin_charge()

func _is_visible_target(target: Node2D) -> bool:
	return target != self and line_of_sight.can_see(global_position, target.global_position)

func _begin_charge() -> void:
	if _charging or not is_turret_active():
		return
	_charging = true
	_charge_remaining = stats.charge_duration
	aiming.lock_aim()
	_locked_origin = aiming.get_muzzle_position()
	_locked_direction = aiming.get_visual_aim_direction()
	laser.show_telegraph(_locked_origin, _locked_direction, stats.charge_duration)
	var charge_length := animation.get_animation_length("charge")
	animation.play_animation("charge", -1, charge_length / stats.charge_duration)

func _fire_locked_shot() -> void:
	_charging = false
	animation.stop_animation("charge")
	_laser_active = true
	laser.fire(_locked_origin, _locked_direction, _damage, stats.knockback, self)
	_has_fired = true
	_cooldown_remaining = _attack_cooldown

func _on_laser_visual_finished() -> void:
	if not _laser_active:
		return
	_laser_active = false
	aiming.unlock_aim()

func _cancel_charge() -> void:
	if not _charging:
		return
	_charging = false
	_charge_remaining = 0.0
	animation.stop_animation("charge")
	laser.cancel_telegraph()
	aiming.unlock_aim()

func _on_combat_started() -> void:
	_has_fired = false
	_cooldown_remaining = stats.first_shot_delay

func _on_combat_stopped() -> void:
	_cancel_charge()
	if _laser_active:
		laser.cancel_telegraph()

func _before_death_animation() -> void:
	_cancel_charge()
	if _laser_active:
		laser.cancel_telegraph()

func _stop_targeting_player() -> void:
	targeting.set_group_enabled(&"player", false)

func get_damage_value() -> int:
	return _damage

func get_attack_cooldown_progress() -> float:
	if not _has_fired or _attack_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _cooldown_remaining / _attack_cooldown, 0.0, 1.0)

func set_damage(value: int) -> void:
	_damage = value

func set_attack_range(value: float) -> void:
	_attack_range = value
	targeting.max_range = value
	range_indicator.initialize(value)

func set_attack_cooldown(value: float) -> void:
	_attack_cooldown = value