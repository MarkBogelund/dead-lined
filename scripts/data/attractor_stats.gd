extends TurretStats
class_name AttractorStats

@export_group("Attractor")
## Seconds between windup start and magnetic activation.
@export_range(0.05, 5.0, 0.05) var windup_duration := 0.6
## Seconds the magnetic pull remains active.
@export_range(0.05, 5.0, 0.05) var pull_duration := 1.0
## Maximum inward velocity applied near the center.
@export_range(0.0, 1000.0, 1.0) var pull_speed := 110.0
## Pull multiplier applied to enemies.
@export_range(0.0, 3.0, 0.05) var enemy_pull_multiplier := 1.0
## Pull multiplier applied to the player before max level.
@export_range(0.0, 3.0, 0.05) var player_pull_multiplier := 0.75
## Radius inside which pull is not applied.
@export_range(0.0, 100.0, 1.0) var inner_dead_zone := 12.0
## Fraction of pull speed retained at the outer edge.
@export_range(0.0, 1.0, 0.05) var edge_pull_fraction := 0.35