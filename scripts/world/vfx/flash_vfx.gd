extends Node2D
class_name FlashVfx

## Reusable flash VFX component - white flash, red damage flash, etc.

@export var flash_color := Color.WHITE ## Color of the flash

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func start() -> void:
	if animation_player and animation_player.has_animation("flash"):
		visible = true
		animation_player.play("flash")
		# Hide after animation completes
		await animation_player.animation_finished
		visible = false
