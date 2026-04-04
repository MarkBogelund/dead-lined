extends Control

signal restart_game

@onready var drones_label: Label = $DronesLabel
@onready var turrets_label: Label = $TurretsLabel
@onready var waves_label: Label = $WavesLabel
@onready var crunch_time_label: Label = $CrunchTimeLabel
@onready var total_label: Label = $TotalLabel
@onready var restart_button: Button = $RestartButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	hide()

func show_stats_with_fade(breakdown: Dictionary) -> void:
	print("GameOverUI: show_stats_with_fade() called")
	
	# Set breakdown stats with scores
	var drones: int = breakdown.get("drones_destroyed", 0)
	var drones_score: int = breakdown.get("drones_score", 0)
	drones_label.text = "%d drones destroyed: $%d" % [drones, drones_score]
	
	var turrets: int = breakdown.get("turrets_destroyed", 0)
	var turrets_score: int = breakdown.get("turrets_score", 0)
	turrets_label.text = "%d turrets destroyed: $%d" % [turrets, turrets_score]
	
	var waves: int = breakdown.get("waves_survived", 0)
	var waves_score: int = breakdown.get("waves_score", 0)
	waves_label.text = "%d waves survived: $%d" % [waves, waves_score]
	
	var crunch_time: float = breakdown.get("crunch_time_spent", 0.0)
	var crunch_score: int = breakdown.get("crunch_time_score", 0)
	crunch_time_label.text = "%s spent in crunch time: $%d" % [_format_time(crunch_time), crunch_score]
	
	var total: int = breakdown.get("total_score", 0)
	total_label.text = "Total settlement: $%d" % total
	
	# Fade in with animation (no need to set modulate, animation handles it)
	show()
	animation_player.play("fade_in")

# Keep original for backward compatibility
func show_stats(stats: Dictionary) -> void:
	show_stats_with_fade(stats)

func _format_time(seconds: float) -> String:
	var minutes := floori(seconds / 60)
	var secs := int(seconds) % 60
	return "%d:%02d" % [minutes, secs]

func _on_restart_pressed() -> void:
	emit_signal("restart_game")
