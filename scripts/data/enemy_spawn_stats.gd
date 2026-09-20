extends Resource
class_name EnemySpawnStats

@export_group("Spawn Pool")
@export var entries: Array[EnemySpawnEntry] = []

@export_group("Timing")
## Seconds between enemies spawned from the wave queue.
@export_range(0.05, 30.0, 0.05) var time_between_spawns: float = 1.0