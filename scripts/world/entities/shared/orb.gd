extends RigidBody2D
class_name Orb

## Pickup dropped by enemies. Owns its launch, lifetime and despawn; subclasses decide what collecting does.

@export var lifetime := 15.0
## Seconds after launch before the orb stops sliding.
@export var freeze_delay := 0.3

var can_collect := false

@onready var detection_area: Area2D = $DetectionArea
@onready var animation_handler: AnimationHandler = $AnimationHandler

var _wave_manager: WaveManager

func _ready() -> void:
	add_to_group("orbs")
	detection_area.body_entered.connect(_on_body_entered)
	animation_handler.configure_animation("idle", 0, false)
	animation_handler.configure_animation("pick_up", 1, true)
	animation_handler.configure_animation("despawn", 2, true)
	animation_handler.animation_finished.connect(_on_animation_finished)
	_wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	if _wave_manager:
		_connect_phase_signals(_wave_manager)

## Called by OrbDropComponent right after the orb enters the tree.
func launch(impulse: Vector2) -> void:
	apply_impulse(impulse)
	can_collect = true
	# The wave's last enemy drops mid-death-animation, after the phase has already flipped.
	if _is_clearing_phase_active():
		_despawn()
		return
	get_tree().create_timer(freeze_delay).timeout.connect(_on_freeze_timer)
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timer)

## Override to clear uncollected orbs on a different phase change.
func _connect_phase_signals(wave_manager: WaveManager) -> void:
	wave_manager.combat_phase_started.connect(_on_clearing_phase_started.unbind(1))

## Override: true when the clearing phase is already running.
func _is_clearing_phase_active() -> bool:
	return false

## Override: return true when the player took the orb.
func _try_collect(_player: Player) -> bool:
	return false

## Override: presentation once collected. Defaults to the burst-and-vanish pickup.
func _on_collected(_player: Player) -> void:
	animation_handler.play_animation("pick_up")

func _on_freeze_timer() -> void:
	freeze = true

func _on_lifetime_timer() -> void:
	if can_collect:
		_despawn()

func _on_clearing_phase_started() -> void:
	if can_collect:
		_despawn()

func _despawn() -> void:
	can_collect = false
	animation_handler.play_animation("despawn")

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"despawn" or anim_name == &"pick_up":
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if not can_collect or not player or not _try_collect(player):
		return
	can_collect = false
	_on_collected(player)
