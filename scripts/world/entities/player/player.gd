extends CharacterBody2D
class_name Player

signal damaged(current_health: int)
signal died

@onready var resource_manager: ResourceManager = %ResourceManager
@onready var stress_level_manager: StressLevelManager = %StressLevelManager
@onready var shop_manager: ShopManager = %ShopManager
@onready var game_over_manager: GameOverManager = %GameOverManager
@onready var camera_shake_manager = %CameraShakeManager
@onready var freeze_frame_manager = %FreezeFrameManager

@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var health: HealthComponent = $HealthComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var animation: AnimationHandler = $AnimationHandler
@onready var melee_weapon: MeleeWeapon = $MeleeWeapon
@onready var dash: DashComponent = $DashComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var crunch_time: CrunchTimeComponent = $CrunchTimeComponent
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var flash_vfx: FlashVfx = $FlashVfx
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var shoot_cost := 2
@export var dash_cost := 0

@export_group("Damage Effects")
@export var damage_knockback_force := 200.0
@export var damage_freeze_duration := 0.08
@export var damage_screen_shake_intensity := 0.2

@export_group("Death Effects")
@export var death_knockback_force := 400.0
@export var death_freeze_duration := 0.15
@export var death_screen_shake_intensity := 0.35

var can_move := true
const MIN_MOVE_SPEED := 10.0

## Crunch time state
var is_invincible := false

func _ready():
	# Configure animations
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("move", 1, false)
	animation.configure_animation("slash", 2, true)
	animation.configure_animation("dash", 2, true)
	animation.configure_animation("take_damage", 3, true)
	animation.configure_animation("die", 4, true)
	
	melee_weapon.slash_started.connect(_handle_slash_started)
	shop_manager.turret_placement_started.connect(_on_turret_placement_started)
	shop_manager.turret_placement_ended.connect(_on_turret_placement_ended)
	
	# Connect to crunch time signals
	crunch_time.crunch_time_started.connect(_on_crunch_time_started)
	crunch_time.crunch_time_ended.connect(_on_crunch_time_ended)

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
	
	# Don't change sprite direction during locked animations (slash, etc)
	if not animation.is_locked():
		_set_sprite_direction(velocity.x)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("shoot") and stress_level_manager.can_afford_safe(shoot_cost):
		var mouse_pos := get_global_mouse_position()
		aiming.aim_at(mouse_pos, global_position, 0.0) # Instant aiming (delta not used)
		if shoot.try_shoot(mouse_pos, global_position):
			stress_level_manager.subtract_stress(shoot_cost)
			animation.play_animation("slash") # Reuse slash animation for shooting since it has the same timing needs
	
	if event.is_action_pressed("slash"):
		melee_weapon.try_slash(get_global_mouse_position())
	
	if event.is_action_pressed("dash") and stress_level_manager.can_afford(dash_cost):
		var dash_dir = _get_dash_direction()
		if dash.try_dash(dash_dir):
			stress_level_manager.subtract_stress(dash_cost)
			_handle_dash_started(dash_dir)

func _update_animation():
	if is_dead():
		return # Die animation already playing from _handle_death
	
	# Try to play movement animations (respects locking automatically)
	if velocity.length() > MIN_MOVE_SPEED:
		animation.play_animation("move")
	else:
		animation.play_animation("idle")

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
	animation.play_animation("slash")

func _handle_dash_started(direction: Vector2):
	_set_sprite_direction(direction.x)
	animation.play_animation("dash")
	camera_shake_manager.shake_screen(0.15, 0.15)

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if is_dead() or dash.is_invincible() or is_invincible:
		return
	
	dash.cancel_dash()
	
	stress_level_manager.subtract_stress(amount)
	
	if stress_level_manager.current_stress <= 0.0:
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
	animation.play_animation("take_damage")
	
	# Notify external systems
	damaged.emit(int(stress_level_manager.current_stress))

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
	animation.play_animation("die")
	
	# Notify external systems
	damaged.emit(0) # HUD
	died.emit() # DeathSequenceController

func is_dead():
	return stress_level_manager != null and stress_level_manager.current_stress <= 0.0

func get_health():
	return int(stress_level_manager.current_stress) if stress_level_manager else 0

func collect_scrap(amount: int) -> void:
	stress_level_manager.add_stress(amount)

func _on_turret_placement_started():
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)

func _on_turret_placement_ended():
	shoot.set_enabled(true)
	melee_weapon.set_enabled(true)

## Crunch time activation - apply multiplicative buffs
func _on_crunch_time_started(buffs: Dictionary) -> void:
	is_invincible = true
	
	# Multiply current values by multipliers
	melee_weapon.hitbox.damage = int(melee_weapon.hitbox.damage * buffs["damage"])
	melee_weapon.slash_radius *= buffs["radius"]
	movement.speed *= buffs["speed"]
	melee_weapon.arc_angle *= buffs["arc_angle"]
	melee_weapon.scale *= buffs["weapon_size"]
	melee_weapon.slash_cooldown *= buffs["cooldown"]
	
	# Visual feedback - red tint
	animated_sprite.modulate = Color(1.5, 0.5, 0.5, 1.0) # Red glow

## Crunch time deactivation - remove multiplicative buffs
func _on_crunch_time_ended(buffs: Dictionary) -> void:
	is_invincible = false
	
	# Divide by same multipliers to reverse buffs
	melee_weapon.hitbox.damage = int(melee_weapon.hitbox.damage / buffs["damage"])
	melee_weapon.slash_radius /= buffs["radius"]
	movement.speed /= buffs["speed"]
	melee_weapon.arc_angle /= buffs["arc_angle"]
	melee_weapon.scale /= buffs["weapon_size"]
	melee_weapon.slash_cooldown /= buffs["cooldown"]
	
	# Reset visual feedback
	animated_sprite.modulate = Color.WHITE
