extends Control

@onready var waves_label: Label = $WavesLabel
@onready var kills_label: Label = $KillsLabel
@onready var turrets_label: Label = $TurretsLabel
@onready var time_label: Label = $TimeLabel
@onready var scrap_label: Label = $ScrapLabel
@onready var restart_button: Button = $RestartButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	hide()

func show_stats_with_fade(stats: Dictionary) -> void:
	print("GameOverUI: show_stats_with_fade() called")
	
	# Set stats
	waves_label.text = "Waves Survived: %d" % stats.get("waves", 0)
	scrap_label.text = "Scrap Collected: %d" % stats.get("scrap", 0)
	turrets_label.text = "Turrets Placed: %d" % stats.get("turrets", 0)
	time_label.text = "Time Survived: %s" % _format_time(stats.get("time", 0.0))
	kills_label.text = "Enemies Killed: %d" % stats.get("kills", 0)
	
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
