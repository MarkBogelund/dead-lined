extends Node2D
class_name TurretPlacer

signal turret_placed(turret_entry: TurretEntry)
signal turret_placement_cancelled
signal placement_started
signal placement_ended

@export var max_place_distance := 50

var current_turret_entry: TurretEntry
var ghost_turret: Node2D
var active := false
var player: CharacterBody2D

func _ready() -> void:
	add_to_group("turret_placer")
	player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if active and ghost_turret and player:
		var direction := get_global_mouse_position() - player.position
		if direction.length() > max_place_distance:
			direction = direction.normalized() * max_place_distance
		ghost_turret.global_position = player.position + direction

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	
	if event.is_action_pressed("interact"):
		_place()
	elif event.is_action_pressed("cancel"):
		cancel()

func start_placement(turret_entry: TurretEntry):
	_cleanup()
	
	current_turret_entry = turret_entry
	ghost_turret = current_turret_entry.ghost_scene.instantiate()
	get_tree().current_scene.add_child(ghost_turret)
	
	active = true
	emit_signal("placement_started")

func cancel():
	_cleanup()
	emit_signal("turret_placement_cancelled")
	emit_signal("placement_ended")

func _place():
	var placed_turret := current_turret_entry.turret_scene.instantiate()
	placed_turret.position = ghost_turret.position
	get_tree().current_scene.add_child(placed_turret)
	
	_cleanup()
	emit_signal("turret_placed", current_turret_entry)
	emit_signal("placement_ended")

func _cleanup() -> void:
	if ghost_turret:
		ghost_turret.queue_free()
		ghost_turret = null
	active = false
