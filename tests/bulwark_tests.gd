extends Node

const BULWARK_SCENE: PackedScene = preload("res://scenes/world/enemies/bulwark.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/game.tscn")
const PIERCER_SCENE: PackedScene = preload("res://scenes/world/turrets/piercer.tscn")
const SHOCKWAVER_SCENE: PackedScene = preload("res://scenes/world/turrets/shockwaver.tscn")
const CHASER_SCENE: PackedScene = preload("res://scenes/world/enemies/chaser.tscn")
const SHOTGUNNER_SCENE: PackedScene = preload("res://scenes/world/enemies/shotgunner.tscn")

var _spawned_boss: Bulwark
var _boss_count := 0
var _normal_spawns: Array[EnemyBase] = []
var _spawn_positions: Array[Vector2] = []
var _cleared_count := 0

func _ready() -> void:
	_run.call_deferred()

func _new_boss(at: Vector2) -> Bulwark:
	var boss := BULWARK_SCENE.instantiate() as Bulwark
	boss.position = at
	add_child(boss)
	boss.set_physics_process(false)
	boss.armor.set_physics_process(false)
	return boss

func _run() -> void:
	var boss := _new_boss(Vector2(1000, 1000))
	var second := _new_boss(Vector2(2000, 2000))
	assert(boss.health.max_health == 300)
	assert(boss.health_ui.cooldown_fill.color.is_equal_approx(Color(0.95, 0.12, 0.12, 1)))
	assert(not boss.health_ui.level_label.visible)
	assert(is_zero_approx(boss.health_ui.cooldown_fill.size.x))
	var front := boss.position + Vector2(100, 0)
	boss.was_hit(8, 0.0, front)
	assert(boss.health.current_health == 298)
	assert(is_equal_approx(boss.armor.get_stress_progress(), 8.0 / 30.0))
	assert(is_equal_approx(boss.health_ui.cooldown_fill.size.x, boss.health_ui._full_bar_width * 8.0 / 30.0))
	assert(is_equal_approx(boss.health_ui.fill.size.x, boss.health_ui._full_bar_width * 298.0 / 300.0))
	assert(second.health.current_health == 300 and second.armor.get_stress_progress() == 0.0)
	boss.was_hit(8, 0.0, boss.position + Vector2(-100, 0))
	assert(boss.health.current_health == 290)
	boss.was_hit_bypassing_armor(8, 0.0, front)
	assert(boss.health.current_health == 282)
	assert(is_equal_approx(boss.armor.get_stress_progress(), 8.0 / 30.0))
	var tuning := BulwarkStats.new()
	tuning.stress_threshold = 10.0
	tuning.armor_broken_duration = 0.2
	boss.armor.configure(tuning)
	boss.armor.resolve_damage(8, front)
	assert(boss.armor.resolve_damage(2, front) == 1)
	assert(boss.armor.is_broken())
	assert(boss.armor_visual._broken)
	assert(is_equal_approx(boss.health_ui.cooldown_fill.size.x, boss.health_ui._full_bar_width))
	assert(boss.armor.resolve_damage(8, front) == 8)
	boss.armor._physics_process(0.21)
	assert(not boss.armor.is_broken())
	assert(is_zero_approx(boss.armor.get_stress_progress()))
	assert(is_zero_approx(boss.health_ui.cooldown_fill.size.x))
	assert(boss.armor.resolve_damage(1, front) == 1)
	boss.armor.configure(tuning)
	boss.armor.resolve_damage(4, front)
	boss.armor._physics_process(0.75)
	assert(is_equal_approx(boss.armor.get_stress_progress(), 0.4))
	boss.armor._physics_process(0.5)
	assert(is_equal_approx(boss.armor.get_stress_progress(), 0.275))
	boss.armor.turn_toward(boss.position + Vector2.UP * 100.0, 0.5)
	assert(is_equal_approx(boss.armor.facing_angle, -PI / 6.0))
	boss.armor.facing_angle = 0.0
	var piercer := PIERCER_SCENE.instantiate()
	var laser := piercer.get_node("LaserComponent") as PiercerLaser
	piercer.remove_child(laser)
	piercer.free()
	add_child(laser)
	var shooter := CharacterBody2D.new()
	add_child(shooter)
	var shockwaver := SHOCKWAVER_SCENE.instantiate()
	var wave := shockwaver.get_node("ShockwaveComponent") as ShockwaveComponent
	shockwaver.remove_child(wave)
	shockwaver.free()
	add_child(wave)
	wave.set_physics_process(false)
	wave.position = boss.position + Vector2(20, 0)
	wave.configure_manual(80.0, 0.2, 12, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var before := boss.health.current_health
	var stress_before := boss.armor.get_stress_progress()
	laser._damage_targets(front, Vector2.LEFT, 200.0, 20, 0.0, shooter)
	assert(boss.health.current_health == before - 20)
	assert(is_equal_approx(boss.armor.get_stress_progress(), stress_before))
	wave._previous_wave_radius = 0.0
	wave._wave_radius = 40.0
	wave._damage_swept_ring()
	assert(boss.health.current_health == before - 32)
	assert(is_equal_approx(boss.armor.get_stress_progress(), stress_before))
	for node: Node in [boss, second, laser, wave, shooter]:
		node.queue_free()
	await get_tree().process_frame
	print("PASS: directional armor, stress/red UI, independent health, break/recovery/decay, minimum damage, turning, and actual Piercer/ring bypass.")
	await _test_spawning()
	await _test_distribution()
	print("PASS: all Bulwark checks")
	get_tree().quit()

func _on_boss_spawned(enemy: EnemyBase) -> void:
	_spawned_boss = enemy as Bulwark
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
	assert(_boss_count == 1 and _spawned_boss != null)
	assert(manager.current_wave == 1)
	assert(_spawned_boss.global_position == Vector2.ZERO)
	assert(_spawned_boss.health.current_health == 300)
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
	print("PASS: sibling managers, configurable boss interval/pool, origin spawn, visible UI, live-boss completion gate, scoring, and boss disable.")

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