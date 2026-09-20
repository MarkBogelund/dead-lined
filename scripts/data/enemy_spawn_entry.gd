extends Resource
class_name EnemySpawnEntry

@export var enemy_scene: PackedScene
## Relative chance of this enemy being selected. Zero disables it.
@export_range(0.0, 100.0, 0.1) var spawn_weight: float = 1.0
