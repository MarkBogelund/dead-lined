extends StaticBody2D
class_name TurretBase

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")

@export var detection_range := 500.0

var build_phase := true

func _ready():
	wave_manager.build_phase_started.connect(_on_build_phase_started)
	wave_manager.combat_phase_started.connect(_on_combat_phase_started)
	
func get_closest_enemy_in_range() -> CharacterBody2D:
	var targets: Array[Node] = []
	targets.append_array(get_tree().get_nodes_in_group("enemies"))
	targets.append_array(get_tree().get_nodes_in_group("player"))

	var closest: CharacterBody2D = null
	var closest_dist := detection_range * detection_range

	for target in targets:
		if target.is_dead():
			continue

		var dist := global_position.distance_squared_to(target.global_position)
		if dist <= closest_dist:
			closest_dist = dist
			closest = target

	return closest	
	
func _on_build_phase_started() -> void:
	build_phase = true

func _on_combat_phase_started(_wave_index: int) -> void:
	build_phase = false
