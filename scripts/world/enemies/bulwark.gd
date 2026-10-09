extends BossEnemyBase
class_name Bulwark

const IDLE_ANIMATION: StringName = &"idle"
const SHIELD_CHARGE_ANIMATION: StringName = &"shield_charge"

@export var stats: BulwarkStats
@export var shield: DirectionalShieldComponent
@export var body_sprite: Sprite2D

var _shield_wave_timer := 0.0
var _charging_shield_wave := false

func _ready() -> void:
	assert(stats and shield and body_sprite and health_ui, "Bulwark requires its stats, health UI and owned components")
	_initialize_base(stats)
	contact_hitbox.initialize(stats.damage, stats.knockback)
	targeting.configure(stats.targeting)
	animation.configure_animation(IDLE_ANIMATION, 0, false)
	animation.configure_animation(SHIELD_CHARGE_ANIMATION, 10, true)
	_shield_wave_timer = stats.shield_wave_cooldown
	shield.stress_changed.connect(health_ui.set_secondary_progress)
	shield.broken_changed.connect(_on_shield_broken_changed)
	shield.shield_hit.connect(_apply_shield_damage)
	shield.configure(stats)
	shield.set_facing(shield.facing_angle)

func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
	elif knockback.is_active():
		velocity = knockback.velocity
	else:
		var target := targeting.get_best_target(global_position)
		velocity = navigation.get_safe_velocity(target.global_position, stats.move_speed) if target and not _charging_shield_wave else Vector2.ZERO
		if target:
			shield.turn_toward(target.global_position, delta)
			body_sprite.flip_h = target.global_position.x < global_position.x
			_update_shield_wave(target, delta)
		animation.play_animation(IDLE_ANIMATION)
	knockback.process(delta)
	_apply_environment_velocity()
	move_and_slide()

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

func buff_damage(multiplier: float) -> void:
	super.buff_damage(multiplier)
	shield.contact_hitbox.damage = int(shield.contact_hitbox.damage * multiplier)
	shield.wave.damage = int(shield.wave.damage * multiplier)

func _before_handle_death() -> void:
	_cancel_shield_wave()
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