extends Node

func _ready() -> void:
	var base_packed := load("res://scenes/world/enemies/boss_enemy_base.tscn") as PackedScene
	assert(base_packed.get_state().get_base_scene_state() == null)
	var base_scene: Node = base_packed.instantiate()
	var boss := load("res://scenes/world/enemies/bulwark.tscn").instantiate() as Bulwark
	add_child(boss)
	var generic_intro := boss.intro_animation.get_animation(&"intro")
	var base_player := base_scene.get_node("Intro/AnimationPlayer") as AnimationPlayer
	assert(generic_intro == base_player.get_animation(&"intro"))
	assert(generic_intro.find_track(NodePath("Visuals/DropRoot/ShieldSprite:scale"), Animation.TYPE_VALUE) == -1)
	var base_handler := base_scene.get_node("AnimationHandler") as AnimationPlayer
	assert(base_handler.get_animation_library_list() == [&""])
	assert(base_handler.has_animation(&"RESET") and base_handler.has_animation(&"boss_die"))
	assert(not base_scene.has_node("HealthUIComponent"))
	base_scene.free()
	var boss_reset := boss.animation.get_animation(&"RESET")
	var bulwark_reset := boss.animation.get_animation(&"bulwark/RESET")
	assert(boss_reset != bulwark_reset)
	assert(boss_reset.find_track(NodePath("WindupParticles:emitting"), Animation.TYPE_VALUE) >= 0)
	assert(boss.health_ui == boss.get_node("HealthUIComponent"))
	assert(boss.health_ui.scene_file_path == "res://scenes/ui/boss_health_ui.tscn")
	assert(boss.health_ui.secondary_fill_mode == HealthUIComponent.FillMode.DRAIN)
	var windup := boss.get_node("WindupParticles") as GPUParticles2D
	windup.emitting = true
	var shield_intro := boss.animation.get_animation(&"bulwark/intro")
	assert(shield_intro.find_track(NodePath("HealthUIComponent:modulate"), Animation.TYPE_VALUE) >= 0)
	assert(is_equal_approx(shield_intro.length, 0.3))
	boss.play_boss_intro()
	assert(boss._spawn_intro_active and not boss.shield.sprite.visible)
	assert(not windup.emitting and not boss.health_ui.visible)
	await boss.intro_animation.animation_finished
	await get_tree().process_frame
	await get_tree().process_frame
	assert(boss.animation.current_animation == &"bulwark/intro")
	assert(boss._spawn_intro_active and not boss.is_physics_processing())
	assert(not boss.shield.is_active() and boss.health_ui.visible and boss.health_ui.modulate.a < 0.5)
	await boss.boss_intro_finished
	assert(not boss._spawn_intro_active and boss.is_physics_processing())
	assert(boss.shield.is_active() and boss.health_ui.visible and boss.shield.sprite.visible)
	assert(boss.shield.sprite.scale.is_equal_approx(Vector2(1.5, 1.5)))
	assert(is_equal_approx(boss.health_ui.modulate.a, 1.0))
	boss.queue_free()
	var cancelled := load("res://scenes/world/enemies/bulwark.tscn").instantiate() as Bulwark
	add_child(cancelled)
	cancelled.play_boss_intro()
	await cancelled.intro_animation.animation_finished
	await get_tree().process_frame
	cancelled.cancel_boss_intro()
	await get_tree().create_timer(0.5).timeout
	assert(not is_instance_valid(cancelled))
	print("PASS: separate base/Bulwark RESETs, base-owned boss UI hidden during arrival then faded in, shared arrival then shield-only intro, gameplay gating and cancellation during reveal")
	get_tree().quit()