extends EnemyBase
class_name BossEnemyBase

signal boss_landed(shake_intensity: float)

@export var boss_intro: BossIntroComponent

func play_boss_intro() -> void:
	if _spawn_intro_active:
		return
	assert(boss_intro, "BossEnemyBase requires its owned BossIntroComponent")
	if not boss_intro.landed.is_connected(_on_boss_landed):
		boss_intro.landed.connect(_on_boss_landed)
		boss_intro.finished.connect(_finish_spawn_intro)
	animation.stop_animation("idle")
	begin_spawn_intro()
	remove_from_group("enemies")
	boss_intro.begin()

func _on_boss_landed(shake_intensity: float) -> void:
	boss_landed.emit(shake_intensity)

func _finish_spawn_intro() -> void:
	add_to_group("enemies")
	super._finish_spawn_intro()

func cancel_boss_intro() -> void:
	if boss_intro:
		boss_intro.cancel()
	hide()
	queue_free()