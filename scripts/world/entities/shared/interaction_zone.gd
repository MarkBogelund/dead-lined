extends Area2D
class_name InteractionZone

## Detects when the player enters or exits the interaction radius.

signal player_entered
signal player_exited

var _player_in_range := false
var _player: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_player = body
		player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_player = null
		player_exited.emit()

func is_player_in_range() -> bool:
	return _player_in_range

func get_player() -> Node2D:
	return _player
