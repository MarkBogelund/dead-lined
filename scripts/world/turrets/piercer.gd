extends TurretBase
class_name Piercer

const WORLD_COLLISION_MASK := 1
const TARGET_COLLISION_MASK := 42
const WALL_QUERY_DISTANCE := 10000.0

@onready var targeting: TargetingComponent = $TargetingComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var laser_graphics: LaserGraphics = $LaserGraphics

@export var stats: PiercerStats
## Groups the laser damages; it pierces all of them and ignores armor.
@export var hit_groups: Array[StringName] = [&"enemies", &"player"]

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
	laser_graphics.fade_finished.connect(_on_laser_fade_finished)
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
	_locked_direction = aiming.get_visual_aim_direction().normalized()
	if _show_laser(_locked_origin, _locked_direction) > 0.0:
		laser_graphics.show_telegraph()
	var charge_length := animation.get_animation_length("charge")
	animation.play_animation("charge", -1, charge_length / stats.charge_duration)

func _fire_locked_shot() -> void:
	_charging = false
	animation.stop_animation("charge")
	_has_fired = true
	_cooldown_remaining = _attack_cooldown
	var beam_length := _show_laser(_locked_origin, _locked_direction)
	if beam_length <= 0.0:
		laser_graphics.cancel_telegraph()
		aiming.unlock_aim()
		return
	_laser_active = true
	laser_graphics.show_fire()
	_damage_line(_locked_origin, _locked_direction, beam_length)

## Draws the laser up to the first wall and returns its length.
func _show_laser(origin: Vector2, direction: Vector2) -> float:
	var beam_length := _get_clear_length(origin, direction)
	if beam_length > 0.0:
		laser_graphics.show_segment(origin, origin + direction * beam_length)
	return beam_length

## Shortest wall distance of three parallel rays spanning the laser's width.
func _get_clear_length(origin: Vector2, direction: Vector2) -> float:
	var space_state := get_world_2d().direct_space_state
	var perpendicular := direction.orthogonal()
	var edge_offset := maxf(0.5, laser_graphics.laser_width * 0.5)
	var clear_length := WALL_QUERY_DISTANCE
	for offset: float in [0.0, -edge_offset, edge_offset]:
		var ray_start := origin + perpendicular * offset
		var query := PhysicsRayQueryParameters2D.create(ray_start, ray_start + direction * WALL_QUERY_DISTANCE, WORLD_COLLISION_MASK)
		var hit := space_state.intersect_ray(query)
		if not hit.is_empty():
			var hit_position: Vector2 = hit["position"]
			clear_length = minf(clear_length, maxf(0.0, (hit_position - origin).dot(direction)))
	return clear_length

func _damage_line(origin: Vector2, direction: Vector2, beam_length: float) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(beam_length, laser_graphics.laser_width)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(direction.angle(), origin + direction * beam_length * 0.5)
	query.collision_mask = TARGET_COLLISION_MASK
	query.exclude = [get_rid()]
	var hit_ids: Dictionary[int, bool] = {}
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 128):
		var target := result.get("collider") as Node2D
		if not target or hit_ids.has(target.get_instance_id()) or not HitboxComponent.can_hit(target, hit_groups):
			continue
		hit_ids[target.get_instance_id()] = true
		HitboxComponent.apply_hit(target, _damage, stats.knockback, origin, true)

func _on_laser_fade_finished(target_alpha: float) -> void:
	if not is_zero_approx(target_alpha) or not _laser_active:
		return
	_laser_active = false
	aiming.unlock_aim()

func _cancel_charge() -> void:
	if not _charging:
		return
	_charging = false
	_charge_remaining = 0.0
	animation.stop_animation("charge")
	laser_graphics.cancel_telegraph()
	aiming.unlock_aim()

func _on_combat_started() -> void:
	_has_fired = false
	_cooldown_remaining = stats.first_shot_delay

func _on_combat_stopped() -> void:
	_cancel_charge()
	if _laser_active:
		laser_graphics.cancel_telegraph()

func _before_death_animation() -> void:
	_cancel_charge()
	if _laser_active:
		laser_graphics.cancel_telegraph()

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