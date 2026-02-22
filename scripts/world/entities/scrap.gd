extends Area2D

var resource_manager: ResourceManager

@export var value := 1

var can_collect := false

func _ready():
	resource_manager = get_tree().get_first_node_in_group("resource_manager")
	connect("body_entered", _on_body_entered)

func enable_collection() -> void:
	can_collect = true

func _on_body_entered(body: Node2D):
	if not can_collect:
		return

	if body.is_in_group("player"):
		resource_manager.scrap_amount += value
		queue_free()
