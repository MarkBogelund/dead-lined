extends Node
class_name DeathSequenceController

@export_group("References")
@export var player: Player
@export var camera: Camera2D
@export var game_over_manager: GameOverManager

@export_group("Timing")
@export var ui_delay := 2.0

@export_group("Camera Zoom")
@export var zoom_duration := 0.8
@export var zoom_target := 3.0

var _initial_camera_zoom: Vector2
var _sequence_running := false

func _ready() -> void:
	add_to_group("death_sequence_controller")
	
	if camera:
		_initial_camera_zoom = camera.zoom
	
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
	_zoom_camera_in()
	
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
