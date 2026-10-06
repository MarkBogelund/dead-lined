extends Resource
class_name EnemySpawnEntry

@export var enabled := true
@export var enemy_scene: PackedScene

@export_group("Wave Amount")
## Total number spawned across all spawn points on the introduction wave.
@export_range(0, 1000, 1) var base_amount: int = 1
## First wave on which this enemy can spawn.
@export_range(1, 1000, 1) var introduction_wave: int = 1
## Multiplies the amount once per wave after introduction.
@export_range(0.0, 10.0, 0.05) var amount_multiplier_per_wave: float = 1.0

@export_group("Wave Health")
## Cumulative health multiplier applied at each configured interval.
@export_range(0.0, 10.0, 0.05) var health_multiplier: float = 1.0
## Apply the health multiplier every N global waves. Zero disables it.
@export_range(0, 1000, 1) var health_multiplier_every_n_waves: int = 0
