extends StaticBody2D
class_name TurretSpawner

signal shop_opened
signal shop_closed

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea

var shop_open := false
enum State {
	DISABLED,
	IDLE,
	PLAYER_IN_RANGE
}

#@export var turret_entries: Array[TurretEntry]

var current_state: State = State.DISABLED

func _ready() -> void:
	_set_state(State.DISABLED)
	add_to_group("turret_spawners")

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.PLAYER_IN_RANGE:
		return

	if event.is_action_pressed("open"):
		if shop_open:
			close_shop()
		else:
			open_shop()

func _set_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	match current_state:
		State.DISABLED:
			close_shop()
			_disable()

		State.IDLE:
			close_shop()
			_enable()

		State.PLAYER_IN_RANGE:
			_enable()

func _enable() -> void:
	visible = true
	collision_shape.set_deferred("disabled", false)
	interaction_area.set_deferred("monitoring", true)
	interaction_area.set_deferred("monitorable", true)

func _disable() -> void:
	visible = false
	collision_shape.set_deferred("disabled", true)
	interaction_area.set_deferred("monitoring", false)
	interaction_area.set_deferred("monitorable", false)

func open_shop() -> void:
	if shop_open:
		return
		
	shop_open = true
	emit_signal("shop_opened")

func close_shop() -> void:
	if not shop_open:
		return

	shop_open = false
	emit_signal("shop_closed")

func build_phase_started():
	_set_state(State.IDLE)
	
func combat_phase_started():
	_set_state(State.DISABLED)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state != State.DISABLED:
		_set_state(State.PLAYER_IN_RANGE)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and current_state != State.DISABLED:
		_set_state(State.IDLE)
