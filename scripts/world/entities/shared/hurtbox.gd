extends Area2D
class_name HurtboxComponent

signal hit(attacker: Node)

func _ready() -> void:
	body_entered.connect(_on_collision)
	area_entered.connect(_on_collision)

func _on_collision(collider: Node) -> void:
	emit_signal("hit", collider)
