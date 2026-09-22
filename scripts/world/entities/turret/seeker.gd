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
		return
	aiming.visual_node = $Visuals/Canon
	aiming.muzzle = $Visuals/Canon/Graphics/Muzzle
	initialize_base(stats.max_health, stats.capacity_drain_rate, stats.health_restore_rate, stats.repair_amount_per_wrench_hit, stats.exclusion_radius, stats.max_range)
	targeting.initialize(stats.max_range)
	targeting.configure_priorities({
		"enemies": stats.enemy_target_priority,
		"player": stats.player_target_priority,
	}, stats.priority_distance_threshold, stats.same_priority_switch_distance)
	shoot.initialize(stats.shoot_cooldown, stats.projectile_damage, stats.projectile_knockback, stats.projectile_speed)
	aiming.initialize(stats.aim_speed, stats.accuracy_angle)

func _on_combat_started() -> void:
	_shoot_delay = stats.shoot_start_delay

func _on_combat_stopped() -> void:
	_telegraphing = false

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
	if not animation.play_animation("shoot"):
		return
	_telegraphing = true

## Called by AnimationPlayer Call Method track at the fire keyframe
func _execute_shot() -> void:
	shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction())
	_telegraphing = false

func _before_damage_animation() -> void:
	_telegraphing = false

func _before_death_animation() -> void:
	_telegraphing = false

func get_damage_value() -> int:
	return shoot.projectile_damage

func apply_damage_upgrade(amount: int) -> void:
	shoot.projectile_damage += amount
