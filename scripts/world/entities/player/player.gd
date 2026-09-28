extends CharacterBody2D
class_name Player

signal damaged(current_capacity: float)
signal died

@onready var wave_manager: WaveManager = %WaveManager
@onready var shop_manager: ShopManager = %ShopManager
@onready var game_over_manager: GameOverManager = %GameOverManager
@onready var camera_shake_manager: CameraShakeManager = %CameraShakeManager
@onready var time_scale_manager: TimeScaleManager = %TimeScaleManager

@onready var capacity: CapacityComponent = $CapacityComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var animation: AnimationHandler = $AnimationHandler
@onready var melee_weapon: MeleeWeapon = $MeleeWeapon
@onready var dash: DashComponent = $DashComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var aim_indicator: AimIndicator = $AimIndicator
@onready var dash_direction_indicator: DashDirectionIndicator = $DashDirectionIndicator
@onready var crunch_time: CrunchTimeComponent = $CrunchTimeComponent
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var crunch_shine_particles: GPUParticles2D = $CrunchShineParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: GameCamera = $"Camera2D"

@export var stats: PlayerStats

@export_group("Dash Charge Presentation")
@export_range(1.0, 2.0, 0.01) var dash_charge_zoom := 1.15
@export_range(0.0, 1.0, 0.01) var dash_charge_zoom_in_duration := 0.2
@export_range(0.0, 1.0, 0.01) var dash_charge_zoom_out_duration := 0.15

var damage_knockback_force := 200.0
var damage_freeze_duration := 0.1
var damage_screen_shake_intensity := 0.2
var death_knockback_force := 400.0
var death_freeze_duration := 0.15
var death_screen_shake_intensity := 0.35
var dash_charge_time_scale := 0.5

const DASH_CHARGE_SOURCE := &"dash_charge"

enum MoveState {NORMAL, DASHING, KNOCKED, FROZEN}

var can_move := true
var _facing_right := true
var _is_dead := false
var _base_velocity := Vector2.ZERO

const MIN_MOVE_SPEED := 10.0
const PLAYER_BODY_LAYER := 2 ## Matches project.godot 2d_physics layer_2 ("PlayerBody")
const TURRET_BODY_LAYER := 6 ## Matches project.godot 2d_physics layer_6 ("TurretBody")

var _conveyor_velocity := Vector2.ZERO
var _shoot_held := false

func set_conveyor_velocity(conveyor_velocity: Vector2) -> void:
	_conveyor_velocity = conveyor_velocity

func clear_conveyor_velocity() -> void:
	_conveyor_velocity = Vector2.ZERO

func _add_conveyor_velocity() -> void:
	velocity += _conveyor_velocity

func _ready() -> void:
	_initialize()
	_setup_animations()
	_connect_signals()

func _initialize() -> void:
	if not stats:
		push_error("%s requires a PlayerStats resource" % name)
		return
	movement.initialize(stats.speed, stats.acceleration, stats.friction)
	dash.initialize(stats.dash_min_distance, stats.dash_max_distance, stats.dash_speed, stats.dash_charge_delay, stats.dash_max_charge_time, stats.dash_cooldown)
	dash_charge_time_scale = stats.dash_charge_time_scale
	melee_weapon.initialize(stats.slash_damage, stats.slash_knockback, stats.slash_self_knockback, stats.slash_radius, stats.slash_arc_angle, stats.slash_duration, stats.slash_cooldown)
	shoot.initialize(stats.shoot_cooldown, stats.projectile_damage, stats.projectile_knockback, stats.projectile_speed)
	capacity.initialize(stats.initial_capacity, stats.max_capacity)
	crunch_time.initialize(
		stats.crunch_duration,
		stats.damage_multiplier,
		stats.radius_multiplier,
		stats.speed_multiplier,
		stats.arc_angle_multiplier,
		stats.cooldown_multiplier,
		camera)
	damage_knockback_force = stats.damage_knockback_force
	damage_freeze_duration = stats.damage_freeze_duration
	damage_screen_shake_intensity = stats.damage_screen_shake_intensity
	death_knockback_force = stats.death_knockback_force
	death_freeze_duration = stats.death_freeze_duration
	death_screen_shake_intensity = stats.death_screen_shake_intensity

func _setup_animations() -> void:
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("move", 1, false)
	animation.configure_animation("slash", 2, true)
	animation.configure_animation("shoot", 2, true)
	animation.configure_animation("dash_charge", 2, true)
	animation.configure_animation("dash", 2, true)
	animation.configure_animation("take_damage", 3, true)
	animation.configure_animation("die", 4, true)

func _connect_signals() -> void:
	# Components
	melee_weapon.camera_shake_manager = camera_shake_manager
	aiming.muzzle = $Muzzle
	crunch_time.crunch_time_started.connect(_on_crunch_time_started)
	crunch_time.crunch_time_ended.connect(_on_crunch_time_ended)
	# Systems
	shop_manager.turret_placement_started.connect(_on_turret_placement_started)
	shop_manager.turret_placement_ended.connect(_on_turret_placement_ended)
	shop_manager.turret_bought.connect(capacity.spend)
	shop_manager.turret_upgraded.connect(capacity.spend)
	shop_manager.turret_sold.connect(capacity.gain)
	wave_manager.build_phase_started.connect(func() -> void: crunch_time.set_build_phase(true))
	wave_manager.combat_phase_started.connect(func(_i: int) -> void: crunch_time.set_build_phase(false))
	dash.charge_started.connect(_on_dash_charge_started)
	dash.charge_maxed.connect(_release_dash)
	dash.charge_ended.connect(_on_dash_charge_ended)
	dash.dash_started.connect(_handle_dash_started)

func _physics_process(delta: float) -> void:
	_sync_body_layer()
	_process_movement(delta)
	_process_locomotion()
	if not _is_dead:
		aiming.aim_at(get_global_mouse_position(), 0.0)
		aim_indicator.point_in(aiming.get_aim_direction())
		_process_held_primary_attack()
	if dash.is_charging():
		dash_direction_indicator.point_in(_get_dash_direction())
	else:
		dash_direction_indicator.fade_out()

## Holding the primary action retries the active weapon; each component owns its cooldown.
func _process_held_primary_attack() -> void:
	if not Input.is_action_pressed("shoot"):
		_shoot_held = false
	if not _shoot_held or dash.is_holding():
		return
	if crunch_time.is_crunch_time_active():
		var mouse_position := get_global_mouse_position()
		if melee_weapon.try_slash(mouse_position):
			_set_facing(mouse_position.x - global_position.x)
			animation.play_animation("slash")
		return
	if shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction()):
		animation.play_animation("shoot")

func _get_move_state() -> MoveState:
	if dash.is_dashing(): return MoveState.DASHING
	if knockback.is_active(): return MoveState.KNOCKED
	if not can_move: return MoveState.FROZEN
	return MoveState.NORMAL

func _process_movement(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	knockback.process(delta)
	match _get_move_state():
		MoveState.DASHING:
			_base_velocity = Vector2.ZERO
			velocity = dash.step_dash(delta)
			_add_conveyor_velocity()
			move_and_slide()
		MoveState.KNOCKED:
			_base_velocity = Vector2.ZERO
			velocity = knockback.velocity
			_add_conveyor_velocity()
			move_and_slide()
		MoveState.FROZEN:
			_base_velocity = Vector2.ZERO
			velocity = Vector2.ZERO
			move_and_slide()
		MoveState.NORMAL:
			_base_velocity = movement.calculate_velocity(_base_velocity, input_dir, delta)
			velocity = _base_velocity + _conveyor_velocity
			move_and_slide()

func _process_locomotion() -> void:
	if _is_dead or dash.is_charging():
		return
	var is_moving := velocity.length() > MIN_MOVE_SPEED
	animation.play_animation("move" if is_moving else "idle")
	if not animation.is_locked() and velocity.x != 0.0:
		_set_facing(velocity.x)

func _unhandled_input(event: InputEvent) -> void:
	# Armed here, not by polling, so clicks consumed by the UI or turret placer never fire.
	if event.is_action_pressed("shoot"):
		_shoot_held = true

	if event.is_action_pressed("crunch_time") and not dash.is_holding():
		crunch_time.try_activate()
	
	if event.is_action_pressed("dash"):
		dash.try_press()
	elif event.is_action_released("dash"):
		_release_dash()

func _set_facing(dir_x: float) -> void:
	if dir_x == 0.0:
		return
	_facing_right = dir_x > 0.0
	animated_sprite.flip_h = not _facing_right

func _get_dash_direction() -> Vector2:
	if velocity.length() > MIN_MOVE_SPEED:
		return velocity.normalized()
	return Vector2.RIGHT if _facing_right else Vector2.LEFT

func _release_dash() -> void:
	dash.release(_get_dash_direction())

func _on_dash_charge_started() -> void:
	time_scale_manager.request(DASH_CHARGE_SOURCE, dash_charge_time_scale)
	camera.set_zoom_factor(DASH_CHARGE_SOURCE, dash_charge_zoom, dash_charge_zoom_in_duration, true)
	PostProcessingManager.set_screen_effect(
		PostProcessingManager.DASH_DESATURATION,
		1.0,
		PostProcessingManager.SETTINGS.dash_fade_in_duration,
		true)
	# Scaled so the white ramp completes in dash.get_charge_duration() real seconds despite slow-motion.
	var length := animation.get_animation("dash_charge").length
	animation.play_animation("dash_charge", -1, length / (dash.get_charge_duration() * dash_charge_time_scale))

func _on_dash_charge_ended() -> void:
	time_scale_manager.release(DASH_CHARGE_SOURCE)
	camera.set_zoom_factor(DASH_CHARGE_SOURCE, 1.0, dash_charge_zoom_out_duration, true)
	PostProcessingManager.set_screen_effect(
		PostProcessingManager.DASH_DESATURATION,
		0.0,
		PostProcessingManager.SETTINGS.dash_fade_out_duration,
		true)
	animation.stop_animation("dash_charge")

func _handle_dash_started(direction: Vector2) -> void:
	_set_facing(direction.x)
	animation.play_animation("dash")
	camera_shake_manager.shake_screen(0.15, 0.15)

## Invincible players leave the PlayerBody layer so enemy hitboxes (e.g. Kamikazer explosions) can't trigger on them.
## Dashing also ignores turret bodies, matching how the player already passes through enemies.
func _sync_body_layer() -> void:
	var should_collide := not _is_invincible()
	if get_collision_layer_value(PLAYER_BODY_LAYER) != should_collide:
		set_collision_layer_value(PLAYER_BODY_LAYER, should_collide)
	var should_hit_turrets := not dash.is_dashing()
	if get_collision_mask_value(TURRET_BODY_LAYER) != should_hit_turrets:
		set_collision_mask_value(TURRET_BODY_LAYER, should_hit_turrets)

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if _is_dead or _is_invincible():
		return
	dash.cancel_charge()
	dash.cancel_dash()
	crunch_time.lose_charge()
	capacity.spend(float(amount))
	if capacity.current_capacity <= 0.0:
		_handle_death(from_position)
	else:
		_handle_damage(from_position, knockback_force)

func _on_melee_hit_obstacle(hit_position: Vector2, self_knockback_force: float) -> void:
	knockback.apply(hit_position, self_knockback_force)

func _handle_damage(from_position: Vector2, knockback_force: float) -> void:
	# Apply knockback
	knockback.apply(from_position, knockback_force)
	
	# Impact effects
	time_scale_manager.freeze(damage_freeze_duration)
	camera_shake_manager.shake_screen(damage_screen_shake_intensity, 0.3)
	
	# Animation
	animation.play_animation("take_damage")
	
	# Notify external systems
	damaged.emit(capacity.current_capacity)

func _handle_death(from_position: Vector2) -> void:
	_is_dead = true
	aim_indicator.hide()
	crunch_time.deactivate()
	knockback.apply(from_position, death_knockback_force)
	
	# Stronger impact effects on death
	time_scale_manager.freeze(death_freeze_duration)
	camera_shake_manager.shake_screen(death_screen_shake_intensity, 0.3)
	
	# Disable controls
	can_move = false
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)
	dash.set_enabled(false)
	
	animation.play_animation("die")
	
	# Notify external systems
	damaged.emit(0.0)
	died.emit()

func _is_invincible() -> bool:
	return crunch_time.is_crunch_time_active() or dash.is_invincible()

func can_afford(price: float) -> bool:
	return capacity.can_afford(price)

var can_pickup: bool:
	get: return not _is_dead and not crunch_time.is_crunch_time_active() and capacity.get_current() < capacity.get_max()

func pickup(amount: int) -> void:
	capacity.gain(float(amount))

## Called by CrunchPowerup on contact; false leaves it on the ground.
func try_collect_crunch_powerup() -> bool:
	return not _is_dead and crunch_time.add_charge()

func _on_turret_placement_started() -> void:
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)

func _on_turret_placement_ended() -> void:
	shoot.set_enabled(true)
	melee_weapon.set_enabled(crunch_time.is_crunch_time_active())

func _on_crunch_time_started(buffs: Dictionary) -> void:
	melee_weapon.set_crunch_time_active(true, buffs)
	melee_weapon.set_enabled(true)
	movement.set_crunch_time_active(true, buffs["speed"])
	crunch_shine_particles.emitting = true

func _on_crunch_time_ended(buffs: Dictionary, _duration: float) -> void:
	melee_weapon.set_enabled(false)
	melee_weapon.set_crunch_time_active(false, buffs)
	movement.set_crunch_time_active(false, buffs["speed"])
	crunch_shine_particles.emitting = false
