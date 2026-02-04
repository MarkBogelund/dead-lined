extends Node
class_name WaveManager

@export var time_between_waves := 5.0

var _wave_timer := 0.0
var _wave_index := 0

func _ready() -> void:
	_wave_timer = time_between_waves

func _process(delta: float) -> void:
	_wave_timer -= delta

	if _wave_timer <= 0.0:
		_start_next_wave()
		_wave_timer = time_between_waves

func _start_next_wave() -> void:
	_wave_index += 1
	print("Starting wave", _wave_index)

	var spawners: Array[Node] = get_tree().get_nodes_in_group("enemy_spawners")
	for spawner in spawners:
		spawner.spawn_wave()
