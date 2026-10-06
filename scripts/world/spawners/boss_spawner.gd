extends EnemySpawner
class_name BossSpawner

var _selected_boss: EnemySpawnEntry

func _ready() -> void:
	assert(wave_manager, "BossSpawner requires its owning WaveManager")

func start_boss_spawn(wave_index: int, entry: EnemySpawnEntry) -> void:
	if _is_spawning:
		return
	_selected_boss = entry
	start_wave_spawn(wave_index)

func cancel_boss_spawn() -> void:
	super._on_build_phase_started()
	_selected_boss = null

func _build_spawn_queue(_wave_index: int) -> Array[EnemySpawnEntry]:
	var queue: Array[EnemySpawnEntry] = []
	if _selected_boss:
		queue.append(_selected_boss)
	return queue

func _spawn_wave_queue(spawn_queue: Array[EnemySpawnEntry], generation: int) -> void:
	if spawn_queue.is_empty() or generation != _spawn_generation or not wave_manager.is_combat_phase():
		return
	_spawn_boss(spawn_queue[0])

func _spawn_boss(entry: EnemySpawnEntry) -> void:
	var boss := entry.enemy_scene.instantiate() as EnemyBase
	assert(boss != null, "Boss pool scenes must extend EnemyBase")
	get_tree().current_scene.add_child(boss)
	boss.global_position = Vector2.ZERO
	_apply_wave_scaling(boss, entry)
	boss.died.connect(wave_manager._on_enemy_died)
	enemy_spawned.emit(boss)
