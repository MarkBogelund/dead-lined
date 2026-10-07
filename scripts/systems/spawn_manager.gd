extends Node
class_name SpawnManager

signal enemy_spawned(enemy: EnemyBase)
signal enemy_defeated(enemy: EnemyBase)
signal wave_cleared(wave_index: int)

@export_group("Normal Enemies")
## Wave-wide enemy totals; they are not multiplied by the number of spawn points.
@export var enemy_entries: Array[EnemySpawnEntry] = []
## Global interval between normal enemy spawns, in seconds.
@export_range(0.05, 30.0, 0.05) var time_between_spawns := 0.75
@export var spawn_points: Array[SpawnPoint] = []
@export var enemy_container: Node
@export var damage_growth := 0.1

@export_group("Bosses")
## One unlocked boss every N waves. Zero disables bosses; one enables first-wave testing.
@export_range(0, 1000, 1) var boss_every_nth_round := 1
@export var boss_entries: Array[EnemySpawnEntry] = []
## Shared location picker; bosses ignore the player and never relax wall clearance.
@export var boss_location_picker: SafeSpotComponent

var _wave_index := 0
var _generation := 0
var _active := false
var _spawning := false
var _completion_emitted := false
var _spawn_timer := 0.0
var _queue_index := 0
var _queue: Array[EnemySpawnEntry] = []
var _round_points: Array[SpawnPoint] = []
var _live_enemies: Dictionary[int, EnemyBase] = {}
var _pending_boss: EnemySpawnEntry
var _boss_placement_queued := false
var _boss_retry_time := 0.0

func _ready() -> void:
	assert(enemy_container != null, "SpawnManager requires an enemy container")

func start_wave(wave_index: int) -> void:
	cancel_wave()
	_wave_index = wave_index
	_active = true
	_completion_emitted = false
	_queue = _build_enemy_queue(wave_index)
	_round_points = _get_round_points()
	if not _queue.is_empty() and _round_points.is_empty():
		push_warning("SpawnManager has no valid spawn points; skipping normal enemies")
		_queue.clear()
	_spawning = true
	_pending_boss = _pick_boss(wave_index)
	if not _queue.is_empty():
		_spawn_next()
	else:
		_spawning = false
	_check_completion()

func cancel_wave() -> void:
	_generation += 1
	_active = false
	_spawning = false
	_spawn_timer = 0.0
	_queue_index = 0
	_queue.clear()
	_round_points.clear()
	_live_enemies.clear()
	_pending_boss = null
	_boss_placement_queued = false
	_boss_retry_time = 0.0

func is_spawning() -> bool:
	return _spawning or _pending_boss != null

func _physics_process(delta: float) -> void:
	if not _active or not _pending_boss or _boss_placement_queued:
		return
	_boss_retry_time = maxf(0.0, _boss_retry_time - delta)
	if _boss_retry_time > 0.0:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var position := player.global_position if player and player.global_position.is_finite() else Vector2.ZERO
	if boss_location_picker:
		var threats := boss_location_picker.get_threats([&"turrets"])
		var navigation_map := get_viewport().find_world_2d().navigation_map
		position = boss_location_picker.pick_spot(navigation_map, 1, threats, position)
		if not position.is_finite():
			_boss_retry_time = 0.25
			return
	_boss_placement_queued = true
	_place_boss.call_deferred(position, _generation)

func _place_boss(position: Vector2, generation: int) -> void:
	if generation != _generation or not _active or not _pending_boss:
		return
	_boss_placement_queued = false
	if boss_location_picker and boss_location_picker.require_wall_clearance and not boss_location_picker.is_wall_clear(position):
		_boss_retry_time = 0.25
		return
	var entry := _pending_boss
	_pending_boss = null
	_spawn_enemy(entry, null, position)
	_check_completion()

func _process(delta: float) -> void:
	if not _active or not _spawning:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_next()

func _build_enemy_queue(wave_index: int) -> Array[EnemySpawnEntry]:
	var queue: Array[EnemySpawnEntry] = []
	for entry: EnemySpawnEntry in enemy_entries:
		if not _is_available(entry, wave_index):
			continue
		var waves_since_introduction := wave_index - entry.introduction_wave
		var amount := maxi(0, floori(float(entry.base_amount) * pow(entry.amount_multiplier_per_wave, waves_since_introduction)))
		for index in amount:
			queue.append(entry)
	queue.shuffle()
	return queue

func _get_round_points() -> Array[SpawnPoint]:
	var points: Array[SpawnPoint] = []
	for point: SpawnPoint in spawn_points:
		if is_instance_valid(point) and point.is_inside_tree() and not points.has(point):
			points.append(point)
	points.shuffle()
	return points

func _pick_boss(wave_index: int) -> EnemySpawnEntry:
	if boss_every_nth_round <= 0 or wave_index % boss_every_nth_round != 0:
		return null
	var available: Array[EnemySpawnEntry] = []
	for entry: EnemySpawnEntry in boss_entries:
		if _is_available(entry, wave_index):
			available.append(entry)
	return available.pick_random() if not available.is_empty() else null

func _is_available(entry: EnemySpawnEntry, wave_index: int) -> bool:
	return entry != null and entry.enabled and entry.enemy_scene != null and wave_index >= entry.introduction_wave

func _spawn_next() -> void:
	if _queue_index >= _queue.size():
		_spawning = false
		_check_completion()
		return
	var point := _round_points[_queue_index % _round_points.size()]
	if is_instance_valid(point) and point.is_inside_tree():
		_spawn_enemy(_queue[_queue_index], point)
	_queue_index += 1
	_spawn_timer = maxf(0.05, time_between_spawns)
	if _queue_index >= _queue.size():
		_spawning = false
		_queue.clear()
		_check_completion()

func _spawn_enemy(entry: EnemySpawnEntry, point: SpawnPoint = null, spawn_position := Vector2.ZERO) -> void:
	var instance := entry.enemy_scene.instantiate()
	var enemy := instance as EnemyBase
	if not enemy:
		instance.free()
		push_error("SpawnManager entries must instantiate EnemyBase scenes")
		return
	enemy_container.add_child(enemy)
	enemy.global_position = point.global_position if point else spawn_position
	_apply_wave_scaling(enemy, entry)
	var enemy_id := enemy.get_instance_id()
	_live_enemies[enemy_id] = enemy
	enemy.died.connect(_on_enemy_died.bind(enemy_id, _generation))
	enemy.tree_exiting.connect(_on_enemy_exiting.bind(enemy_id, _generation))
	if point:
		point.send_in(enemy)
	enemy_spawned.emit(enemy)

func _apply_wave_scaling(enemy: EnemyBase, entry: EnemySpawnEntry) -> void:
	if entry.health_multiplier_every_n_waves > 0:
		var health_steps := floori(float(_wave_index) / float(entry.health_multiplier_every_n_waves))
		enemy.buff_health(pow(entry.health_multiplier, health_steps))
	enemy.buff_damage(1.0 + float(_wave_index) * damage_growth)

func _on_enemy_died(enemy_id: int, generation: int) -> void:
	if generation != _generation or not _live_enemies.has(enemy_id):
		return
	var enemy := _live_enemies[enemy_id]
	_live_enemies.erase(enemy_id)
	enemy_defeated.emit(enemy)
	_check_completion()

func _on_enemy_exiting(enemy_id: int, generation: int) -> void:
	if generation == _generation and _live_enemies.erase(enemy_id):
		_check_completion()

func _check_completion() -> void:
	if _active and not is_spawning() and _live_enemies.is_empty() and not _completion_emitted:
		_completion_emitted = true
		wave_cleared.emit(_wave_index)