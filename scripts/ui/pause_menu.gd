extends Control
class_name PauseMenu

## SYSTEM-layer menu. Overlays everything without closing world menus.
## Requires process_mode = ALWAYS so it works while the tree is paused.

@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var toggle_menu: ToggleMenuComponent


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	toggle_menu = ToggleMenuComponent.new()
	toggle_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	toggle_menu.open_on_button = true
	toggle_menu.close_on_toggle_button = true
	toggle_menu.open_action = &"pause"
	toggle_menu.open_fn = _do_open
	toggle_menu.close_fn = _do_close
	add_child(toggle_menu)

	resume_button.pressed.connect(func() -> void: toggle_menu.close())


func _do_open() -> void:
	animation_player.stop()
	get_tree().paused = true
	visible = true
	animation_player.play(&"appear")


func _do_close() -> void:
	get_tree().paused = false
	animation_player.play(&"disappear")
	await animation_player.animation_finished
	visible = false
