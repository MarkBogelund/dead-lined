extends Node2D
class_name TurretPlacer

signal turret_placed(turret_entry: TurretEntry)
signal turret_placement_cancelled
signal placement_started
signal placement_ended

@export var max_place_distance := 50
@export var player: CharacterBody2D

var current_turret_entry: TurretEntry
var ghost_turret: Node2D
var active := false

func _ready() -> void:
	add_to_group("turret_placer")

func _process(_delta: float) -> void:
	if active:
		update_position(get_global_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed("interact"):
		place()
		
	if event.is_action_pressed("cancel"):
		cancel()

func start_placement(turret_entry: TurretEntry):
	clear_ghost_turret()
	
	current_turret_entry = turret_entry
	
	ghost_turret = current_turret_entry.ghost_scene.instantiate()
	get_tree().current_scene.add_child(ghost_turret)

	active = true
	emit_signal("placement_started")

func update_position(mouse_world_pos: Vector2) -> void:
	if not ghost_turret or not player:
		return

	var direction := mouse_world_pos - player.position
	var distance := direction.length()

	if distance > max_place_distance:
		direction = direction.normalized() * max_place_distance

	ghost_turret.global_position = player.position + direction

func cancel():
	clear_ghost_turret()
	emit_signal("turret_placement_cancelled")
	emit_signal("placement_ended")

func clear_ghost_turret() -> void:
	if ghost_turret:
		ghost_turret.queue_free()
		ghost_turret = null
	active = false

func place():	
	var placed_turret := current_turret_entry.turret_scene.instantiate()
	placed_turret.position = ghost_turret.position
	get_tree().current_scene.add_child(placed_turret)
	
	clear_ghost_turret()
	emit_signal("turret_placed", current_turret_entry)
	emit_signal("placement_ended")
