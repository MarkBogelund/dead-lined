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

## Balancing stats — assign in inspector or injected by TurretPlacer
@export var stats: TurretStats

## Firing
@export var fire_rate := 0.5 # Seconds between shots
@export var shoot_start_delay := 1.0 # Seconds after combat phase before shooting is allowed

const UP_FACING_OFFSET := -PI / 2

var _fire_timer := 0.0
var _active := false
var enabled := true
var _shoot_delay := 0.0

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")

func _ready() -> void:
	if stats:
		health.initialize(stats.max_health)
		targeting.max_range = stats.max_range
		fire_rate = stats.fire_rate
		shoot.projectile_damage = stats.projectile_damage
		shoot.projectile_knockback = stats.projectile_knockback
		shoot.projectile_speed = stats.projectile_speed
	
	add_to_group("turrets")
	
	# Configure animations
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("recoil", 1, false)
	animation.configure_animation("take_damage", 2, true)
	animation.configure_animation("die", 3, true)
	
	wave_manager.combat_phase_started.connect(func(_i): _active = true; _shoot_delay = shoot_start_delay)
	wave_manager.build_phase_started.connect(func(): _active = false)
	
	game_over_manager.game_over.connect(_on_game_over)

func _on_game_over() -> void:
	_active = false
	enabled = false

func _process(delta: float) -> void:
	if not _active or not enabled or is_dead():
		return
	
	_fire_timer -= delta
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
	if _fire_timer > 0:
		return
	
	if shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction()):
		_fire_timer = fire_rate
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

func despawn() -> void:
	queue_free()

func shake_screen(intensity: float, duration: float) -> void:
	camera_shake_manager.shake_screen(intensity, duration)

func is_dead() -> bool:
	return health.is_dead() if health else false
