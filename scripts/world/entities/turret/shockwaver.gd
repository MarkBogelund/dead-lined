extends TurretBase
class_name Shockwaver

@onready var shockwave: ShockwaveComponent = $ShockwaveComponent

@export var stats: ShockwaverStats

func _ready() -> void:
	_initialize()
	super._ready()
	animation.configure_animation("shock", 1, true)
	shockwave.windup_started.connect(_on_shockwave_windup_started)

func _initialize() -> void:
	if not stats:
		push_error("%s requires a ShockwaverStats resource" % name)
		return
	initialize_base(stats)
	shockwave.configure(stats.attack_range, stats.ring_thickness, stats.attack_cooldown, stats.expansion_duration, stats.damage, stats.knockback)

func _on_combat_started() -> void:
	shockwave.set_enabled(true)

func _on_combat_stopped() -> void:
	shockwave.set_enabled(false)

func _before_death_animation() -> void:
	shockwave.set_enabled(false)

func _stop_targeting_player() -> void:
	shockwave.trigger_on_player = false

func _on_shockwave_windup_started() -> void:
	# execute_shockwave() is keyed in the shock animation, so a blocked play (upgrade, repair) would strand the windup.
	if not animation.play_animation("shock"):
		shockwave.cancel_windup()

func get_damage_value() -> int:
	return shockwave.damage

func get_attack_cooldown_progress() -> float:
	return shockwave.get_cooldown_progress()

func set_damage(value: int) -> void:
	shockwave.damage = value

func set_attack_range(value: float) -> void:
	shockwave.set_max_range(value)
	range_indicator.initialize(shockwave.max_range)

func set_attack_cooldown(value: float) -> void:
	shockwave.cooldown = value