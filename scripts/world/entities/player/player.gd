extends CharacterBody2D
class_name Player

signal damaged(current_health: int)
signal died

@onready var resource_manager: ResourceManager = %ResourceManager
@onready var shop_manager: ShopManager = %ShopManager
@onready var game_over_manager: GameOverManager = %GameOverManager
@onready var camera_shake_manager = %CameraShakeManager
@onready var freeze_frame_manager = %FreezeFrameManager

@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var animation: AnimationComponent = $AnimationComponent
@onready var melee_weapon: MeleeWeapon = $MeleeWeapon
@onready var dash: DashComponent = $DashComponent
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var flash_vfx: FlashVfx = $FlashVfx
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export_group("Damage Effects")
@export var damage_knockback_force := 200.0
@export var damage_freeze_duration := 0.08
@export var damage_screen_shake_intensity := 0.2

@export_group("Death Effects")
@export var death_knockback_force := 400.0
@export var death_freeze_duration := 0.15
@export var death_screen_shake_intensity := 0.35

var can_move := true

@export var shoot_cost := 1
const MIN_MOVE_SPEED := 10.0

func _ready():
	melee_weapon.slash_started.connect(_handle_slash_started)
	shop_manager.turret_placement_started.connect(_on_turret_placement_started)
	shop_manager.turret_placement_ended.connect(_on_turret_placement_ended)

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	knockback.process(delta)
	
	if dash.is_dashing():
		velocity = dash.get_dash_velocity()
		# Use move_and_collide for fixed-distance dash without wall sliding
		var collision := move_and_collide(velocity * delta)
		if collision:
			dash.cancel_dash()
	else:
		if knockback.is_active():
			velocity = knockback.velocity
		elif can_move:
			velocity = movement.calculate_velocity(velocity, input_dir, delta)
		else:
			velocity = Vector2.ZERO
		
		move_and_slide()
	
	_update_animation()
	
	if animation.current_state != AnimationComponent.State.SLASH:
		_set_sprite_direction(velocity.x)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("shoot") and resource_manager.can_buy(shoot_cost):
		if shoot.try_shoot(get_global_mouse_position(), global_position):
			resource_manager.subtract_scrap(shoot_cost)
	
	if event.is_action_pressed("slash"):
		melee_weapon.try_slash(get_global_mouse_position())
	
	if event.is_action_pressed("dash"):
		var dash_dir = _get_dash_direction()
		if dash.try_dash(dash_dir):
			_handle_dash_started(dash_dir)

func _update_animation():
	if is_dead():
		animation.set_state(AnimationComponent.State.DIE)
		return
	
	if velocity.length() > MIN_MOVE_SPEED:
		animation.set_state(AnimationComponent.State.MOVE)
	else:
		animation.set_state(AnimationComponent.State.IDLE)

func _set_sprite_direction(dir_x: float):
	if dir_x != 0:
		animated_sprite.flip_h = dir_x < 0

func _get_dash_direction() -> Vector2:
	# If moving, dash in movement direction
	if velocity.length() > MIN_MOVE_SPEED:
		return velocity.normalized()
	
	# If idle, dash in the direction sprite is facing
	if animated_sprite.flip_h:
		return Vector2.LEFT
	else:
		return Vector2.RIGHT

func _handle_slash_started(target_pos: Vector2):
	_set_sprite_direction(target_pos.x - global_position.x)
	animation.set_state(AnimationComponent.State.SLASH)

func _handle_dash_started(direction: Vector2):
	_set_sprite_direction(direction.x)
	animation.set_state(AnimationComponent.State.DASH)
	camera_shake_manager.shake_screen(0.15, 0.15)

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead() or dash.is_invincible():
		return
	
	var was_fatal = health.take_damage(amount)
	
	if was_fatal:
		_handle_death(from_position)
	else:
		_handle_damage(from_position, knockback_force)

func _handle_damage(from_position: Vector2, knockback_force: float) -> void:
	# Apply knockback
	knockback.apply(from_position, knockback_force)
	
	# Visual feedback
	if hit_particles:
		hit_particles.restart()
	
	# Impact effects
	freeze_frame_manager.freeze(damage_freeze_duration)
	camera_shake_manager.shake_screen(damage_screen_shake_intensity, 0.3)
	
	# Animation
	animation.set_state(AnimationComponent.State.DAMAGE)
	
	# Notify external systems
	damaged.emit(health.get_current_health())

func _handle_death(from_position: Vector2) -> void:
	# Stronger knockback on death
	knockback.apply(from_position, death_knockback_force)
	
	# Visual feedback
	if hit_particles:
		hit_particles.restart()
	
	# Stronger impact effects on death
	freeze_frame_manager.freeze(death_freeze_duration)
	camera_shake_manager.shake_screen(death_screen_shake_intensity, 0.3)
	
	# Disable controls
	can_move = false
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)
	
	# Death VFX
	if flash_vfx:
		flash_vfx.start()
	
	# Animation
	animation.set_state(AnimationComponent.State.DIE)
	
	# Notify external systems
	damaged.emit(0) # HUD
	died.emit() # DeathSequenceController

func is_dead():
	return health.is_dead()

func get_health():
	return health.get_current_health()

func collect_scrap(amount: int) -> void:
	resource_manager.add_scrap(amount)

func _on_turret_placement_started():
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)

func _on_turret_placement_ended():
	shoot.set_enabled(true)
	melee_weapon.set_enabled(true)
