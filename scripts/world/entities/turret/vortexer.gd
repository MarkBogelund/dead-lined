extends TurretBase
class_name Vortexer

@onready var magnetic_field: MagneticFieldComponent = $MagneticFieldComponent

@export var stats: VortexerStats

func _ready() -> void:
	_initialize()
	super._ready()
	animation.configure_animation("pulse", 1, true)
	magnetic_field.windup_started.connect(_on_field_windup_started)

func _initialize() -> void:
	if not stats:
		push_error("%s requires a VortexerStats resource" % name)
		return
	initialize_base(stats)
	magnetic_field.configure(stats)

func _on_combat_started() -> void:
	magnetic_field.set_enabled(true)

func _on_combat_stopped() -> void:
	magnetic_field.set_enabled(false)

func _before_death_animation() -> void:
	magnetic_field.set_enabled(false)

func _stop_targeting_player() -> void:
	magnetic_field.affect_player = false

func _on_field_windup_started() -> void:
	var speed := animation.get_animation_length("pulse") / stats.windup_duration
	if not animation.play_animation("pulse", -1, speed):
		magnetic_field.cancel_windup()

func get_damage_value() -> int:
	return magnetic_field.damage

func set_damage(value: int) -> void:
	magnetic_field.damage = value

func set_attack_range(value: float) -> void:
	magnetic_field.set_max_range(value)
	range_indicator.initialize(value)

func set_attack_cooldown(value: float) -> void:
	magnetic_field.cooldown = value