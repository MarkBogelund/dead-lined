extends Area2D

@export var value := 1

var can_collect := false

func _ready():
	connect("body_entered", _on_body_entered)

func enable_collection() -> void:
	can_collect = true

func _on_body_entered(body: Node2D):
	if not can_collect:
		return

	if body.is_in_group("player"):
		body.collect_scrap(value)
		queue_free()
