extends TurretBase
class_name Turret

@onready var shoot: ShootComponent = $ShootComponent
@onready var targeting: TargetingComponent = $TargetingComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent

## Stats
@export var stats: SeekerStats

const UP_FACING_OFFSET := -PI / 2

var _shoot_delay := 0.0
var _telegraphing := false

func _ready() -> void:
	_initialize()
	super._ready()
	animation.configure_animation("shoot", 1, true)

func _initialize() -> void:
	if not stats:
		push_error("%s requires a SeekerStats resource" % name)
		return
	aiming.visual_node = $Visuals/Canon
	aiming.muzzle = $Visuals/Canon/Graphics/Muzzle
	initialize_base(stats)
	targeting.initialize(stats.attack_range)
	targeting.configure(stats.targeting)
	shoot.initialize(stats.attack_cooldown, stats.damage, stats.knockback, stats.projectile_speed)
	aiming.initialize(stats.aim_speed, stats.aim_tolerance)

func _on_combat_started() -> void:
	_shoot_delay = stats.first_shot_delay

func _on_combat_stopped() -> void:
	_telegraphing = false

func _stop_targeting_player() -> void:
	targeting.set_group_enabled(&"player", false)

func _process(delta: float) -> void:
	if not is_turret_active():
		return
	
	_shoot_delay -= delta
	
	var target := targeting.get_best_target(global_position, func(node: Node2D) -> bool:
			return node != self and line_of_sight.can_see(global_position, node.global_position))
	if not target:
		return
	
	# Refresh debug state for the chosen target (filter calls pollute last_target with every candidate)
	if line_of_sight.debug_draw:
		line_of_sight.can_see(global_position, target.global_position)
	
	aiming.aim_at(target.global_position, delta)
	
	if aiming.is_aimed_at(target.global_position) and _shoot_delay <= 0.0 and not _telegraphing and shoot.is_ready():
		_begin_telegraph()

func _begin_telegraph() -> void:
	# A cooldown shorter than the shoot animation would otherwise latch _telegraphing without firing.
	if animation.get_current_anim_name() == "shoot" and animation.is_playing():
		return
	if not animation.play_animation("shoot"):
		return
	_telegraphing = true

## Called by AnimationPlayer Call Method track at the fire keyframe
func _execute_shot() -> void:
	shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction())
	_telegraphing = false

func _before_death_animation() -> void:
	_telegraphing = false

func get_damage_value() -> int:
	return shoot.projectile_damage

func set_damage(value: int) -> void:
	shoot.projectile_damage = value

func set_attack_range(value: float) -> void:
	targeting.max_range = value
	range_indicator.initialize(value)

func set_attack_cooldown(value: float) -> void:
	shoot.shoot_cooldown = value
