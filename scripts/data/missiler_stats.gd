extends TurretStats
class_name MissilerStats

@export_group("Missiler")
@export var targeting: TargetingProfile
@export_range(0.0, 500.0, 1.0) var minimum_range := 70.0
@export_range(0.05, 5.0, 0.05) var charge_duration := 1.2
@export_range(0.05, 5.0, 0.05) var flight_duration := 0.8
@export_range(0.0, 200.0, 1.0) var arc_height := 36.0
@export_range(1.0, 300.0, 1.0) var blast_radius := 55.0
@export_range(1.0, 64.0, 1.0) var ring_thickness := 12.0
@export_range(0.05, 3.0, 0.05) var expansion_duration := 0.35
