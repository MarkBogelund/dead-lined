extends Control

signal restart_game

@onready var drones_label: Label = %DronesLabel
@onready var waves_label: Label = %WavesLabel
@onready var crunch_time_label: Label = %CrunchTimeLabel
@onready var total_label: Label = %TotalLabel
@onready var restart_button: Button = %RestartButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	hide()
	MenuManager.register(&"game_over", MenuManager.Layer.GAME_OVER, Callable(), Callable())

func show_stats_with_fade(breakdown: Dictionary) -> void:
	# Set breakdown stats with scores
	var drones: int = breakdown.get("drones_destroyed", 0)
	var drones_score: int = breakdown.get("drones_score", 0)
	drones_label.text = "%d drones destroyed: $%d" % [drones, drones_score]
	
	var waves: int = breakdown.get("waves_survived", 0)
	var waves_score: int = breakdown.get("waves_score", 0)
	waves_label.text = "%d waves survived: $%d" % [waves, waves_score]
	
	var crunch_time: float = breakdown.get("crunch_time_spent", 0.0)
	var crunch_score: int = breakdown.get("crunch_time_score", 0)
	crunch_time_label.text = "%s crunch time: $%d" % [_format_time(crunch_time), crunch_score]
	
	var total: int = breakdown.get("total_score", 0)
	total_label.text = "Total settlement: $%d" % total
	
	# Fade in with animation (no need to set modulate, animation handles it)
	show()
	restart_button.grab_focus()
	animation_player.play("fade_in")
	MenuManager.request_open(&"game_over")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_on_restart_pressed()

# Keep original for backward compatibility
func show_stats(stats: Dictionary) -> void:
	show_stats_with_fade(stats)

func _format_time(seconds: float) -> String:
	var minutes := floori(seconds / 60)
	var secs := int(seconds) % 60
	return "%d:%02d" % [minutes, secs]

func _on_restart_pressed() -> void:
	restart_game.emit()
