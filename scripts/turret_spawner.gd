extends StaticBody2D
class_name TurretSpawner

var game_manager: GameManager
var menu_open := false
var current_state := "DISABLED" # "DISABLED", "IDLE", "PLAYER_IN_RANGE"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		push_error("GameManager not found")
		return

	game_manager.build_phase_started.connect(_on_build_phase_started)
	game_manager.combat_phase_started.connect(_on_combat_phase_started)

	_set_state("DISABLED")

func _unhandled_input(event: InputEvent) -> void:
	if current_state == "PLAYER_IN_RANGE" and event.is_action_pressed("open"):
		menu_open = not menu_open
		print("Menu opened" if menu_open else "Menu closed")

# --- STATE LOGIC ---

func _set_state(state: String) -> void:
	current_state = state

	match state:
		"DISABLED":
			_disable()
		"IDLE":
			_enable()
			menu_open = false
		"PLAYER_IN_RANGE":
			_enable()

func _enable():
	visible = true
	collision_shape.set_deferred("disabled", false)
	interaction_area.set_deferred("monitoring", true)
	interaction_area.set_deferred("monitorable", true)
	menu_open = false

func _disable():
	visible = false
	collision_shape.set_deferred("disabled", true)
	interaction_area.set_deferred("monitoring", false)
	interaction_area.set_deferred("monitorable", false)
	if menu_open:
		menu_open = false
		print("Menu closed")  # ensure menu closes when combat starts

# --- SIGNAL CALLBACKS ---

func _on_build_phase_started() -> void:
	_set_state("IDLE")

func _on_combat_phase_started(_wave: int) -> void:
	_set_state("DISABLED")

# --- PLAYER DETECTION ---

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state != "DISABLED":
		_set_state("PLAYER_IN_RANGE")

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and current_state != "DISABLED":
		_set_state("IDLE")
		menu_open = false
		print("Menu closed")
