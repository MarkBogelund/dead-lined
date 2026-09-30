extends Node2D
class_name CombatLever

@export_group("Phase Light")
@export var build_phase_color := Color(0.25, 1.0, 0.35)
@export var combat_phase_color := Color(1.0, 0.2, 0.15)

@onready var animation: AnimationHandler = $AnimationHandler
@onready var phase_light: PointLight2D = $PointLight2D

var _wave_manager: WaveManager
var _activation_requested := false

func _ready() -> void:
	_wave_manager = get_tree().get_first_node_in_group(&"wave_manager") as WaveManager
	if not _wave_manager:
		push_error("CombatLever requires a WaveManager in the wave_manager group")
		return
	animation.configure_animation("swing_left", 0, false)
	animation.configure_animation("swing_right", 1, true)
	_wave_manager.build_phase_started.connect(_on_build_phase_started)
	_wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	if _wave_manager.is_build_phase():
		_on_build_phase_started()
	else:
		_on_combat_phase_started(_wave_manager.current_wave)

## Player projectiles call this contract for opt-in area targets.
func receive_player_projectile_hit() -> bool:
	if not _wave_manager or not _wave_manager.is_build_phase() or _activation_requested:
		return false
	_activation_requested = true
	_wave_manager.skip_build_phase()
	return true

func _on_build_phase_started() -> void:
	_activation_requested = false
	phase_light.color = build_phase_color
	animation.play_animation("swing_left")

func _on_combat_phase_started(_wave_index: int) -> void:
	phase_light.color = combat_phase_color
	animation.play_animation("swing_right")