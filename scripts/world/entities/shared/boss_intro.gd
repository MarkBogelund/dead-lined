extends Node2D
class_name BossIntroComponent

signal landed(shake_intensity: float)
signal finished

const DROP_ANIMATION: StringName = &"drop"

@export var visuals: Node2D
@export var ground_shadow: CanvasItem
@export var animation_player: AnimationPlayer
@export var landing_marker: BossLandingMarker
@export var drop_shadow: Sprite2D
@export var impact_visuals: Node2D
@export var dust_particles: GPUParticles2D
@export var spark_particles: GPUParticles2D
## Height in pixels above the landing point from which the boss visually falls.
@export_range(32.0, 512.0, 1.0) var drop_height := 180.0
## Trauma applied to the existing camera shake manager at impact.
@export_range(0.0, 1.0, 0.01) var landing_shake_intensity := 0.45

var drop_progress := 0.0:
	set(value):
		drop_progress = value
		if _active and visuals:
			visuals.position = _original_position + Vector2.UP * drop_height * (1.0 - value)
var squash := 0.0:
	set(value):
		squash = value
		if _active and visuals:
			visuals.scale = _original_scale * Vector2(1.0 + value * 0.18, 1.0 - value * 0.2)
var landing_flash := 0.0:
	set(value):
		landing_flash = value
		if _active and _surface:
			_surface.set_shader_parameter("flash_amount", value)

var _active := false
var _has_landed := false
var _original_position := Vector2.ZERO
var _original_scale := Vector2.ONE
var _original_modulate := Color.WHITE
var _original_visible := true
var _shadow_visible := false
var _surface: ShaderMaterial

func _ready() -> void:
	assert(visuals and animation_player and landing_marker and drop_shadow and impact_visuals and dust_particles and spark_particles, "BossIntroComponent requires its presentation references")
	animation_player.animation_finished.connect(_on_animation_finished)
	landing_marker.hide()
	drop_shadow.hide()
	impact_visuals.hide()

func begin() -> void:
	cancel()
	_original_position = visuals.position
	_original_scale = visuals.scale
	_original_modulate = visuals.modulate
	_original_visible = visuals.visible
	_shadow_visible = ground_shadow.visible if ground_shadow else false
	_surface = visuals.material as ShaderMaterial
	_active = true
	_has_landed = false
	if ground_shadow:
		ground_shadow.hide()
	visuals.hide()
	impact_visuals.top_level = false
	impact_visuals.position = Vector2.ZERO
	impact_visuals.show()
	landing_marker.show_warning()
	drop_shadow.show()
	animation_player.play(DROP_ANIMATION)
	animation_player.advance(0.0)

func reveal() -> void:
	if _active:
		visuals.show()

func land() -> void:
	if not _active or _has_landed:
		return
	_has_landed = true
	impact_visuals.top_level = true
	impact_visuals.global_position = global_position
	dust_particles.restart()
	spark_particles.restart()
	landing_marker.show_impact()
	landed.emit(landing_shake_intensity)

func cancel() -> void:
	animation_player.stop()
	landing_marker.hide()
	drop_shadow.hide()
	dust_particles.emitting = false
	spark_particles.emitting = false
	impact_visuals.hide()
	if _active:
		_restore_visuals()
	_active = false

func _restore_visuals() -> void:
	visuals.position = _original_position
	visuals.scale = _original_scale
	visuals.modulate = _original_modulate
	visuals.visible = _original_visible
	if ground_shadow:
		ground_shadow.visible = _shadow_visible
	if _surface:
		_surface.set_shader_parameter("flash_amount", 0.0)

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != DROP_ANIMATION or not _active:
		return
	_restore_visuals()
	landing_marker.hide()
	drop_shadow.hide()
	_active = false
	finished.emit()