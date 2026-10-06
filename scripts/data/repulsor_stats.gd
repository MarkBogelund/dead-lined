extends TurretStats
class_name RepulsorStats

@export_group("Repulsor")
@export_range(0.05, 5.0, 0.05) var windup_duration := 0.6
@export_range(0.05, 5.0, 0.05) var push_duration := 1.0
@export_range(0.0, 1000.0, 1.0) var push_speed := 150.0
@export_range(0.0, 3.0, 0.05) var enemy_push_multiplier := 1.0
@export_range(0.0, 3.0, 0.05) var player_push_multiplier := 0.75
@export_range(0.0, 100.0, 1.0) var inner_dead_zone := 35.0
@export_range(0.0, 1.0, 0.05) var edge_push_fraction := 0.8