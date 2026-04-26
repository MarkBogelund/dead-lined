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

## Stats
@export var stats: SeekerStats

const UP_FACING_OFFSET := -PI / 2

var _active := false
var enabled := true
var _shoot_delay := 0.0

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")
@onready var player: Player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	add_to_group("turrets")
	_initialize()
	
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("recoil", 1, false)
	animation.configure_animation("repair", 2, true)
	animation.configure_animation("take_damage", 2, true)
	animation.configure_animation("die", 3, true)
	
	wave_manager.combat_phase_started.connect(func(_i): _active = true; _shoot_delay = stats.shoot_start_delay)
	wave_manager.build_phase_started.connect(func(): _active = false)

	game_over_manager.game_over.connect(_on_game_over)

	interaction_range.player_entered.connect(func(): health_ui.set_player_in_range(true))
	interaction_range.player_exited.connect(func(): health_ui.set_player_in_range(false))
	repair.repaired.connect(health.heal)
	repair.capacity_drained.connect(player.capacity.spend)

	hud.setup(self , player, wave_manager)
func _initialize() -> void:
	if not stats:
		return
	health.initialize(stats.max_health)
	repair.initialize(stats.capacity_drain_rate, stats.health_restore_rate, stats.repair_amount_per_player_shot)
	targeting.initialize(stats.max_range)
	exclusion_zone.initialize(stats.exclusion_radius)
	shoot.initialize(stats.shoot_cooldown, stats.projectile_damage, stats.projectile_knockback, stats.projectile_speed)
	aiming.initialize(stats.aim_speed, stats.accuracy_angle)

func receive_repair_shot() -> void:
	if not health.is_full():
		repair.receive_repair_shot()
		animation.play_animation("repair")

func _on_game_over() -> void:
	_active = false
	enabled = false

func _process(delta: float) -> void:
	if interaction_range.is_player_in_range() and not health.is_full() and Input.is_action_pressed("open"):
		repair.try_repair(delta, player.capacity.current_capacity)
	else:
		repair.reset()

	if not _active or not enabled or is_dead():
		return
	
	_shoot_delay -= delta
	
	var target := targeting.get_best_target(global_position, func(node: Node2D):
			return node != self and line_of_sight.can_see(global_position, node.global_position))
	if not target:
		return
	
	# Refresh debug state for the chosen target (filter calls pollute last_target with every candidate)
	if line_of_sight.debug_draw:
		line_of_sight.can_see(global_position, target.global_position)
	
	aiming.aim_at(target.global_position, delta)
	
	if aiming.is_aimed_at(target.global_position) and _shoot_delay <= 0.0:
		_fire_at()

func _fire_at() -> void:
	if shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction()):
		animation.play_animation("recoil")

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
	animation.play_animation("take_damage")

func _handle_death() -> void:
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
