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
	ghost_turret.range_radius = current_turret_entry.stats.max_range if current_turret_entry.stats else -1.0
	ghost_turret.exclusion_radius = current_turret_entry.stats.exclusion_radius if current_turret_entry.stats else -1.0
	get_tree().current_scene.add_child(ghost_turret)
	
	get_tree().call_group("turret_exclusion_zones", "show")
	
	active = true
	emit_signal("placement_started")

func cancel():
	_cleanup()
	emit_signal("turret_placement_cancelled")
	emit_signal("placement_ended")

func _place():
	# Check if placement is valid
	if ghost_turret and not ghost_turret.is_placement_valid():
		# Invalid placement - do not place turret
		# Optional: Add feedback (sound, screen shake, particle effect)
		return
	
	# Valid placement - proceed with turret placement
	var placed_turret := current_turret_entry.turret_scene.instantiate()
	placed_turret.position = ghost_turret.position
	get_tree().current_scene.add_child(placed_turret)
	placed_turret.add_to_group("turrets")
	
	_cleanup()
	emit_signal("turret_placed", placed_turret, current_turret_entry)
	emit_signal("placement_ended")

func _cleanup() -> void:
	if ghost_turret:
		ghost_turret.queue_free()
		ghost_turret = null
	get_tree().call_group("turret_exclusion_zones", "hide")
	active = false
