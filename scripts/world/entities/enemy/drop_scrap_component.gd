extends Node
class_name DropScrapComponent

@export var scrap_drop_amount := 1
@export var scrap_scene: PackedScene
@export var impulse_min := 100.0
@export var impulse_max := 300.0
@export var linear_damp := 3.0  ## How quickly scrap slows down (higher = stops faster)
@export var freeze_delay := 0.3  ## Seconds until scrap stops moving completely

var parent: Node2D

func _ready() -> void:
	if not get_parent() is Node2D:
		push_error("DropScrapComponent must be a child of a Node2D entity")
	else:
		parent = get_parent()

func drop() -> void:
	if not parent or not scrap_scene:
		return
	
	var drop_position := parent.global_position
	
	for i in scrap_drop_amount:
		var scrap = scrap_scene.instantiate()
		get_tree().current_scene.add_child(scrap)
		
		scrap.global_position = drop_position
		
		# Setup physics properties
		scrap.gravity_scale = 0.0
		scrap.lock_rotation = true
		scrap.linear_damp = linear_damp
		
		# Apply random impulse in random direction
		var angle := randf() * TAU
		var dir := Vector2(cos(angle), sin(angle))
		var strength := randf_range(impulse_min, impulse_max)
		scrap.apply_impulse(dir * strength)
		
		scrap.enable_collection()
		
		# Freeze after delay
		_freeze_scrap_after_delay(scrap, freeze_delay)

func _freeze_scrap_after_delay(scrap: RigidBody2D, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(scrap):
		scrap.freeze = true
