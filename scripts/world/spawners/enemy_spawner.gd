extends Marker2D
class_name EnemySpawner

signal enemy_spawned(enemy: Node)

@onready var wave_manager: WaveManager = %WaveManager

@export var spawn_stats: EnemySpawnStats

@export_group("Spawn Intro")
## Direction from the outside spawn position to the point where the enemy becomes active.
@export var spawn_intro_direction := Vector2.DOWN
## Distance from the outside spawn position to the point where the enemy becomes active.
@export var spawn_intro_distance := 96.0
@export var conveyor_settings: ConveyorSettings

@export var health_growth := 0.15
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

	await _spawn_until_wave_ends(generation)

	if generation == _spawn_generation:
		_is_spawning = false

func _spawn_until_wave_ends(generation: int) -> void:
	while generation == _spawn_generation and wave_manager.is_combat_phase():
		var enemy_scene := _pick_enemy_scene()
		if enemy_scene:
			_spawn_single_enemy(enemy_scene)
		var spawn_interval := maxf(spawn_stats.time_between_spawns if spawn_stats else 1.0, 0.05)
		await get_tree().create_timer(spawn_interval).timeout

func _on_build_phase_started() -> void:
	_is_spawning = false
	_spawn_generation += 1

func _spawn_single_enemy(enemy_scene: PackedScene) -> void:
	var enemy := enemy_scene.instantiate()
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
	_apply_wave_scaling(enemy)
	
	# Emit signal for systems that need to track enemy spawns (ScoreManager)
	enemy_spawned.emit(enemy)

func _pick_enemy_scene() -> PackedScene:
	if not spawn_stats:
		return null
	var total_weight := 0.0
	for entry: EnemySpawnEntry in spawn_stats.entries:
		if entry and entry.enemy_scene and entry.spawn_weight > 0.0:
			total_weight += entry.spawn_weight
	if total_weight <= 0.0:
		return null

	var roll := randf() * total_weight
	for entry: EnemySpawnEntry in spawn_stats.entries:
		if not entry or not entry.enemy_scene or entry.spawn_weight <= 0.0:
			continue
		roll -= entry.spawn_weight
		if roll <= 0.0:
			return entry.enemy_scene
	return null

func _apply_wave_scaling(enemy: Node) -> void:
	var health_multiplier := 1.0 + wave_index_to_health_multiplier(_current_wave)
	enemy.buff_health(health_multiplier)
	
	var damage_multiplier := 1.0 + wave_index_to_damage_multiplier(_current_wave)
	enemy.buff_damage(damage_multiplier)

func wave_index_to_health_multiplier(wave_index: int) -> float:
	return wave_index * health_growth

func wave_index_to_damage_multiplier(wave_index: int) -> float:
	return wave_index * damage_growth

func _get_spawn_intro_direction() -> Vector2:
	if not spawn_intro_direction.is_finite() or spawn_intro_direction.is_zero_approx():
		return Vector2.DOWN
	return spawn_intro_direction.normalized()
