extends TurretStats
class_name PiercerStats

@export_group("Piercer")
@export var targeting: TargetingProfile
@export_range(0.1, 10.0, 0.1) var aim_speed := 0.9
@export_range(0.01, 0.5, 0.01) var aim_tolerance := 0.1
@export_range(0.05, 5.0, 0.05) var charge_duration := 0.8
@export_range(0.0, 5.0, 0.05) var first_shot_delay := 0.5