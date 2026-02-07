extends StaticBody2D
class_name TurretSpawner

signal shop_opened
signal shop_closed

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")

var menu_open := false
enum State {
	DISABLED,
	IDLE,
	PLAYER_IN_RANGE
}

var current_state: State = State.DISABLED

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)

	_set_state(State.DISABLED)
	add_to_group("turret_spawners")

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.PLAYER_IN_RANGE:
		return

	if event.is_action_pressed("open"):
		if menu_open:
			close_menu()
		else:
			open_menu()

func _set_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	match current_state:
		State.DISABLED:
			close_menu()
			_disable()

		State.IDLE:
			close_menu()
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

func open_menu() -> void:
	if menu_open:
		return

	menu_open = true
	emit_signal("shop_opened")

func close_menu() -> void:
	if not menu_open:
		return

	menu_open = false
	emit_signal("shop_closed")

func _on_build_phase_started() -> void:
	_set_state(State.IDLE)

func _on_combat_phase_started(_wave: int) -> void:
	_set_state(State.DISABLED)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state != State.DISABLED:
		_set_state(State.PLAYER_IN_RANGE)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and current_state != State.DISABLED:
		_set_state(State.IDLE)
