extends TurretBase
class_name Attractor

@onready var radial_field: RadialFieldComponent = $RadialFieldComponent

@export var stats: AttractorStats

func _ready() -> void:
	_initialize()
	super._ready()
	animation.configure_animation("pulse", 1, true)
	radial_field.windup_started.connect(_on_field_windup_started)

func _initialize() -> void:
	if not stats:
		push_error("%s requires an AttractorStats resource" % name)
		return
	initialize_base(stats)
	radial_field.configure(stats.attack_range, stats.attack_cooldown, stats.windup_duration, stats.pull_duration, stats.pull_speed, stats.enemy_pull_multiplier, stats.player_pull_multiplier, stats.inner_dead_zone, stats.edge_pull_fraction, stats.damage, false, false)
	range_indicator.initialize(stats.attack_range, stats.inner_dead_zone)

func _on_combat_started() -> void:
	radial_field.set_enabled(true)

func _on_combat_stopped() -> void:
	radial_field.set_enabled(false)

func _before_death_animation() -> void:
	radial_field.set_enabled(false)

func _stop_targeting_player() -> void:
	pass
	
func _on_field_windup_started() -> void:
	var speed := animation.get_animation_length("pulse") / stats.windup_duration
	if not animation.play_animation("pulse", -1, speed):
		radial_field.cancel_windup()

func get_damage_value() -> int:
	return radial_field.damage

func get_attack_cooldown_progress() -> float:
	return radial_field.get_cooldown_progress()

func set_damage(value: int) -> void:
	radial_field.damage = value

func set_attack_range(value: float) -> void:
	radial_field.set_max_range(value)
	range_indicator.initialize(value, stats.inner_dead_zone)

func set_attack_cooldown(value: float) -> void:
	radial_field.cooldown = value