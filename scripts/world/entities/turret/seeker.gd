extends StaticBody2D
class_name Turret

signal died

## Components
@onready var shoot: ShootComponent = $ShootComponent
@onready var vfx_component: VFXComponent = $VFXComponent
@onready var animation: AnimationHandler = $AnimationHandler
@onready var health: HealthComponent = $HealthComponent
@onready var targeting: TargetingComponent = $TargetingComponent
@onready var aiming: AimingComponent = $AimingComponent

## Firing
@export var fire_rate := 0.5 # Seconds between shots
@export var vfx_scene: PackedScene

const UP_FACING_OFFSET := -PI / 2

var _fire_timer := 0.0
var _active := false
var enabled := true

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")
@onready var camera_shake_manager: CameraShakeManager = get_tree().get_first_node_in_group("camera_shake_manager")

func _ready() -> void:
	add_to_group("turrets")
	
	# Configure animations
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("recoil", 1, false)
	animation.configure_animation("take_damage", 2, true)
	animation.configure_animation("die", 3, true)
	
	wave_manager.combat_phase_started.connect(func(_i): _active = true)
	wave_manager.build_phase_started.connect(func(): _active = false)
	
	game_over_manager.game_over.connect(_on_game_over)

func _on_game_over() -> void:
	_active = false
	enabled = false

func _process(delta: float) -> void:
	if not _active or not enabled or is_dead():
		return
	
	_fire_timer -= delta
	
	var target := targeting.get_best_target(global_position)
	if not target:
		return
	
	aiming.aim_at(target.global_position, delta)
	
	if aiming.is_aimed_at(target.global_position):
		_fire_at()

func _fire_at() -> void:
	if _fire_timer > 0:
		return
	
	if shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction()):
		_fire_timer = fire_rate
		animation.play_animation("recoil")
		if vfx_scene and vfx_component:
			vfx_component.instantiate_vfx(vfx_scene, aiming.get_muzzle_position())

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
