extends Node2D
class_name DashFlash

## Visual flash effect for player dash

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Connect to dash component signals
	var dash = get_parent().get_node_or_null("DashComponent")
	if dash:
		dash.dash_started.connect(_on_dash_started)

func _on_dash_started(_direction: Vector2) -> void:
	if animation_player:
		animation_player.play("flash")
