extends Node

func _ready() -> void:
	var base_scene: Node = load("res://scenes/world/enemies/boss_enemy_base.tscn").instantiate()
	var boss := load("res://scenes/world/enemies/bulwark.tscn").instantiate() as Bulwark
	add_child(boss)
	var generic_intro := boss.intro_animation.get_animation(&"intro")
	var base_player := base_scene.get_node("Intro/AnimationPlayer") as AnimationPlayer
	assert(generic_intro == base_player.get_animation(&"intro"))
	assert(generic_intro.find_track(NodePath("Visuals/DropRoot/ShieldSprite:scale"), Animation.TYPE_VALUE) == -1)
	base_scene.free()
	var shield_intro := boss.animation.get_animation(&"bulwark/intro")
	assert(shield_intro.get_track_count() == 2)
	assert(is_equal_approx(shield_intro.length, 0.3))
	boss.play_boss_intro()
	assert(boss._spawn_intro_active and not boss.shield.sprite.visible)
	await boss.intro_animation.animation_finished
	await get_tree().process_frame
	await get_tree().process_frame
	assert(boss.animation.current_animation == &"bulwark/intro")
	assert(boss._spawn_intro_active and not boss.is_physics_processing())
	assert(not boss.shield.is_active() and not boss.health_ui.visible)
	await boss.boss_intro_finished
	assert(not boss._spawn_intro_active and boss.is_physics_processing())
	assert(boss.shield.is_active() and boss.health_ui.visible and boss.shield.sprite.visible)
	assert(boss.shield.sprite.scale.is_equal_approx(Vector2(1.5, 1.5)))
	boss.queue_free()
	var cancelled := load("res://scenes/world/enemies/bulwark.tscn").instantiate() as Bulwark
	add_child(cancelled)
	cancelled.play_boss_intro()
	await cancelled.intro_animation.animation_finished
	await get_tree().process_frame
	cancelled.cancel_boss_intro()
	await get_tree().create_timer(0.5).timeout
	assert(not is_instance_valid(cancelled))
	print("PASS: inherited shared arrival then shield-only AnimationHandler intro, gameplay gating, shield endpoint and cancellation during reveal")
	get_tree().quit()