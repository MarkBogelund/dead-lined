extends Node2D
class_name TurretPlacer

signal turret_placed(turret: Node, turret_entry: TurretEntry)
signal turret_placement_cancelled
signal placement_started
signal placement_ended

@export var max_place_distance := 50
@onready var player: CharacterBody2D = %Player

var current_turret_entry: TurretEntry
var ghost_turret: Node2D
var active := false

func _process(_delta: float) -> void:
	if active and ghost_turret and player:
		var mouse_delta := get_global_mouse_position() - player.position
		var direction := InputManager.get_smoothed_pointing_vector(mouse_delta, max_place_distance)
		if direction.length() > max_place_distance:
			direction = direction.normalized() * max_place_distance
		ghost_turret.global_position = player.position + direction

func _input(event: InputEvent) -> void:
	if not active:
		return
	
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		InputManager.consume_attack_until_release()
		_place()
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		cancel()

func start_placement(turret_entry: TurretEntry) -> void:
	_cleanup()
	
	current_turret_entry = turret_entry
	ghost_turret = current_turret_entry.ghost_scene.instantiate()
	ghost_turret.initialize(
		current_turret_entry.stats.attack_range,
		current_turret_entry.exclusion_radius)
	get_tree().current_scene.add_child(ghost_turret)
	
	get_tree().call_group("turret_exclusion_zones", "show")
	
	active = true
	placement_started.emit()

func cancel() -> void:
	_cleanup()
	turret_placement_cancelled.emit()
	placement_ended.emit()

func _place() -> void:
	# Check if placement is valid
	if ghost_turret and not ghost_turret.is_placement_valid():
		# Invalid placement - do not place turret
		# Optional: Add feedback (sound, screen shake, particle effect)
		return
	
	# Valid placement - proceed with turret placement
	var placed_turret := current_turret_entry.turret_scene.instantiate()
	placed_turret.position = ghost_turret.position
	get_tree().current_scene.add_child(placed_turret)
	
	_cleanup()
	turret_placed.emit(placed_turret, current_turret_entry)
	placement_ended.emit()

func _cleanup() -> void:
	if ghost_turret:
		ghost_turret.queue_free()
		ghost_turret = null
	get_tree().call_group("turret_exclusion_zones", "hide")
	active = false
