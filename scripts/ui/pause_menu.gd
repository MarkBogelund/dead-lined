extends Control
class_name PauseMenu

## SYSTEM-layer menu. Overlays everything without closing world menus.
## Requires process_mode = ALWAYS so it works while the tree is paused.
## Registers itself with MenuManager on _ready.

@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	MenuManager.register(
		&"pause",
		MenuManager.Layer.SYSTEM,
		_do_open,
		_do_close,
		&"",
		[]
	)
	resume_button.pressed.connect(func(): MenuManager.request_close(&"pause"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if MenuManager.is_open(&"pause"):
			MenuManager.request_close(&"pause")
		else:
			MenuManager.request_open(&"pause")
		get_viewport().set_input_as_handled()


func _do_open() -> void:
	animation_player.stop()
	get_tree().paused = true
	visible = true
	animation_player.play(&"appear")


func _do_close() -> void:
	# Unpause immediately so close animation plays at normal speed
	# and the game world can be seen resuming behind the fading overlay.
	get_tree().paused = false
	animation_player.play(&"disappear")
	await animation_player.animation_finished
	visible = false
