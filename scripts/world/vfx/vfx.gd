extends Node2D
class_name Vfx

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func start() -> void:
	animation_player.play("start")
