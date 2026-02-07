extends Resource
class_name EnemySpawnData

@export var enemy_scene: PackedScene

@export var base_count := 1
@export var count_growth := 0.0   # added per wave

@export var spawn_every_n_waves := 1  # e.g. 3 → every 3 waves
@export var max_per_wave := -1        # -1 = no cap
