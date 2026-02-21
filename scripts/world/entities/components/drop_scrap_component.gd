extends Node
class_name DropScrapComponent

@export var scrap_drop_amount := 1
@export var scrap_drop_radius := 0.0
@export var scrap_scene: PackedScene

var parent: Node2D

func _ready() -> void:
	if not get_parent() is Node2D:
		push_error("DropScrapComponent must be a child of a Node2D entity")
	else:
		parent = get_parent()

func drop() -> void:
	if not parent:
		return
	
	for i in scrap_drop_amount:
		var scrap = scrap_scene.instantiate()
		scrap.set_explosion(parent.global_position, scrap_drop_radius)
		get_tree().current_scene.add_child(scrap)
