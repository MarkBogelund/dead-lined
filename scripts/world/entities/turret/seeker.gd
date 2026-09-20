extends StaticBody2D
class_name Turret

signal died

## Components
@onready var shoot: ShootComponent = $ShootComponent
@onready var animation: AnimationHandler = $AnimationHandler
@onready var health: HealthComponent = $HealthComponent
@onready var targeting: TargetingComponent = $TargetingComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var interaction_range: InteractionZone = $InteractionZone
@onready var health_ui: HealthUIComponent = $HealthUIComponent
@onready var upgrader: TurretUpgradeComponent = $TurretUpgradeComponent
@onready var repair: RepairComponent = $RepairComponent
@onready var exclusion_zone: TurretExclusionZone = $TurretExclusionZone
@onready var hud: TurretHUD = $TurretHUD
@onready var range_indicator: RangeIndicator = $RangeIndicator
@onready var windup_particles: GPUParticles2D = $WindupParticles

## Stats
@export var stats: SeekerStats

const UP_FACING_OFFSET := -PI / 2

var _active := false
var enabled := true
var _shoot_delay := 0.0
var _telegraphing := false

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")
@onready var player: Player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	add_to_group("turrets")
	_initialize()
	
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("shoot", 1, true)
	animation.configure_animation("repair", 3, true)
	animation.configure_animation("take_damage", 2, true)
	animation.configure_animation("die", 4, true)
	
	wave_manager.combat_phase_started.connect(func(_i: int) -> void: _active = true; _shoot_delay = stats.shoot_start_delay)
	wave_manager.build_phase_started.connect(func() -> void: _active = false)

	game_over_manager.game_over.connect(_on_game_over)

	interaction_range.player_entered.connect(func() -> void: health_ui.set_player_in_range(true); range_indicator.show_indicator())
	interaction_range.player_exited.connect(func() -> void: health_ui.set_player_in_range(false); range_indicator.hide_indicator())
	repair.repaired.connect(health.heal)
	repair.capacity_drained.connect(player.capacity.spend)
	repair.healing_started.connect(func() -> void: windup_particles.emitting = true)
	repair.healing_stopped.connect(func() -> void: windup_particles.emitting = false)

	hud.setup(self, player, wave_manager)
func _initialize() -> void:
	if not stats:
		return
	health.initialize(stats.max_health)
	repair.initialize(stats.capacity_drain_rate, stats.health_restore_rate, stats.repair_amount_per_wrench_hit)
	targeting.initialize(stats.max_range)
	exclusion_zone.initialize(stats.exclusion_radius)
	range_indicator.initialize(stats.max_range)
	shoot.initialize(stats.shoot_cooldown, stats.projectile_damage, stats.projectile_knockback, stats.projectile_speed)
	aiming.initialize(stats.aim_speed, stats.accuracy_angle)

func receive_wrench_hit() -> bool:
	if not health.is_full():
		repair.repair_once()
		animation.play_animation("repair")
		return true
	return false

func _on_game_over() -> void:
	_active = false
	enabled = false
	_telegraphing = false

func _process(delta: float) -> void:
	if not _active or not enabled or is_dead():
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

## Damage handling - called by enemy hitboxes
func was_hit(amount: int, _knockback_force: float, _from_position: Vector2) -> void:
	if is_dead():
		return
	
	var was_fatal := health.take_damage(amount)
	
	if was_fatal:
		_handle_death()
	else:
		_handle_damage()

func _handle_damage() -> void:
	_telegraphing = false
	animation.play_animation("take_damage")

func _handle_death() -> void:
	_telegraphing = false
	remove_from_group("turrets")
	
	# Disable turret functionality
	enabled = false
	_active = false
	
	# Play death animation
	animation.play_animation("die")
	
	# Emit signal
	died.emit()

func shake_screen(intensity: float, duration: float) -> void:
	camera_shake_manager.shake_screen(intensity, duration)

func is_dead() -> bool:
	return health.is_dead()
