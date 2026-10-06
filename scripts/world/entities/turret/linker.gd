extends TurretBase
class_name Linker

@onready var linker: LinkerComponent = $LinkerComponent

@export var stats: LinkerStats

func _ready() -> void:
	_initialize()
	linker.chain_started.connect(_on_chain_started)
	linker.chain_fired.connect(_on_chain_fired)
	linker.chain_cancelled.connect(_on_chain_cancelled)
	animation.configure_animation("charge", 2, true)
	super._ready()

func _initialize() -> void:
	if not stats:
		push_error("%s requires a LinkerStats resource" % name)
		return
	initialize_base(stats)
	linker.configure(stats.attack_range, stats.charge_duration, stats.attack_cooldown, stats.damage, stats.knockback)

func _on_combat_started() -> void:
	linker.set_enabled(true)

func _on_combat_stopped() -> void:
	linker.set_enabled(false)
	animation.stop_animation("charge")

func _before_death_animation() -> void:
	_on_combat_stopped()

func _stop_targeting_player() -> void:
	linker.set_player_targeting_enabled(false)

func _on_chain_started() -> void:
	var speed := animation.get_animation_length("charge") / stats.charge_duration
	if not animation.play_animation("charge", -1, speed):
		linker.cancel_charge()

func _on_chain_fired(_target_count: int) -> void:
	animation.stop_animation("charge")

func _on_chain_cancelled() -> void:
	animation.stop_animation("charge")

func get_damage_value() -> int:
	return linker.damage

func get_attack_cooldown_progress() -> float:
	return linker.get_cooldown_progress()

func set_damage(value: int) -> void:
	linker.damage = value

func set_attack_range(value: float) -> void:
	linker.link_range = value
	range_indicator.initialize(value)

func set_attack_cooldown(value: float) -> void:
	linker.attack_cooldown = value