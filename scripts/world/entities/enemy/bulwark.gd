extends EnemyBase
class_name Bulwark

const IDLE_ANIMATION: StringName = &"idle"

@export var stats: BulwarkStats
@export var armor: DirectionalArmorComponent
@export var armor_visual: DirectionalArmorVisual
@export var health_ui: HealthUIComponent
@export var body_sprite: Sprite2D

func _ready() -> void:
	assert(stats and armor and armor_visual and health_ui and body_sprite, "Bulwark requires its stats and owned components")
	_initialize_base(stats)
	contact_hitbox.initialize(stats.damage, stats.knockback)
	targeting.configure(stats.targeting)
	animation.configure_animation(IDLE_ANIMATION, 0, false)
	health_ui.setup(health)
	armor.stress_changed.connect(_on_stress_changed)
	armor.armor_changed.connect(armor_visual.set_broken)
	armor.facing_changed.connect(armor_visual.set_facing)
	armor_visual.configure(stats.armor_arc_degrees)
	armor.configure(stats)
	armor_visual.set_facing(armor.facing_angle)

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
	super.was_hit(armor.resolve_damage(amount, from_position), knockback_force, from_position)

func was_hit_bypassing_armor(amount: int, knockback_force: float, from_position: Vector2) -> void:
	super.was_hit(amount, knockback_force, from_position)

func buff_damage(multiplier: float) -> void:
	contact_hitbox.damage = int(contact_hitbox.damage * multiplier)

func _on_stress_changed(progress: float) -> void:
	health_ui.set_cooldown_progress(progress)
	armor_visual.set_stress(progress)

func _before_handle_death() -> void:
	armor.set_enabled(false)
	health_ui.hide()

func play_spawn_intro(target_position: Vector2, duration: float) -> void:
	health_ui.hide()
	armor.set_enabled(false)
	super.play_spawn_intro(target_position, duration)

func _finish_spawn_intro() -> void:
	armor.set_enabled(true)
	health_ui.show()
	super._finish_spawn_intro()