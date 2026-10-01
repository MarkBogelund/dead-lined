extends TurretBase
class_name Missiler

@onready var targeting: TargetingComponent = $TargetingComponent
@onready var aiming: AimingComponent = $AimingComponent

@export var stats: MissilerStats
@export var mortar_scene: PackedScene

var _cooldown := 0.0
var _attack_cooldown := 4.0
var _damage := 25
var _charging := false
var _locked_impact := Vector2.ZERO
var _strike: MortarStrike
var muzzle: Marker2D

func _ready() -> void:
	_initialize()
	super._ready()
	animation.configure_animation("launch", 1, true)

func _initialize() -> void:
	if not stats:
		push_error("%s requires a MissilerStats resource" % name)
		return
	if not mortar_scene:
		push_error("%s requires a mortar_scene" % name)
		return
	targeting.initialize(stats.attack_range)
	targeting.configure(stats.targeting)
	muzzle = aiming.muzzle
	aiming.initialize(5.0, 0.15)
	initialize_base(stats)
	_attack_cooldown = stats.attack_cooldown
	_damage = stats.damage

func _process(delta: float) -> void:
	if not is_turret_active():
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if _charging or _cooldown > 0.0:
		return
	var target := targeting.get_best_target(global_position, _is_valid_target)
	if not target:
		return
	aiming.aim_at(target.global_position, delta)
	if aiming.is_aimed_at(target.global_position):
		_begin_charge(target.global_position)

func _is_valid_target(target: Node2D) -> bool:
	return global_position.distance_to(target.global_position) >= stats.minimum_range

func _begin_charge(impact_position: Vector2) -> void:
	if not animation.play_animation("launch", -1, animation.get_animation_length("launch") / stats.charge_duration):
		return
	_locked_impact = impact_position
	aiming.aim_at(_locked_impact, 0.0)
	_strike = mortar_scene.instantiate() as MortarStrike
	get_tree().current_scene.add_child(_strike)
	_strike.setup(_locked_impact, stats.blast_radius, stats.expansion_duration, _damage, stats.knockback)
	_charging = true

func _launch_strike() -> void:
	if not _charging or not is_instance_valid(_strike):
		return
	_strike.launch(muzzle.global_position, stats.flight_duration, stats.arc_height)
	_strike = null
	_charging = false
	_cooldown = _attack_cooldown

func _cancel_charge() -> void:
	if not _charging:
		return
	_charging = false
	if is_instance_valid(_strike):
		_strike.queue_free()
	_strike = null
	animation.stop_animation("launch")

func _on_combat_started() -> void:
	_cooldown = 0.0

func _on_combat_stopped() -> void:
	_cancel_charge()

func _before_death_animation() -> void:
	_cancel_charge()

func _stop_targeting_player() -> void:
	targeting.set_group_enabled(&"player", false)

func get_damage_value() -> int:
	return _damage

func set_damage(value: int) -> void:
	_damage = value

func set_attack_range(value: float) -> void:
	targeting.max_range = value
	range_indicator.initialize(value)

func set_attack_cooldown(value: float) -> void:
	_attack_cooldown = value