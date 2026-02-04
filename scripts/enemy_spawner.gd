extends Marker2D
class_name EnemySpawner

# -------------------------------------------------
# Spawn configuration
# -------------------------------------------------
@export var spawn_entries: Array[EnemySpawnEntry] = []
@export var spawn_radius := 24.0

# -------------------------------------------------
# Timing & scaling
# -------------------------------------------------
@export var base_spawn_delay := 0.6
@export var min_spawn_delay := 0.15
@export var spawn_delay_decay := 0.97

@export var health_growth := 0.15
#@export var damage_growth := 0.1

# -------------------------------------------------
# Internal state
# -------------------------------------------------
var _current_wave := 0
var _is_spawning := false

# -------------------------------------------------
# Public API
# -------------------------------------------------
func spawn_wave() -> void:
	if _is_spawning:
		return

	_current_wave += 1
	_is_spawning = true

	var spawn_list: Array[PackedScene] = _build_spawn_list()
	var spawn_delay = max(
		base_spawn_delay * pow(spawn_delay_decay, _current_wave - 1),
		min_spawn_delay
	)

	await _spawn_wave(spawn_list, spawn_delay)
	_is_spawning = false

# -------------------------------------------------
# Spawn logic
# -------------------------------------------------
func _spawn_wave(spawn_list: Array[PackedScene], spawn_delay: float) -> void:
	for scene in spawn_list:
		_spawn_enemy(scene)
		await get_tree().create_timer(spawn_delay).timeout

func _spawn_enemy(scene: PackedScene) -> void:
	var enemy := scene.instantiate()
	enemy.global_position = global_position + _random_offset()

	_apply_scaling(enemy)
	get_tree().current_scene.add_child(enemy)

# -------------------------------------------------
# Spawn list construction
# -------------------------------------------------
func _build_spawn_list() -> Array[PackedScene]:
	var result: Array[PackedScene] = []

	for entry in spawn_entries:
		if entry.enemy_scene == null:
			continue

		if entry.spawn_every_n_waves > 1 and _current_wave % entry.spawn_every_n_waves != 0:
			continue

		var count := entry.base_count + entry.count_growth * (_current_wave - 1)
		count = int(floor(count))

		if entry.max_per_wave > 0:
			count = min(count, entry.max_per_wave)

		for i in count:
			result.append(entry.enemy_scene)

	result.shuffle()
	return result

# -------------------------------------------------
# Difficulty scaling
# -------------------------------------------------
func _apply_scaling(enemy: Node) -> void:
	var health := enemy.get_node_or_null("HealthComponent")
	if health:
		var multiplier := 1.0 + _current_wave * health_growth
		health.max_health *= multiplier
		health.current_health = health.max_health

	#if DAMAGE in enemy:
		#enemy.damage *= 1.0 + _current_wave * damage_growth

# -------------------------------------------------
# Helpers
# -------------------------------------------------
func _random_offset() -> Vector2:
	return Vector2(
		randf_range(-spawn_radius, spawn_radius),
		randf_range(-spawn_radius, spawn_radius)
	)
