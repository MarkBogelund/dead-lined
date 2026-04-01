extends Node
class_name DeathSequenceController

## Orchestrates the player death sequence with timing control

@export_group("References")
@export var player: Player
@export var camera: Camera2D
@export var game_over_manager: GameOverManager
@export var camera_shake_manager: CameraShakeManager

@export_group("Freeze Frame Timing")
@export var freeze_duration := 0.08 ## Celeste-style hitstop

@export_group("Event Delays (after freeze ends)")
@export var shake_delay := 0.0 ## Delay before screen shake starts
@export var zoom_delay := 0.1 ## DEPRECATED - zoom now starts with freeze frame
@export var ui_delay := 2.0 ## Delay before UI fades in

@export_group("Camera Zoom")
@export var zoom_duration := 0.8 ## How long to zoom in
@export var zoom_target := 3.0 ## Target zoom level (2.0 default → 3.0)

@export_group("Screen Shake")
@export var shake_intensity := 0.8 ## Heavy shake on death
@export var shake_duration := 0.4 ## How long shake lasts

var _initial_camera_zoom: Vector2
var _sequence_running := false

func _ready() -> void:
	add_to_group("death_sequence_controller")
	
	if camera:
		_initial_camera_zoom = camera.zoom
	
	# Wait for player and its components to be fully ready
	if player:
		await player.ready
		if player.health:
			player.health.died.connect(_on_player_died)

func _on_player_died() -> void:
	if _sequence_running:
		return
	
	_sequence_running = true
	start_death_sequence()

func start_death_sequence() -> void:
	# Start camera zoom (will pause during freeze, then continue)
	_zoom_camera_in()
	
	# === FREEZE FRAME (everything stops) ===
	Engine.time_scale = 0.0
	await get_tree().create_timer(freeze_duration, true, false, true).timeout
	Engine.time_scale = 1.0
	
	# === POST-FREEZE (Player handles its own death effects) ===
	# Player._on_died() triggers: particles, flash, knockback, death animation
	
	# Screen shake
	if shake_delay > 0:
		await get_tree().create_timer(shake_delay).timeout
	if camera_shake_manager:
		camera_shake_manager.shake_screen(shake_intensity, shake_duration)
	
	# UI fade in
	if ui_delay > 0:
		await get_tree().create_timer(ui_delay).timeout
	_show_game_over()

func _zoom_camera_in() -> void:
	if not camera:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "zoom", Vector2(zoom_target, zoom_target), zoom_duration)

func _show_game_over() -> void:
	if game_over_manager:
		game_over_manager.trigger_game_over()

## Reset for scene restart
func reset() -> void:
	_sequence_running = false
	if camera:
		camera.zoom = _initial_camera_zoom
	Engine.time_scale = 1.0
