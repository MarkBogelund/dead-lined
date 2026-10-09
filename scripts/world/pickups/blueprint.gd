extends Orb
class_name Blueprint

## Boss drop that unlocks a turret. Never expires or clears on phase changes; whoever spawned it listens to `collected`.

signal collected

const COLLECT_ANIMATION := &"collect"

func _ready() -> void:
	super()
	animation_handler.configure_animation(COLLECT_ANIMATION, 3, true)

func _connect_phase_signals(_wave_manager: WaveManager) -> void:
	pass

func _try_collect(_player: Player) -> bool:
	return true

func _can_attract(_player: Player) -> bool:
	return true

func _on_collected(_player: Player) -> void:
	collected.emit()
	animation_handler.play_animation(COLLECT_ANIMATION)
