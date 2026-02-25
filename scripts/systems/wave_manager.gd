extends Node
class_name WaveManager

signal build_phase_started
signal combat_phase_started(wave_index: int)
signal build_phase_tick(time_left: float)

@export var time_between_waves := 10

@onready var game_over_manager: GameOverManager = %GameOverManager

var _current_phase: Phase = Phase.BUILD
var _phase_timer := 0.0
var _wave_index := 0

enum Phase {
	BUILD,
	COMBAT
}

var current_wave: int:
	get: return _wave_index

func get_current_wave() -> int:
	return _wave_index

func _ready() -> void:
	game_over_manager.game_over.connect(_on_game_over)
	await get_tree().process_frame
	_enter_build_phase()

func _on_game_over() -> void:
	StatsManager.set_waves(_wave_index)

func _process(delta: float) -> void:
	if _current_phase != Phase.BUILD:
		return
	
	_phase_timer -= delta
	emit_signal("build_phase_tick", _phase_timer)
	
	if _phase_timer <= 0.0:
		_enter_combat_phase()

func _enter_build_phase() -> void:
	print("build phase")
	_current_phase = Phase.BUILD
	_phase_timer = time_between_waves
	emit_signal("build_phase_started")

func _enter_combat_phase() -> void:
	_current_phase = Phase.COMBAT
	_wave_index += 1
	StatsManager.start_time_tracking()
	emit_signal("combat_phase_started", _wave_index)

func _on_enemy_died() -> void:
	if _current_phase != Phase.COMBAT:
		return
	
	# Print amopunt of enemies left for debugging
	print("Enemy died, remaining:", get_tree().get_nodes_in_group("enemies").size())

	if get_tree().get_nodes_in_group("enemies").is_empty():
		_enter_build_phase()
