extends Resource
class_name CrunchTimeEffects

@export_group("Active state")
@export var active_overlay_color: Color = Color(1.0, 0.68, 0.12, 1.0)
@export var active_overlay_intensity: float = 0.2
@export var active_overlay_pulse_speed: float = 2.0
@export var camera_zoom_active: Vector2 = Vector2(1.75, 1.75)
@export var camera_zoom_duration: float = 0.35

@export_group("Normal state")
@export var normal_overlay_color: Color = Color(0.65, 0.3, 0.05, 0.3)
@export var normal_overlay_intensity: float = 0.2

@export_group("Player visual")
@export var ready_tint: Color = Color(1.0, 0.82, 0.82, 1.0)
@export var active_tint: Color = Color(1.0, 0.72, 0.16, 1.0)
@export var tint_transition_duration: float = 0.2

