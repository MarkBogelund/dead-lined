extends Marker2D
class_name EnemySpawner

@export var spawn_entries: Array[EnemySpawnEntry] = []
@export var spawn_radius := 24.0

@export var base_spawn_delay := 0.6
@export var min_spawn_delay := 0.15
@export var spawn_delay_decay := 0.97

@export var health_growth := 0.15
@export var damage_growth := 0.1

var _current_wave := 0
var _is_spawning := false

func _ready() -> void:
	var game_manager := get_tree().get_first_node_in_group("game_managers")
	if game_manager == null:
		push_error("EnemySpawner: GameManager not found in 'game_managers' group")
		return

	game_manager.connect(
		"combat_phase_started",
		Callable(self, "_on_combat_phase_started")
	)

func _on_combat_phase_started(wave_index: int) -> void:
	start_wave_spawn(wave_index)

func start_wave_spawn(wave_index: int) -> void:
	if _is_spawning:
		return

	_current_wave = wave_index
	_is_spawning = true

	var spawn_list := _build_spawn_queue_for_wave(_current_wave)
	var spawn_delay := _calculate_spawn_delay(_current_wave)

	await _spawn_wave_queue(spawn_list, spawn_delay)

	_is_spawning = false

func _spawn_wave_queue(spawn_list: Array[PackedScene], spawn_delay: float) -> void:
	for enemy_scene in spawn_list:
		_spawn_single_enemy(enemy_scene)
		await get_tree().create_timer(spawn_delay).timeout

func _spawn_single_enemy(enemy_scene: PackedScene) -> void:
	var enemy := enemy_scene.instantiate()
	enemy.global_position = global_position + _get_random_spawn_offset()
	get_tree().current_scene.add_child(enemy)
	_apply_wave_scaling(enemy)

func _build_spawn_queue_for_wave(wave_index: int) -> Array[PackedScene]:
	var queue: Array[PackedScene] = []

	for entry in spawn_entries:
		if entry.enemy_scene == null:
			continue

		if entry.spawn_every_n_waves > 1 and wave_index % entry.spawn_every_n_waves != 0:
			continue

		var count := entry.base_count + entry.count_growth * (wave_index - 1)
		count = int(floor(count))

		if entry.max_per_wave > 0:
			count = min(count, entry.max_per_wave)

		for i in count:
			queue.append(entry.enemy_scene)

	queue.shuffle()
	return queue

func _apply_wave_scaling(enemy: Node) -> void:
	var health_multiplier := 1.0 + wave_index_to_health_multiplier(_current_wave)
	enemy.buff_health(health_multiplier)
	
	var damage_multiplier := 1.0 + wave_index_to_damage_multiplier(_current_wave)
	enemy.buff_health(damage_multiplier)

func wave_index_to_health_multiplier(wave_index: int) -> float:
	return wave_index * health_growth

func wave_index_to_damage_multiplier(wave_index: int) -> float:
	return wave_index * damage_growth

func _calculate_spawn_delay(wave_index: int) -> float:
	return max(
		base_spawn_delay * pow(spawn_delay_decay, wave_index - 1),
		min_spawn_delay
	)

func _get_random_spawn_offset() -> Vector2:
	return Vector2(
		randf_range(-spawn_radius, spawn_radius),
		randf_range(-spawn_radius, spawn_radius)
	)
