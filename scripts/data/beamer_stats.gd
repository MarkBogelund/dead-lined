extends TurretStats
class_name BeamerStats

@export_group("Beamer")
@export_range(1.0, 90.0, 1.0) var beam_width := 12.0
@export_range(1.0, 360.0, 1.0) var sweep_speed_degrees := 65.0
@export_range(1.0, 180.0, 1.0) var tracking_speed_degrees := 32.0
@export_range(0.0, 50.0, 1.0) var lock_break_distance := 5.0
@export_range(0.05, 20.0, 0.05) var windup_duration := 0.55
@export_range(0.05, 5.0, 0.05) var damage_interval := 0.15
## Total seconds of target tracking per firing cycle before overheating; sweeping does not consume it.
@export_range(0.05, 60.0, 0.05) var max_tracking_duration := 5.0