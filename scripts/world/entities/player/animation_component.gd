extends Node
class_name AnimationComponent

signal animation_finished(anim_name: String)

enum State {
	IDLE,
	MOVE,
	SLASH,
	DASH,
	DAMAGE,
	DIE
}

var current_state: State = State.IDLE
var locked: bool = false

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

var state_priority = {
	State.IDLE: 0,
	State.MOVE: 1,
	State.SLASH: 2,
	State.DASH: 2,
	State.DAMAGE: 3,
	State.DIE: 4
}

func _ready():
	animation_player.animation_finished.connect(_on_animation_finished)

func set_state(new_state: State):
	# DIE locks permanently
	if current_state == State.DIE:
		return

	# Locked states (slash/damage) cannot be overridden
	if locked and state_priority[new_state] <= state_priority[current_state]:
		return

	if current_state == new_state:
		return

	current_state = new_state
	_play_animation_for_state(new_state)

func _play_animation_for_state(state: State):
	match state:
		State.IDLE:
			locked = false
			animation_player.play("idle")

		State.MOVE:
			locked = false
			animation_player.play("move")

		State.SLASH:
			locked = true
			animation_player.play("slash")

		State.DASH:
			locked = true
			animation_player.play("slash") # Temporary - replace with "dash" animation later

		State.DAMAGE:
			locked = true
			animation_player.play("take_damage")

		State.DIE:
			locked = true
			animation_player.play("die")

func _on_animation_finished(_anim_name: String):
	if current_state == State.SLASH or current_state == State.DAMAGE or current_state == State.DASH:
		locked = false
	
	emit_signal("animation_finished", _anim_name)
