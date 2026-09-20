extends Marker2D
class_name EnemySpawner

signal enemy_spawned(enemy: Node)
signal wave_spawning_finished

@onready var wave_manager: WaveManager = %WaveManager

@export var spawn_stats: EnemySpawnStats

@export_group("Spawn Intro")
## Direction from the outside spawn position to the point where the enemy becomes active.
@export var spawn_intro_direction := Vector2.DOWN
## Distance from the outside spawn position to the point where the enemy becomes active.
@export var spawn_intro_distance := 96.0
@export var conveyor_settings: ConveyorSettings

@export var damage_growth := 0.1

var _current_wave := 0
var _is_spawning := false
var _spawn_generation := 0

func _ready() -> void:
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	wave_manager.build_phase_started.connect(_on_build_phase_started)

func _on_combat_phase_started(wave_index: int) -> void:
	start_wave_spawn(wave_index)

func start_wave_spawn(wave_index: int) -> void:
	if _is_spawning:
		return

	_current_wave = wave_index
	_is_spawning = true
	_spawn_generation += 1
	var generation := _spawn_generation

	var spawn_queue := _build_spawn_queue(wave_index)
	await _spawn_wave_queue(spawn_queue, generation)

	if generation == _spawn_generation:
		_is_spawning = false
		wave_spawning_finished.emit()

func _spawn_wave_queue(spawn_queue: Array[EnemySpawnEntry], generation: int) -> void:
	for index: int in range(spawn_queue.size()):
		if generation != _spawn_generation or not wave_manager.is_combat_phase():
			return
		var entry: EnemySpawnEntry = spawn_queue[index]
		_spawn_single_enemy(entry)
		if index < spawn_queue.size() - 1:
			var spawn_interval := maxf(spawn_stats.time_between_spawns if spawn_stats else 1.0, 0.05)
			await get_tree().create_timer(spawn_interval).timeout

func _on_build_phase_started() -> void:
	_is_spawning = false
	_spawn_generation += 1

func is_spawning() -> bool:
	return _is_spawning

func _spawn_single_enemy(entry: EnemySpawnEntry) -> void:
	var enemy := entry.enemy_scene.instantiate()
	var spawn_position := global_position
	enemy.global_position = spawn_position
	get_tree().current_scene.add_child(enemy)
	if enemy is EnemyBase:
		var intro_direction := _get_spawn_intro_direction()
		var release_position := spawn_position + intro_direction * spawn_intro_distance
		var intro_speed: float = conveyor_settings.enemy_movement_speed if conveyor_settings else 120.0
		var intro_duration: float = spawn_intro_distance / intro_speed
		(enemy as EnemyBase).play_spawn_intro(release_position, intro_duration)
	enemy.add_to_group("enemies")
	_apply_wave_scaling(enemy, entry)
	enemy.died.connect(wave_manager._on_enemy_died)
	
	# Emit signal for systems that need to track enemy spawns (ScoreManager)
	enemy_spawned.emit(enemy)

func _build_spawn_queue(wave_index: int) -> Array[EnemySpawnEntry]:
	var queue: Array[EnemySpawnEntry] = []
	if not spawn_stats:
		return queue
	for entry: EnemySpawnEntry in spawn_stats.entries:
		if not entry or not entry.enabled or not entry.enemy_scene:
			continue
		if wave_index < entry.introduction_wave:
			continue
		var waves_since_introduction := wave_index - entry.introduction_wave
		var amount := int(floor(float(entry.base_amount) * pow(entry.amount_multiplier_per_wave, waves_since_introduction)))
		for _spawn_index: int in range(maxi(amount, 0)):
			queue.append(entry)
	queue.shuffle()
	return queue

func _apply_wave_scaling(enemy: Node, entry: EnemySpawnEntry) -> void:
	if entry.health_multiplier_every_n_waves > 0:
		var health_steps := _current_wave / entry.health_multiplier_every_n_waves
		enemy.buff_health(pow(entry.health_multiplier, health_steps))
	var damage_multiplier := 1.0 + wave_index_to_damage_multiplier(_current_wave)
	enemy.buff_damage(damage_multiplier)

func wave_index_to_damage_multiplier(wave_index: int) -> float:
	return wave_index * damage_growth

func _get_spawn_intro_direction() -> Vector2:
	if not spawn_intro_direction.is_finite() or spawn_intro_direction.is_zero_approx():
		return Vector2.DOWN
	return spawn_intro_direction.normalized()
