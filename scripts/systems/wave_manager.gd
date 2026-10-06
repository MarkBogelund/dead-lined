extends Node
class_name WaveManager

signal build_phase_started
signal combat_phase_started(wave_index: int)
signal build_phase_tick(time_left: float)

@export var settings: WaveSettings

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

func is_build_phase() -> bool:
	return _current_phase == Phase.BUILD

func is_combat_phase() -> bool:
	return _current_phase == Phase.COMBAT

func skip_build_phase() -> void:
	if _current_phase == Phase.BUILD:
		_phase_timer = 0.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("skip_build_phase"):
		skip_build_phase()

func _ready() -> void:
	await get_tree().process_frame
	_enter_build_phase()

func _process(delta: float) -> void:
	if _current_phase != Phase.BUILD:
		return
	_phase_timer = maxf(0.0, _phase_timer - delta)
	build_phase_tick.emit(_phase_timer)
	if _phase_timer <= 0.0:
		_enter_combat_phase()

func _enter_build_phase() -> void:
	_current_phase = Phase.BUILD
	_phase_timer = maxf(0.0, settings.build_phase_duration)
	build_phase_started.emit()

func _enter_combat_phase() -> void:
	_current_phase = Phase.COMBAT
	_wave_index += 1
	combat_phase_started.emit(_wave_index)

func _on_wave_cleared(wave_index: int) -> void:
	call_deferred("_finish_wave", wave_index)

func _finish_wave(wave_index: int) -> void:
	if _current_phase == Phase.COMBAT and _wave_index == wave_index:
		_enter_build_phase()
