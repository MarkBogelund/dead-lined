extends EnemyBase
class_name BossEnemyBase

signal boss_landed(shake_intensity: float)
signal boss_intro_finished

@export var intro_animation: AnimationPlayer
@export var intro: Node2D
@export var landing_wave: RadialWaveComponent

const DROP_ANIMATION: StringName = &"drop"
const RESET_ANIMATION: StringName = &"RESET"

func buff_damage(multiplier: float) -> void:
	contact_hitbox.damage = int(contact_hitbox.damage * multiplier)

func play_boss_intro() -> void:
	if _spawn_intro_active:
		return
	assert(intro_animation and intro and landing_wave, "BossEnemyBase requires its shared intro nodes")
	if not intro_animation.animation_finished.is_connected(_on_intro_finished):
		intro_animation.animation_finished.connect(_on_intro_finished)
	animation.stop_animation("idle")
	begin_spawn_intro()
	remove_from_group("enemies")
	intro.top_level = false
	intro.position = Vector2.ZERO
	landing_wave.set_enabled(true)
	intro_animation.play(DROP_ANIMATION)
	intro_animation.advance(0.0)

func _on_intro_finished(animation_name: StringName) -> void:
	if animation_name == DROP_ANIMATION and _spawn_intro_active:
		intro.top_level = true
		intro.global_position = global_position
		_finish_spawn_intro()
		boss_intro_finished.emit()

func _finish_spawn_intro() -> void:
	add_to_group("enemies")
	super._finish_spawn_intro()

func cancel_boss_intro() -> void:
	_spawn_intro_active = false
	landing_wave.set_enabled(false)
	intro_animation.play(RESET_ANIMATION)
	intro_animation.advance(0.0)
	intro_animation.stop(true)
	hide()
	queue_free()