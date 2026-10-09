extends BossEnemyBase
class_name Bulwark

const IDLE_ANIMATION: StringName = &"idle"
const SHIELD_CHARGE_ANIMATION: StringName = &"shield_charge"
## Hide/show the shield via self_modulate: handler RESETs reapply visible/scale before every clip.
const SHIELD_BREAK_ANIMATION: StringName = &"shield_break"
const SHIELD_REGENERATE_ANIMATION: StringName = &"shield_regenerate"
## Retreat directions tried in order when backing off, relative to straight away from the target.
const BACK_OFF_ANGLES: Array[float] = [0.0, PI / 4.0, -PI / 4.0, PI / 2.0, -PI / 2.0]

@export var stats: BulwarkStats
@export var shield: DirectionalShieldComponent
@export var body_sprite: Sprite2D

var _shield_wave_timer := 0.0
var _charging_shield_wave := false
var _shield_broken := false
var _shield_ram_timer := 0.0
var _backing_off := false

func _ready() -> void:
	assert(stats and shield and body_sprite and health_ui, "Bulwark requires its stats, health UI and owned components")
	_initialize_base(stats)
	contact_hitbox.initialize(stats.damage, stats.knockback)
	targeting.configure(stats.targeting)
	animation.configure_animation(IDLE_ANIMATION, 0, false)
	animation.configure_animation(SHIELD_CHARGE_ANIMATION, 10, true)
	animation.configure_animation(SHIELD_BREAK_ANIMATION, 11, true)
	animation.configure_animation(SHIELD_REGENERATE_ANIMATION, 11, true)
	_shield_wave_timer = stats.shield_wave_cooldown
	shield.stress_changed.connect(health_ui.set_secondary_progress)
	shield.broken_changed.connect(_on_shield_broken_changed)
	shield.shield_hit.connect(_apply_shield_damage)
	shield.contact_hitbox.hit_target.connect(_on_shield_rammed)
	shield.configure(stats)
	shield.set_facing(shield.facing_angle)

func _physics_process(delta: float) -> void:
	_shield_ram_timer = maxf(0.0, _shield_ram_timer - delta)
	if is_dead():
		velocity = Vector2.ZERO
	elif knockback.is_active():
		velocity = knockback.velocity
	else:
		var target := targeting.get_best_target(global_position)
		if target and not _charging_shield_wave and _update_back_off(target):
			# Backing off restarts the ram cooldown, so it then holds instead of jittering at the boundary.
			_shield_ram_timer = stats.shield_ram_cooldown
			velocity = _get_back_off_velocity(target)
		else:
			var advancing := target and not _charging_shield_wave and not _is_holding_for_ram(target)
			velocity = navigation.get_safe_velocity(target.global_position, stats.move_speed) if advancing else Vector2.ZERO
		if target:
			shield.turn_toward(target.global_position, delta)
			body_sprite.flip_h = target.global_position.x < global_position.x
			_update_shield_wave(target, delta)
		animation.play_animation(IDLE_ANIMATION)
	knockback.process(delta)
	_apply_environment_velocity()
	move_and_slide()

## While the ram cools down, stay just outside shield reach so targets never end up inside the shield.
func _is_holding_for_ram(target: Node2D) -> bool:
	return shield.is_active() and _shield_ram_timer > 0.0 \
		and global_position.distance_to(target.global_position) <= stats.shield_ram_hold_distance

## Starts backing off when the target gets inside the shield and keeps going until it is out of shield reach.
func _update_back_off(target: Node2D) -> bool:
	var distance := global_position.distance_to(target.global_position)
	if not shield.is_active() or distance >= stats.shield_ram_hold_distance:
		_backing_off = false
	elif distance < stats.shield_ram_min_distance:
		_backing_off = true
	return _backing_off

## Heads for the first walkable point outside shield reach; avoidance is skipped since the target's obstacle zeroes it.
func _get_back_off_velocity(target: Node2D) -> Vector2:
	var away := global_position - target.global_position
	away = away.normalized() if not away.is_zero_approx() else Vector2.from_angle(shield.facing_angle + PI)
	var map := navigation.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(map) == 0:
		return away * stats.move_speed
	var reach := stats.shield_ram_hold_distance + 8.0
	for angle: float in BACK_OFF_ANGLES:
		var point := NavigationServer2D.map_get_closest_point(map, target.global_position + away.rotated(angle) * reach)
		var step := point - global_position
		if point.distance_to(target.global_position) >= stats.shield_ram_hold_distance and step.length() > 1.0:
			return step.normalized() * stats.move_speed
	return away * stats.move_speed

func _on_shield_rammed(target: Node) -> void:
	if is_dead() or not target is Node2D:
		return
	_shield_ram_timer = stats.shield_ram_cooldown
	knockback.apply((target as Node2D).global_position, stats.shield_ram_recoil)

func _update_shield_wave(target: Node2D, delta: float) -> void:
	if _charging_shield_wave or not shield.is_active():
		return
	_shield_wave_timer -= delta
	if _shield_wave_timer <= 0.0 and global_position.distance_to(target.global_position) <= stats.shield_wave_trigger_range:
		_charging_shield_wave = animation.play_animation(SHIELD_CHARGE_ANIMATION)

## Called by the shield_charge animation at its release frame.
func launch_shield_wave() -> void:
	_charging_shield_wave = false
	_shield_wave_timer = stats.shield_wave_cooldown
	shield.launch_wave()

func _cancel_shield_wave() -> void:
	if _charging_shield_wave:
		_charging_shield_wave = false
		_shield_wave_timer = stats.shield_wave_cooldown
		animation.stop_animation(SHIELD_CHARGE_ANIMATION)

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead() or _spawn_intro_active:
		return
	if shield.protects_from(from_position):
		_apply_shield_damage(amount, from_position)
	else:
		super.was_hit(amount, knockback_force, from_position)

func was_hit_bypassing_armor(amount: int, knockback_force: float, from_position: Vector2) -> void:
	super.was_hit(amount, knockback_force, from_position)

func _apply_shield_damage(amount: int, from_position: Vector2) -> void:
	var was_fatal := health.take_damage(shield.resolve_shield_damage(amount))
	knockback.apply(from_position, 0.0)
	shield.flash_hit()
	if was_fatal:
		_handle_death(from_position, 0.0)

func _on_shield_broken_changed(broken: bool) -> void:
	if broken:
		_cancel_shield_wave()
		_shield_broken = true
		animation.play_animation(SHIELD_BREAK_ANIMATION)
	elif _shield_broken:
		_shield_broken = false
		animation.play_animation(SHIELD_REGENERATE_ANIMATION)

func buff_damage(multiplier: float) -> void:
	super.buff_damage(multiplier)
	shield.contact_hitbox.damage = int(shield.contact_hitbox.damage * multiplier)
	shield.wave.damage = int(shield.wave.damage * multiplier)

func _before_handle_death() -> void:
	_cancel_shield_wave()
	animation.stop_animation(SHIELD_BREAK_ANIMATION)
	animation.stop_animation(SHIELD_REGENERATE_ANIMATION)
	shield.set_enabled(false)
	shield.sprite.use_parent_material = true
	super._before_handle_death()

func begin_spawn_intro() -> void:
	shield.set_enabled(false)
	shield.sprite.hide()
	super.begin_spawn_intro()

func _finish_spawn_intro() -> void:
	shield.set_enabled(true)
	super._finish_spawn_intro()