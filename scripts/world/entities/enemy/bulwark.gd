extends BossEnemyBase
class_name Bulwark

const IDLE_ANIMATION: StringName = &"idle"

@export var stats: BulwarkStats
@export var armor: DirectionalArmorComponent
@export var armor_visual: DirectionalArmorVisual
@export var health_ui: HealthUIComponent
@export var body_sprite: Sprite2D
@export var shield: ArmorShieldComponent

func _ready() -> void:
	assert(stats and armor and armor_visual and health_ui and body_sprite and shield, "Bulwark requires its stats and owned components")
	_initialize_base(stats)
	contact_hitbox.initialize(stats.damage, stats.knockback)
	targeting.configure(stats.targeting)
	animation.configure_animation(IDLE_ANIMATION, 0, false)
	health_ui.setup(health)
	armor.stress_changed.connect(_on_stress_changed)
	armor.armor_changed.connect(_on_armor_changed)
	armor.facing_changed.connect(armor_visual.set_facing)
	armor.facing_changed.connect(shield.set_facing)
	shield.shield_hit.connect(_on_shield_hit)
	armor.configure(stats)
	armor_visual.set_facing(armor.facing_angle)
	shield.set_facing(armor.facing_angle)

func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
	elif knockback.is_active():
		velocity = knockback.velocity
	else:
		var target := targeting.get_best_target(global_position)
		velocity = navigation.get_safe_velocity(target.global_position, stats.move_speed) if target else Vector2.ZERO
		if target:
			armor.turn_toward(target.global_position, delta)
			body_sprite.flip_h = target.global_position.x < global_position.x
		animation.play_animation(IDLE_ANIMATION)
	knockback.process(delta)
	_apply_environment_velocity()
	move_and_slide()

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead() or _spawn_intro_active:
		return
	var protected := armor.protects_from(from_position)
	if protected:
		_apply_shield_damage(amount, from_position)
	else:
		super.was_hit(amount, knockback_force, from_position)

func was_hit_bypassing_armor(amount: int, knockback_force: float, from_position: Vector2) -> void:
	super.was_hit(amount, knockback_force, from_position)

func _on_shield_hit(amount: int, from_position: Vector2) -> void:
	if is_dead() or _spawn_intro_active or armor.is_broken():
		return
	_apply_shield_damage(amount, from_position)

func _apply_shield_damage(amount: int, from_position: Vector2) -> void:
	var was_fatal := health.take_damage(armor.resolve_shield_damage(amount))
	knockback.apply(from_position, 0.0)
	armor_visual.flash_hit()
	if was_fatal:
		_handle_death(from_position, 0.0)

func _on_armor_changed(broken: bool) -> void:
	armor_visual.set_broken(broken)
	shield.set_enabled(not broken and not is_dead() and not _spawn_intro_active)

func buff_damage(multiplier: float) -> void:
	contact_hitbox.damage = int(contact_hitbox.damage * multiplier)

func _on_stress_changed(progress: float) -> void:
	health_ui.set_cooldown_progress(progress)
	armor_visual.set_stress(progress)

func _before_handle_death() -> void:
	armor.set_enabled(false)
	shield.set_enabled(false)
	health_ui.hide()

func begin_spawn_intro() -> void:
	health_ui.hide()
	armor.set_enabled(false)
	shield.set_enabled(false)
	super.begin_spawn_intro()

func _finish_spawn_intro() -> void:
	armor.set_enabled(true)
	shield.set_enabled(not armor.is_broken())
	health_ui.show()
	super._finish_spawn_intro()