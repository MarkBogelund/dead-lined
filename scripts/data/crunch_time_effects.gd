extends Resource
class_name CrunchTimeEffects

@export_group("Active state")
## Pulsing edge vignette.
@export var active_overlay_color: Color = Color(1.0, 0.68, 0.12, 1.0)
@export var active_overlay_intensity: float = 0.2
@export var active_overlay_pulse_speed: float = 2.0
@export_range(0.0, 1.0, 0.01) var active_overlay_pulse_min: float = 0.55

@export_group("Active screen effect")
@export var active_screen_tint_color: Color = Color(1.0, 0.72, 0.16, 1.0)
@export_range(0.0, 1.0, 0.01) var active_screen_tint_intensity: float = 0.28
@export_range(0.0, 1.0, 0.01) var active_chromatic_aberration: float = 0.5
@export_range(0.0, 1.0, 0.01) var active_bloom_intensity: float = 0.45
## Bloom sample radius in screen pixels.
@export_range(0.5, 8.0, 0.25) var active_bloom_radius: float = 2.5

@export_group("Camera")
@export var camera_zoom_active: Vector2 = Vector2(1.75, 1.75)
@export var camera_zoom_duration: float = 0.35

@export_group("Player visual")
@export var ready_tint: Color = Color(1.0, 0.82, 0.82, 1.0)
@export var active_tint: Color = Color(1.0, 0.72, 0.16, 1.0)
@export var tint_transition_duration: float = 0.2
