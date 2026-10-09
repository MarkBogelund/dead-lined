extends Node

class RecordingSafeSpot extends SafeSpotComponent:
	var clear_points: Array[Vector2] = []
	var clearance_checks := 0

	func is_point_clear(point: Vector2) -> bool:
		clearance_checks += 1
		var clear := super.is_point_clear(point)
		if clear:
			clear_points.append(point)
		return clear

const BULWARK_SCENE: PackedScene = preload("res://scenes/world/enemies/bulwark.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/game.tscn")
const SHOCKWAVER_SCENE: PackedScene = preload("res://scenes/world/turrets/shockwaver.tscn")
const CHASER_SCENE: PackedScene = preload("res://scenes/world/enemies/chaser.tscn")
const SHOTGUNNER_SCENE: PackedScene = preload("res://scenes/world/enemies/shotgunner.tscn")
const PLAYER_PROJECTILE_SCENE: PackedScene = preload("res://scenes/world/projectiles/player_projectile.tscn")
const TURRET_PROJECTILE_SCENE: PackedScene = preload("res://scenes/world/projectiles/turret_projectile.tscn")
const EMITTER_SCENE: PackedScene = preload("res://scenes/world/enemies/emitter.tscn")

var _spawned_boss: Bulwark
var _boss_count := 0
var _boss_spawn_position := Vector2.INF
var _normal_spawns: Array[EnemyBase] = []
var _spawn_positions: Array[Vector2] = []
var _cleared_count := 0
var _shield_impacts := 0

func _ready() -> void:
	_run.call_deferred()

func _new_boss(at: Vector2) -> Bulwark:
	var boss := BULWARK_SCENE.instantiate() as Bulwark
	boss.position = at
	add_child(boss)
	boss.set_physics_process(false)
	boss.shield.set_physics_process(false)
	boss.shield.configure(BulwarkStats.new())
	return boss

func _run() -> void:
	await _test_targeting()
	if "--targeting-only" in OS.get_cmdline_user_args():
		get_tree().quit()
		return
	if "--spawn-only" in OS.get_cmdline_user_args():
		await _test_spawning()
		await _test_distribution()
		print("PASS: spawn-focused regressions")
		get_tree().quit()
		return
	var boss := _new_boss(Vector2(1000, 1000))
	var second := _new_boss(Vector2(2000, 2000))
	var max_hp := boss.stats.max_health
	assert(boss.health.max_health == max_hp and max_hp > 20)
	assert(boss.shield.sprite is Sprite2D)
	assert(boss.shield.sprite.modulate.is_equal_approx(boss.shield.armored_color))
	assert(boss.health_ui.level_label == null)
	assert(boss.health_ui.scene_file_path == "res://scenes/ui/boss_health_ui.tscn")
	assert(boss.health_ui.secondary_fill_mode == HealthUIComponent.FillMode.DRAIN)
	assert(is_equal_approx(boss.health_ui.secondary_bar.size.x, boss.health_ui.get_full_width(boss.health_ui.secondary_bar)))
	var front := boss.position + Vector2(100, 0)
	var body_material := boss.get_node("Visuals").get("material") as ShaderMaterial
	var shield_material := boss.shield.sprite.material as ShaderMaterial
	assert(shield_material != body_material)
	assert(shield_material != second.shield.sprite.material)
	boss.was_hit(8, 200.0, front)
	assert(boss.health.current_health == max_hp - 2)
	boss.animation.advance(0.01)
	assert(is_zero_approx(float(body_material.get_shader_parameter("flash_amount"))))
	assert(is_equal_approx(float(shield_material.get_shader_parameter("flash_amount")), 1.0))
	assert(is_zero_approx(float((second.shield.sprite.material as ShaderMaterial).get_shader_parameter("flash_amount"))))
	assert(boss.knockback.velocity.is_zero_approx())
	assert(is_equal_approx(boss.shield.get_stress_progress(), 8.0 / 30.0))
	var ui := boss.health_ui
	assert(is_equal_approx(ui.secondary_bar.size.x, ui.get_full_width(ui.secondary_bar) * 22.0 / 30.0))
	assert(is_equal_approx(ui.primary_bar.size.x, ui.get_full_width(ui.primary_bar) * float(max_hp - 2) / max_hp))
	assert(second.health.current_health == max_hp and second.shield.get_stress_progress() == 0.0)
	boss.was_hit(8, 200.0, boss.position + Vector2(-100, 0))
	assert(boss.health.current_health == max_hp - 10)
	await get_tree().process_frame
	boss.animation.advance(0.01)
	assert(float(body_material.get_shader_parameter("flash_amount")) > 0.0)
	assert(is_equal_approx(boss.knockback.velocity.length(), 200.0))
	boss.was_hit_bypassing_armor(8, 0.0, front)
	assert(boss.health.current_health == max_hp - 18)
	assert(is_equal_approx(boss.shield.get_stress_progress(), 8.0 / 30.0))
	var tuning := BulwarkStats.new()
	tuning.stress_threshold = 10.0
	tuning.armor_broken_duration = 0.2
	boss.shield.configure(tuning)
	boss.shield.resolve_shield_damage(8)
	boss.knockback.velocity = Vector2.ZERO
	boss.was_hit(2, 200.0, front)
	assert(boss.knockback.velocity.is_zero_approx())
	assert(boss.shield.is_broken())
	assert(not boss.shield.is_active())
	assert(boss.shield.sprite.modulate.is_equal_approx(boss.shield.broken_color))
	assert(is_zero_approx(ui.secondary_bar.size.x))
	assert(boss.shield.resolve_shield_damage(8) == 8)
	boss.shield._physics_process(0.21)
	assert(not boss.shield.is_broken())
	assert(boss.shield.is_active())
	assert(is_zero_approx(boss.shield.get_stress_progress()))
	assert(boss.shield.sprite.modulate.is_equal_approx(boss.shield.armored_color))
	assert(is_equal_approx(ui.secondary_bar.size.x, ui.get_full_width(ui.secondary_bar)))
	assert(boss.shield.resolve_shield_damage(1) == 1)
	boss.shield.configure(tuning)
	boss.shield.resolve_shield_damage(4)
	boss.shield._physics_process(0.75)
	assert(is_equal_approx(boss.shield.get_stress_progress(), 0.4))
	boss.shield._physics_process(0.5)
	assert(is_equal_approx(boss.shield.get_stress_progress(), 0.275))
	boss.shield.turn_toward(boss.position + Vector2.UP * 100.0, 0.5)
	assert(is_equal_approx(boss.shield.facing_angle, -PI / 6.0))
	assert(is_equal_approx(boss.shield.sprite.global_rotation, boss.shield.facing_angle))
	assert(is_equal_approx(boss.shield.global_rotation, boss.shield.facing_angle))
	boss.shield.set_facing(0.0)
	var shockwaver := SHOCKWAVER_SCENE.instantiate()
	var wave := shockwaver.get_node("RadialWaveComponent") as RadialWaveComponent
	shockwaver.remove_child(wave)
	shockwaver.free()
	add_child(wave)
	wave.set_physics_process(false)
	wave.position = boss.position + Vector2(20, 0)
	wave.configure_manual(80.0, 0.2, 12, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var before := boss.health.current_health
	var stress_before := boss.shield.get_stress_progress()
	# Piercer's laser hits through this shared armor-bypassing path.
	HitboxComponent.apply_hit(boss, 20, 0.0, front, true)
	assert(boss.health.current_health == before - 20)
	assert(is_equal_approx(boss.shield.get_stress_progress(), stress_before))
	wave._previous_wave_radius = 0.0
	wave._wave_radius = 40.0
	wave._damage_swept_ring()
	assert(boss.health.current_health == before - 32)
	assert(is_equal_approx(boss.shield.get_stress_progress(), stress_before))
	for node: Node in [boss, second, wave]:
		node.queue_free()
	await get_tree().process_frame
	print("PASS: directional armor, stress/red UI, independent health, break/recovery/decay, minimum damage, turning, and actual Piercer/ring bypass.")
	await _test_shield_collisions()
	await _test_spawning()
	await _test_distribution()
	print("PASS: all Bulwark checks")
	get_tree().quit()

func _test_targeting() -> void:
	var authored := load("res://resources/enemies/bulwark/bulwark_targeting.tres") as TargetingProfile
	var standard := load("res://resources/enemies/enemy_targeting.tres") as TargetingProfile
	assert(authored.primary_group == standard.primary_group)
	assert(authored.secondary_group == standard.secondary_group)
	assert(authored.primary_lock_radius > standard.primary_lock_radius)
	assert(authored.switch_to_secondary_margin > standard.switch_to_secondary_margin)
	assert(authored.return_to_primary_margin > standard.return_to_primary_margin)
	assert(authored.retarget_margin == standard.retarget_margin)
	var profile := authored.duplicate() as TargetingProfile
	profile.primary_group = &"bulwark_test_player"
	profile.secondary_group = &"bulwark_test_turret"
	var targeting := TargetingComponent.new()
	add_child(targeting)
	targeting.configure(profile)
	var player := Node2D.new()
	var turret := Node2D.new()
	add_child(player)
	add_child(turret)
	player.add_to_group(profile.primary_group)
	turret.add_to_group(profile.secondary_group)
	player.position = Vector2(110, 0)
	turret.position = Vector2(10, 0)
	assert(targeting.get_best_target(Vector2.ZERO) == player)
	player.position = Vector2(200, 0)
	turret.position = Vector2(110, 0)
	assert(targeting.get_best_target(Vector2.ZERO) == player)
	player.position = Vector2(260, 0)
	assert(targeting.get_best_target(Vector2.ZERO) == turret)
	player.position = Vector2(175, 0)
	assert(targeting.get_best_target(Vector2.ZERO) == turret)
	player.position = Vector2(165, 0)
	assert(targeting.get_best_target(Vector2.ZERO) == player)
	player.remove_from_group(profile.primary_group)
	assert(targeting.get_best_target(Vector2.ZERO) == turret)
	turret.remove_from_group(profile.secondary_group)
	assert(targeting.get_best_target(Vector2.ZERO) == null)
	targeting.queue_free()
	player.queue_free()
	turret.queue_free()
	await get_tree().process_frame
	print("PASS: shared enemy targeting, stronger player lock/preference, turret switching, return hysteresis, and turret fallback without a player.")

func _record_shield_hit(_amount: int, _origin: Vector2) -> void:
	_shield_impacts += 1

func _shoot_at_boss(scene: PackedScene, boss: Bulwark, offset: Vector2, direction: Vector2) -> void:
	var projectile := scene.instantiate() as Node2D
	projectile.set_orientation(boss.global_position + offset, direction.angle(), direction)
	projectile.set_parameters(120.0, 8, 200.0, 2.0)
	add_child(projectile)

func _test_shield_collisions() -> void:
	var boss := _new_boss(Vector2(4000, 4000))
	boss.shield.shield_hit.connect(_record_shield_hit)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var query := PhysicsRayQueryParameters2D.create(boss.global_position + Vector2(40, 0), boss.global_position, 128)
	var space := boss.get_world_2d().direct_space_state
	assert(space.intersect_ray(query).get("collider") == boss.shield)
	_shoot_at_boss(PLAYER_PROJECTILE_SCENE, boss, Vector2(50, 0), Vector2.LEFT)
	await get_tree().create_timer(0.45).timeout
	assert(_shield_impacts == 1)
	var max_hp := boss.stats.max_health
	assert(boss.health.current_health == max_hp - 2)
	assert(boss.knockback.velocity.is_zero_approx())
	_shoot_at_boss(TURRET_PROJECTILE_SCENE, boss, Vector2(50, 0), Vector2.LEFT)
	await get_tree().create_timer(0.45).timeout
	assert(_shield_impacts == 2)
	assert(boss.health.current_health == max_hp - 4)
	assert(boss.knockback.velocity.is_zero_approx())
	_shoot_at_boss(PLAYER_PROJECTILE_SCENE, boss, Vector2(-50, 0), Vector2.RIGHT)
	await get_tree().create_timer(0.45).timeout
	assert(_shield_impacts == 2)
	assert(boss.health.current_health == max_hp - 12)
	assert(is_equal_approx(boss.knockback.velocity.length(), 200.0))
	assert(boss.knockback.velocity.x > 0.0)
	var tuning := BulwarkStats.new()
	tuning.stress_threshold = 10.0
	tuning.armor_broken_duration = 0.2
	boss.shield.configure(tuning)
	boss.shield.was_hit(10, 200.0, boss.position + Vector2.RIGHT * 40.0)
	assert(boss.shield.is_broken() and not boss.shield.is_active())
	assert(boss.knockback.velocity.is_zero_approx())
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(boss.shield.collision_polygon.disabled)
	assert(space.intersect_ray(query).is_empty())
	var before := boss.health.current_health
	_shoot_at_boss(PLAYER_PROJECTILE_SCENE, boss, Vector2(50, 0), Vector2.LEFT)
	await get_tree().create_timer(0.45).timeout
	assert(boss.health.current_health == before - 8)
	assert(is_equal_approx(boss.knockback.velocity.length(), 200.0))
	assert(_shield_impacts == 3)
	boss.shield._physics_process(0.21)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(not boss.shield.collision_polygon.disabled)
	boss.shield.set_facing(PI)
	await get_tree().physics_frame
	await get_tree().physics_frame
	query.from = boss.global_position + Vector2(-40, 0)
	assert(space.intersect_ray(query).get("collider") == boss.shield)
	boss.play_spawn_intro(boss.position, 0.05)
	assert(not boss.shield.is_active())
	await get_tree().create_timer(0.1).timeout
	assert(boss.shield.is_active())
	boss.was_hit_bypassing_armor(10000, 0.0, boss.position + Vector2.RIGHT)
	assert(not boss.shield.is_active())
	boss.queue_free()
	await get_tree().process_frame
	print("PASS: real player/turret projectile shield interception, single damage, exposed-side knockback, collider break/reform/rotation, broken-front knockback, spawn/death cleanup.")

func _on_boss_spawned(enemy: EnemyBase) -> void:
	_spawned_boss = enemy as Bulwark
	_boss_spawn_position = enemy.global_position
	_boss_count += 1

func _test_spawning() -> void:
	var game := GAME_SCENE.instantiate()
	add_child(game)
	var manager := get_tree().get_first_node_in_group("wave_manager") as WaveManager
	var score := get_tree().get_first_node_in_group("score_manager") as ScoreManager
	var player := get_tree().get_first_node_in_group("player") as Player
	var spawner := get_tree().get_first_node_in_group("spawn_manager") as SpawnManager
	assert(spawner != null)
	spawner.enemy_entries = []
	spawner.boss_every_nth_round = 1
	manager.set_process(false)
	player.set_process(false)
	player.set_physics_process(false)
	var turret := StaticBody2D.new()
	turret.collision_layer = 32
	turret.collision_mask = 0
	var turret_collision := CollisionShape2D.new()
	var turret_shape := CircleShape2D.new()
	turret_shape.radius = 16.0
	turret_collision.shape = turret_shape
	turret.add_child(turret_collision)
	turret.position = player.global_position + Vector2(70, 0)
	add_child(turret)
	turret.add_to_group("turrets")
	spawner.enemy_spawned.connect(_on_boss_spawned)
	assert(manager.get_parent() == spawner.get_parent())
	assert(spawner.boss_entries.size() == 1)
	assert(spawner._pick_boss(1) == spawner.boss_entries[0])
	spawner.boss_every_nth_round = 5
	assert(spawner._pick_boss(1) == null)
	assert(spawner._pick_boss(5) == spawner.boss_entries[0])
	spawner.boss_every_nth_round = 0
	assert(spawner._pick_boss(5) == null)
	spawner.boss_every_nth_round = 1
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	manager._wave_index = 0
	manager._enter_combat_phase()
	assert(spawner.is_spawning() and _boss_count == 0)
	spawner._check_completion()
	assert(manager.is_combat_phase())
	await spawner.enemy_spawned
	assert(_boss_count == 1 and _spawned_boss != null)
	var intro_clip := _spawned_boss.intro_animation.get_animation(&"intro")
	assert(_spawned_boss.intro_animation.current_animation == &"intro")
	assert(not _spawned_boss.has_node("Intro/ShieldRevealAnimationPlayer"))
	assert(intro_clip.find_track(NodePath("Visuals/DropRoot/ShieldSprite:scale"), Animation.TYPE_VALUE) == -1)
	var shield_intro := _spawned_boss.animation.get_animation(&"bulwark/intro")
	assert(shield_intro.find_track(NodePath("Visuals/DropRoot/ShieldSprite:scale"), Animation.TYPE_VALUE) >= 0)
	assert(is_equal_approx(shield_intro.length, 0.3))
	assert(manager.current_wave == 1)
	assert(_boss_spawn_position.is_finite())
	var picker := spawner.boss_location_picker
	assert(picker.require_wall_clearance)
	assert((picker.clearance_collision_mask & 2) == 0)
	assert(picker.is_wall_clear(_boss_spawn_position))
	assert(_boss_spawn_position.distance_to(turret.global_position) >= picker.min_threat_distance)
	assert(not picker.is_point_clear(turret.global_position))
	var navigation_map := player.get_world_2d().navigation_map
	var path := NavigationServer2D.map_get_path(navigation_map, player.global_position, _boss_spawn_position, true)
	assert(not path.is_empty() and path[path.size() - 1].distance_to(_boss_spawn_position) <= 1.0)
	assert(_spawned_boss.health.current_health == _spawned_boss.stats.max_health)
	assert(not _spawned_boss.health_ui.visible)
	assert(_spawned_boss._spawn_intro_active)
	assert((_spawned_boss.get_node("Intro/LandingMarker") as CanvasItem).visible)
	await _spawned_boss.boss_intro_finished
	assert(_spawned_boss.health_ui.visible)
	assert(not _spawned_boss._spawn_intro_active)
	assert(not spawner.is_spawning())
	spawner._check_completion()
	assert(manager.is_combat_phase())
	var destroyed_before := score.drones_destroyed
	_spawned_boss.was_hit_bypassing_armor(10000, 0.0, _spawned_boss.global_position + Vector2.RIGHT)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(manager.is_build_phase())
	assert(score.drones_destroyed == destroyed_before + 1)
	spawner.boss_every_nth_round = 0
	manager._enter_combat_phase()
	assert(manager.current_wave == 2)
	await get_tree().process_frame
	assert(_boss_count == 1)
	var threats := picker.get_threats([&"player", &"turrets", &"turrets"])
	assert(threats.count(turret) == 1)
	picker.min_threat_distance = 10000.0
	assert(picker.pick_spot(navigation_map, 1, threats, player.global_position).is_finite())
	var origin_fallback := picker.pick_spot(RID(), 1, threats, player.global_position)
	assert(origin_fallback == player.global_position if picker.is_wall_clear(player.global_position) else not origin_fallback.is_finite())
	var recorder := RecordingSafeSpot.new()
	recorder.candidates = picker.candidates
	recorder.min_threat_distance = 10000.0
	recorder.clearance_radius = picker.clearance_radius
	recorder.require_wall_clearance = picker.require_wall_clearance
	recorder.clearance_collision_mask = picker.clearance_collision_mask
	add_child(recorder)
	var fallback := recorder.pick_spot(navigation_map, 1, threats, player.global_position)
	assert(fallback.is_finite())
	assert(recorder.clearance_checks <= recorder.candidates)
	var fallback_distance := recorder.get_nearest_threat_distance(fallback, threats)
	for point: Vector2 in recorder.clear_points:
		var candidate_path := NavigationServer2D.map_get_path(navigation_map, player.global_position, point, true)
		if not candidate_path.is_empty() and candidate_path[candidate_path.size() - 1].distance_to(point) <= 1.0:
			assert(fallback_distance + 0.001 >= recorder.get_nearest_threat_distance(point, threats))
	var cached_shape := recorder._clearance_shape
	var cached_query := recorder._clearance_query
	recorder.is_point_clear(turret.global_position)
	assert(recorder._clearance_shape == cached_shape and recorder._clearance_query == cached_query)
	recorder.queue_free()
	var emitter := EMITTER_SCENE.instantiate() as Emitter
	emitter.position = player.global_position
	add_child(emitter)
	emitter.set_physics_process(false)
	emitter.safe_spot.min_threat_distance = 10000.0
	emitter._pick_spot(emitter._get_threats())
	assert(emitter._has_spot and emitter._spot.is_finite())
	emitter.queue_free()
	spawner.set_physics_process(false)
	spawner.boss_every_nth_round = 1
	manager._enter_combat_phase()
	assert(spawner.is_spawning())
	manager._enter_build_phase()
	spawner._physics_process(0.016)
	assert(not spawner.is_spawning() and _boss_count == 1)
	manager._enter_combat_phase()
	spawner._physics_process(0.016)
	assert(spawner.is_spawning())
	await spawner.enemy_spawned
	assert(_boss_count == 2 and not spawner.is_spawning())
	assert(_boss_spawn_position.is_finite())
	assert(picker.get_nearest_threat_distance(_boss_spawn_position, threats) < picker.min_threat_distance)
	await _spawned_boss.boss_intro_finished
	_spawned_boss.was_hit_bypassing_armor(10000, 0.0, _spawned_boss.global_position + Vector2.RIGHT)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(manager.is_build_phase())
	picker.clearance_radius = 10000.0
	manager._enter_combat_phase()
	spawner._physics_process(0.016)
	assert(spawner.is_spawning())
	await get_tree().process_frame
	await get_tree().process_frame
	assert(spawner.is_spawning() and _boss_count == 2)
	manager._enter_build_phase()
	assert(manager.is_build_phase())
	turret.queue_free()
	print("PASS: turret-biased boss spawn with player overlap allowed, wall-safe fallback, bounded queries, Emitter reuse, completion/cancellation, and scoring.")

func _record_normal_spawn(enemy: EnemyBase) -> void:
	_normal_spawns.append(enemy)
	_spawn_positions.append(enemy.global_position)

func _record_cleared(_wave_index: int) -> void:
	_cleared_count += 1

func _test_distribution() -> void:
	var spawner := SpawnManager.new()
	spawner.enemy_container = self
	spawner.boss_every_nth_round = 0
	spawner.time_between_spawns = 0.05
	var first_point := SpawnPoint.new()
	var second_point := SpawnPoint.new()
	first_point.position = Vector2(2000, 2000)
	second_point.position = Vector2(3000, 3000)
	first_point.spawn_intro_distance = 60.0
	second_point.spawn_intro_distance = 96.0
	second_point.spawn_intro_direction = Vector2.UP
	add_child(first_point)
	add_child(second_point)
	spawner.spawn_points = [first_point, second_point]
	var first_entry := EnemySpawnEntry.new()
	first_entry.enemy_scene = CHASER_SCENE
	first_entry.base_amount = 3
	first_entry.health_multiplier = 2.0
	first_entry.health_multiplier_every_n_waves = 2
	var second_entry := EnemySpawnEntry.new()
	second_entry.enemy_scene = SHOTGUNNER_SCENE
	second_entry.base_amount = 2
	var locked_entry := EnemySpawnEntry.new()
	locked_entry.enemy_scene = CHASER_SCENE
	locked_entry.introduction_wave = 10
	var disabled_entry := EnemySpawnEntry.new()
	disabled_entry.enemy_scene = CHASER_SCENE
	disabled_entry.enabled = false
	spawner.enemy_entries = [first_entry, second_entry, locked_entry, disabled_entry, null]
	add_child(spawner)
	spawner.set_process(false)
	spawner.enemy_spawned.connect(_record_normal_spawn)
	spawner.wave_cleared.connect(_record_cleared)
	assert(spawner._build_enemy_queue(1).size() == 5)
	var layouts: Dictionary[String, bool] = {}
	seed(12345)
	for round_index in range(20):
		var queue := spawner._build_enemy_queue(1)
		var points := spawner._get_round_points()
		var signature := ""
		for index in queue.size():
			signature += "%s:%s;" % [queue[index].enemy_scene.resource_path, points[index % points.size()].position]
		layouts[signature] = true
	assert(layouts.size() > 1)
	spawner.start_wave(2)
	assert(_normal_spawns.size() == 1 and spawner.is_spawning())
	for index in range(4):
		spawner._process(0.06)
	assert(_normal_spawns.size() == 5 and not spawner.is_spawning())
	assert(_cleared_count == 0)
	var first_count := 0
	var second_count := 0
	for position: Vector2 in _spawn_positions:
		first_count += int(position == first_point.position)
		second_count += int(position == second_point.position)
	assert(first_count + second_count == 5 and absi(first_count - second_count) == 1)
	for enemy: EnemyBase in _normal_spawns:
		assert(enemy._spawn_intro_active)
		if enemy is Chaser:
			assert(enemy.health.max_health == (enemy as Chaser).stats.max_health * 2)
		enemy._finish_spawn_intro()
		enemy.was_hit_bypassing_armor(10000, 0.0, enemy.position + Vector2.RIGHT)
	assert(_cleared_count == 1)
	spawner._check_completion()
	assert(_cleared_count == 1)
	_normal_spawns.clear()
	_spawn_positions.clear()
	spawner.start_wave(3)
	assert(_normal_spawns.size() == 1)
	var stale_enemy := _normal_spawns[0]
	spawner.cancel_wave()
	spawner._process(100.0)
	assert(_normal_spawns.size() == 1 and not spawner.is_spawning())
	stale_enemy.died.emit()
	assert(_cleared_count == 1)
	spawner.enemy_entries = []
	spawner.start_wave(4)
	assert(_cleared_count == 2)
	stale_enemy.died.emit()
	assert(_cleared_count == 2)
	stale_enemy.queue_free()
	spawner.cancel_wave()
	await get_tree().process_frame
	print("PASS: global queue/filtering, fresh random layouts, balanced round-robin spawns, conveyor entry, scaling, completion once, cancellation/stale deaths, and empty waves.")