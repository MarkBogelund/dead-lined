extends StaticBody2D
class_name Turret

signal died

## Components
@onready var shoot: ShootComponent = $ShootComponent
@onready var vfx_component: VFXComponent = $VFXComponent
@onready var animation: AnimationHandler = $AnimationHandler
@onready var health: HealthComponent = $HealthComponent
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var flash_vfx: FlashVfx = $FlashVfx
@onready var health_ui: HealthUIComponent = $HealthUIComponent
@onready var canon: Node2D = $Canon
@onready var muzzle: Marker2D = $Canon/Graphics/Muzzle
@onready var targeting: TargetingComponent = $TargetingComponent
@onready var aiming: AimingComponent = $AimingComponent

## Targeting
@export var detection_angle := 0.2 # Radians from aim direction

## Firing
@export var fire_rate := 0.5 # Seconds between shots
@export var vfx_scene: PackedScene

const UP_FACING_OFFSET := -PI / 2

var _fire_timer := 0.0
var _active := false
var enabled := true

@onready var wave_manager: WaveManager = get_tree().get_first_node_in_group("wave_manager")
@onready var game_over_manager: GameOverManager = get_tree().get_first_node_in_group("game_over_manager")

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
	
	aiming.aim_at(target.global_position, canon.global_position, delta)
	
	if aiming.is_aimed_at(target.global_position, canon.global_position, detection_angle):
		_fire_at(target.global_position)

func _fire_at(target_pos: Vector2) -> void:
	if _fire_timer > 0:
		return
	
	if shoot.try_shoot(target_pos, muzzle.global_position):
		_fire_timer = fire_rate
		animation.play_animation("recoil")
		if vfx_scene and vfx_component:
			vfx_component.instantiate_vfx(vfx_scene, muzzle.global_position)

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
	if hit_particles:
		hit_particles.restart()
	
	animation.play_animation("take_damage")

func _handle_death() -> void:
	# Remove from turrets group so enemies stop targeting
	remove_from_group("turrets")
	
	# Disable turret functionality
	enabled = false
	_active = false
	
	# Visual feedback
	if hit_particles:
		hit_particles.restart()
	
	if flash_vfx:
		flash_vfx.start()
	
	# Play death animation
	animation.play_animation("die")
	
	# Emit signal
	died.emit()
	
	# Despawn after delay (give time for animation and VFX)
	await get_tree().create_timer(0.8).timeout
	despawn()

func despawn() -> void:
	queue_free()

func is_dead() -> bool:
	return health.is_dead() if health else false
