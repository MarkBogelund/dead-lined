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
		return
	initialize_base(stats.max_health, stats.capacity_drain_rate, stats.health_restore_rate, stats.repair_amount_per_wrench_hit, stats.exclusion_radius, stats.shockwave_radius)
	shockwave.configure(stats.contact_radius, stats.shockwave_radius, stats.ring_thickness, stats.cooldown, stats.windup_duration, stats.expansion_duration, stats.damage)

func _on_combat_started() -> void:
	shockwave.set_enabled(true)

func _on_combat_stopped() -> void:
	shockwave.set_enabled(false)

func _before_death_animation() -> void:
	shockwave.set_enabled(false)

func _on_shockwave_windup_started() -> void:
	animation.play_animation("shock")

func get_damage_value() -> int:
	return shockwave.damage

func apply_damage_upgrade(amount: int) -> void:
	shockwave.apply_damage_upgrade(amount)