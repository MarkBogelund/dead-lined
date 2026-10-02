extends TurretBase
class_name Beamer

@onready var beam: BeamComponent = $BeamComponent

@export var stats: BeamerStats

func _ready() -> void:
	_initialize()
	beam.windup_started.connect(_on_windup_started)
	beam.firing_started.connect(_on_firing_started)
	animation.configure_animation("windup", 1, false)
	animation.configure_animation("fire", 1, false)
	super._ready()

func _initialize() -> void:
	if not stats:
		push_error("%s requires a BeamerStats resource" % name)
		return
	initialize_base(stats)
	beam.configure(stats.attack_range, stats.beam_width, stats.damage_interval, stats.windup_duration, stats.lock_break_distance, stats.damage, stats.knockback, stats.sweep_speed_degrees, stats.tracking_speed_degrees)

func _on_combat_started() -> void:
	beam.set_enabled(true)

func _on_combat_stopped() -> void:
	beam.set_enabled(false)
	animation.stop_animation("fire")
	animation.stop_animation("windup")

func _before_death_animation() -> void:
	_on_combat_stopped()

func _on_windup_started() -> void:
	animation.stop_animation("fire")
	var duration := stats.windup_duration
	animation.play_animation("windup", -1, animation.get_animation_length("windup") / duration)

func _on_firing_started() -> void:
	animation.play_animation("fire")

func get_damage_value() -> int:
	return beam.damage

func set_damage(value: int) -> void:
	beam.set_damage(value)

func set_attack_range(value: float) -> void:
	beam.set_range(value)
	range_indicator.initialize(value)
