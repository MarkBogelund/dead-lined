extends Resource
class_name PostProcessingSettings

## Shared tuning for full-screen effects managed by PostProcessingManager.

@export_group("High Capacity Vignette")
@export var good_capacity_vignette_enabled := false
@export var good_color := Color(1.0, 0.82, 0.2, 1.0)
@export var good_curve: Curve
@export var capacity_priority := 0

@export_group("Low Capacity Distortion")
## X = capacity fraction (0 empty, 1 full); Y = final effect strength.
@export var danger_strength_curve: Curve
## Strength of edge displacement and how often glitch cells appear.
@export_range(0.0, 1.0, 0.01) var danger_glitch_intensity := 0.7
## RGB separation strength; 1 uses the internally balanced maximum offset.
@export_range(0.0, 1.0, 0.01) var danger_chromatic_aberration := 0.65
## 0 keeps original colors; 1 is fully red-tinted while preserving luminance.
@export_range(0.0, 1.0, 0.01) var danger_red_tint := 1.0
## Fraction of the screen radius covered from the outside inward: 0 = none, 1 = almost the whole screen.
@export_range(0.0, 1.0, 0.01) var danger_screen_coverage := 0.8

@export_group("Dash Charge")
@export_range(0.0, 1.0, 0.05) var dash_max_desaturation := 0.3
@export_range(0.0, 1.0, 0.05) var dash_darken := 0.1
@export_range(0.0, 2.0, 0.01) var dash_fade_in_duration := 0.1
@export_range(0.0, 2.0, 0.01) var dash_fade_out_duration := 0.2

@export_group("Crunch Time")
@export var crunch_time_priority := 100
@export_range(0.0, 2.0, 0.01) var crunch_time_fade_duration := 0.15