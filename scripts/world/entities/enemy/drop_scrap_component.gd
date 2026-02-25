extends Node
class_name DropScrapComponent

@export var scrap_drop_amount := 1
@export var scrap_drop_radius := 48.0
@export var scrap_scene: PackedScene
@export var scatter_duration := 0.2

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
		
		# Set initial position at drop point
		scrap.global_position = drop_position
		
		# Calculate random scatter position
		var angle := randf() * TAU
		var dir := Vector2(cos(angle), sin(angle))
		var distance := randf() * scrap_drop_radius
		var target_pos := drop_position + dir * distance
		
		# Animate scrap to scatter position (bind tween to scrap node)
		var tween := scrap.create_tween()
		tween.tween_property(
			scrap,
			"global_position",
			target_pos,
			scatter_duration
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		# Enable collection immediately
		scrap.enable_collection()
