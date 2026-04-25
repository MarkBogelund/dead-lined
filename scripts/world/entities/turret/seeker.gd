extends StaticBody2D
class_name Turret

signal died
signal upgrade_requested(turret: Turret)

## Components
@onready var shoot: ShootComponent = $ShootComponent
@onready var animation: AnimationHandler = $AnimationHandler
@onready var health: HealthComponent = $HealthComponent
@onready var targeting: TargetingComponent = $TargetingComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var line_of_sight: LineOfSightComponent = $LineOfSightComponent
@onready var interaction_range: InteractionRangeComponent = $InteractionRangeComponent
@onready var health_ui: HealthUIComponent = $HealthUIComponent

## Stats
@export var stats: SeekerStats

const UP_FACING_OFFSET := -PI / 2

var _active := false
var enabled := true
var _shoot_delay := 0.0
var _repair_accumulator := 0.0
var level := 1
var _is_build_phase := true

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")

func _ready() -> void:
	add_to_group("turrets")
	_initialize()
	
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("recoil", 1, false)
	animation.configure_animation("take_damage", 2, true)
	animation.configure_animation("die", 3, true)
	
	wave_manager.combat_phase_started.connect(func(_i): _active = true; _shoot_delay = stats.shoot_start_delay)
	wave_manager.build_phase_started.connect(func(): _active = false)
	wave_manager.combat_phase_started.connect(func(_i): _is_build_phase = false)
	wave_manager.build_phase_started.connect(func(): _is_build_phase = true)
	
	game_over_manager.game_over.connect(_on_game_over)

	interaction_range.player_entered.connect(func(): health_ui.set_player_in_range(true))
	interaction_range.player_exited.connect(func(): health_ui.set_player_in_range(false))

func _initialize() -> void:
	if not stats:
		return
	health.initialize(stats.max_health)
	targeting.max_range = stats.max_range
	shoot.shoot_cooldown = stats.shoot_cooldown
	shoot.projectile_damage = stats.projectile_damage
	shoot.projectile_knockback = stats.projectile_knockback
	shoot.projectile_speed = stats.projectile_speed
	aiming.aim_speed = stats.aim_speed
	aiming.accuracy_angle = stats.accuracy_angle

func _on_game_over() -> void:
	_active = false
	enabled = false

func _unhandled_input(event: InputEvent) -> void:
	if not _is_build_phase or is_dead():
		return
	if not interaction_range.is_player_in_range():
		return
	if event.is_action_pressed("open"):
		get_viewport().set_input_as_handled()
		upgrade_requested.emit(self)

func _process(delta: float) -> void:
	_handle_repair(delta)

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

func _handle_repair(delta: float) -> void:
	if _is_build_phase or is_dead() or not interaction_range.is_player_in_range():
		_repair_accumulator = 0.0
		return
	if not Input.is_action_pressed("open"):
		_repair_accumulator = 0.0
		return
	if health.get_current_health() >= health.max_health:
		_repair_accumulator = 0.0
		return
	var player := interaction_range.get_player()
	if not player:
		_repair_accumulator = 0.0
		return
	var drain := stats.capacity_drain_rate * delta
	if not player.capacity.can_afford(drain):
		_repair_accumulator = 0.0
		return
	player.capacity.spend(drain)
	_repair_accumulator += stats.health_restore_rate * delta
	if _repair_accumulator >= 1.0:
		var to_heal := int(_repair_accumulator)
		health.heal(to_heal)
		_repair_accumulator -= float(to_heal)

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

func apply_health_upgrade() -> void:
	level += 1
	health.increase_max_health(stats.health_upgrade_amount)

func apply_damage_upgrade() -> void:
	level += 1
	shoot.projectile_damage += stats.damage_upgrade_amount

func despawn() -> void:
	queue_free()

func shake_screen(intensity: float, duration: float) -> void:
	camera_shake_manager.shake_screen(intensity, duration)

func is_dead() -> bool:
	return health.is_dead() if health else false
