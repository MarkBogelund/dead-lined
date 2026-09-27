extends Resource
class_name PostProcessingSettings

## Shared tuning for full-screen effects managed by PostProcessingManager.

@export_group("Capacity Vignette")
@export var danger_color := Color(0.4, 0.0, 0.0, 1.0)
@export var danger_curve: Curve
@export var good_color := Color(1.0, 0.82, 0.2, 1.0)
@export var good_curve: Curve
@export var capacity_priority := 0

@export_group("Dash Charge")
@export_range(0.0, 1.0, 0.05) var dash_max_desaturation := 0.3
@export_range(0.0, 1.0, 0.05) var dash_darken := 0.1
@export_range(0.0, 2.0, 0.01) var dash_fade_in_duration := 0.1
@export_range(0.0, 2.0, 0.01) var dash_fade_out_duration := 0.2

@export_group("Crunch Time")
@export var crunch_time_priority := 100
@export_range(0.0, 2.0, 0.01) var crunch_time_fade_duration := 0.15