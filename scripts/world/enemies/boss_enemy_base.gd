extends EnemyBase
class_name BossEnemyBase

signal boss_landed(shake_intensity: float)
signal boss_death_shake_requested(shake_intensity: float)
signal boss_intro_finished
signal boss_alert_changed(active: bool)

@export var intro_animation: AnimationPlayer
@export var intro: Node2D
@export var landing_wave: RadialWaveComponent

const INTRO_ANIMATION: StringName = &"intro"
const RESET_ANIMATION: StringName = &"RESET"
const BOSS_DEATH_ANIMATION: StringName = &"boss_die"

func buff_damage(multiplier: float) -> void:
	contact_hitbox.damage = int(contact_hitbox.damage * multiplier)

func emit_boss_landed(shake_intensity: float) -> void:
	boss_landed.emit(shake_intensity)

func emit_boss_death_shake(shake_intensity: float) -> void:
	boss_death_shake_requested.emit(shake_intensity)

func emit_boss_alert(active: bool) -> void:
	boss_alert_changed.emit(active)

func _get_death_animation_name() -> StringName:
	return BOSS_DEATH_ANIMATION

func play_boss_intro() -> void:
	if _spawn_intro_active:
		return
	assert(intro_animation and intro and landing_wave, "BossEnemyBase requires its shared intro nodes")
	if not intro_animation.animation_finished.is_connected(_on_intro_finished):
		intro_animation.animation_finished.connect(_on_intro_finished)
	if not animation.animation_finished.is_connected(_on_boss_specific_intro_finished):
		animation.animation_finished.connect(_on_boss_specific_intro_finished)
	if animation.has_configured_animation(INTRO_ANIMATION):
		animation.configure_animation(INTRO_ANIMATION, 1, true)
	animation.stop_animation("idle")
	begin_spawn_intro()
	remove_from_group("enemies")
	intro.top_level = false
	intro.position = Vector2.ZERO
	landing_wave.set_enabled(true)
	intro_animation.play(INTRO_ANIMATION)
	intro_animation.advance(0.0)

func _on_intro_finished(animation_name: StringName) -> void:
	if animation_name == INTRO_ANIMATION and _spawn_intro_active:
		intro.top_level = true
		intro.global_position = global_position
		if animation.has_configured_animation(INTRO_ANIMATION) and animation.play_animation(INTRO_ANIMATION):
			return
		_complete_boss_intro()

func _on_boss_specific_intro_finished(animation_name: StringName) -> void:
	if String(animation_name).get_file() == String(INTRO_ANIMATION) and _spawn_intro_active:
		_complete_boss_intro()

func _complete_boss_intro() -> void:
	_finish_spawn_intro()
	boss_intro_finished.emit()

func _finish_spawn_intro() -> void:
	add_to_group("enemies")
	super._finish_spawn_intro()

func cancel_boss_intro() -> void:
	_spawn_intro_active = false
	animation.stop_animation(INTRO_ANIMATION)
	boss_alert_changed.emit(false)
	landing_wave.set_enabled(false)
	intro_animation.play(RESET_ANIMATION)
	intro_animation.advance(0.0)
	intro_animation.stop(true)
	hide()
	queue_free()