extends CharacterBody2D
class_name Player

signal damaged(current_capacity: float)
signal died

@onready var wave_manager: WaveManager = %WaveManager
@onready var shop_manager: ShopManager = %ShopManager
@onready var game_over_manager: GameOverManager = %GameOverManager
@onready var camera_shake_manager = %CameraShakeManager
@onready var freeze_frame_manager = %FreezeFrameManager

@onready var capacity: CapacityComponent = $CapacityComponent
@onready var knockback: KnockbackComponent = $KnockbackComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var animation: AnimationHandler = $AnimationHandler
@onready var melee_weapon: MeleeWeapon = $MeleeWeapon
@onready var dash: DashComponent = $DashComponent
@onready var aiming: AimingComponent = $AimingComponent
@onready var crunch_time: CrunchTimeComponent = $CrunchTimeComponent
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export_group("Capacity Costs")
@export var shoot_cost: float = 2.0

@export_group("Damage Effects")
@export var damage_knockback_force := 200.0
@export var damage_freeze_duration := 0.08
@export var damage_screen_shake_intensity := 0.2

@export_group("Death Effects")
@export var death_knockback_force := 400.0
@export var death_freeze_duration := 0.15
@export var death_screen_shake_intensity := 0.35

enum MoveState {NORMAL, DASHING, KNOCKED, FROZEN}

var can_move := true
var _facing_right := true
var _is_dead := false

const MIN_MOVE_SPEED := 10.0

func _ready() -> void:
	_setup_animations()
	_connect_signals()

func _setup_animations() -> void:
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("move", 1, false)
	animation.configure_animation("slash", 2, true)
	animation.configure_animation("dash", 2, true)
	animation.configure_animation("take_damage", 3, true)
	animation.configure_animation("die", 4, true)

func _connect_signals() -> void:
	# Components
	melee_weapon.camera_shake_manager = camera_shake_manager
	aiming.muzzle = $Muzzle
	crunch_time.crunch_time_started.connect(_on_crunch_time_started)
	crunch_time.crunch_time_ended.connect(_on_crunch_time_ended)
	crunch_time.drain_tick.connect(_on_crunch_drain_tick)
	# Systems
	shop_manager.turret_placement_started.connect(_on_turret_placement_started)
	shop_manager.turret_placement_ended.connect(_on_turret_placement_ended)
	shop_manager.turret_bought.connect(_on_turret_bought)
	shop_manager.turret_lost.connect(_on_turret_lost)
	wave_manager.build_phase_started.connect(func(): crunch_time.set_build_phase(true))
	wave_manager.combat_phase_started.connect(func(_i: int): crunch_time.set_build_phase(false))

func _physics_process(delta: float) -> void:
	_process_movement(delta)
	_process_locomotion()

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
			velocity = dash.get_dash_velocity()
			var collision := move_and_collide(velocity * delta)
			if collision:
				dash.cancel_dash()
		MoveState.KNOCKED:
			velocity = knockback.velocity
			move_and_slide()
		MoveState.FROZEN:
			velocity = Vector2.ZERO
			move_and_slide()
		MoveState.NORMAL:
			velocity = movement.calculate_velocity(velocity, input_dir, delta)
			move_and_slide()

func _process_locomotion() -> void:
	if _is_dead:
		return
	var is_moving := velocity.length() > MIN_MOVE_SPEED
	animation.play_animation("move" if is_moving else "idle")
	if not animation.is_locked() and velocity.x != 0.0:
		_set_facing(velocity.x)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("crunch_time"):
		crunch_time.toggle(capacity.can_crunch_time())
	
	if event.is_action_pressed("shoot") and capacity.can_afford(shoot_cost):
		var mouse_pos := get_global_mouse_position()
		aiming.aim_at(mouse_pos, 0.0)
		if shoot.try_shoot(aiming.get_muzzle_position(), aiming.get_aim_direction()):
			capacity.spend(shoot_cost)
			animation.play_animation("slash") # Reuse slash animation for shooting since it has the same timing needs
	
	if event.is_action_pressed("slash"):
		var mouse_pos := get_global_mouse_position()
		if melee_weapon.try_slash(mouse_pos):
			_set_facing(mouse_pos.x - global_position.x)
			animation.play_animation("slash")
	
	if event.is_action_pressed("dash"):
		var dash_dir := _get_dash_direction()
		if dash.try_dash(dash_dir):
			_handle_dash_started(dash_dir)

func _set_facing(dir_x: float) -> void:
	if dir_x == 0.0:
		return
	_facing_right = dir_x > 0.0
	animated_sprite.flip_h = not _facing_right

func _get_dash_direction() -> Vector2:
	if velocity.length() > MIN_MOVE_SPEED:
		return velocity.normalized()
	return Vector2.RIGHT if _facing_right else Vector2.LEFT

func _handle_dash_started(direction: Vector2) -> void:
	_set_facing(direction.x)
	animation.play_animation("dash")
	camera_shake_manager.shake_screen(0.15, 0.15)

func was_hit(amount: int, knockback_force: float, from_position: Vector2) -> void:
	if _is_dead or _is_invincible():
		return
	dash.cancel_dash()
	capacity.spend(float(amount))
	if capacity.current_capacity <= 0.0:
		_handle_death(from_position)
	else:
		_handle_damage(from_position, knockback_force)

func _handle_damage(from_position: Vector2, knockback_force: float) -> void:
	# Apply knockback
	knockback.apply(from_position, knockback_force)
	
	# Impact effects
	freeze_frame_manager.freeze(damage_freeze_duration)
	camera_shake_manager.shake_screen(damage_screen_shake_intensity, 0.3)
	
	# Animation
	animation.play_animation("take_damage")
	
	# Notify external systems
	damaged.emit(capacity.current_capacity)

func _handle_death(from_position: Vector2) -> void:
	_is_dead = true
	crunch_time.deactivate()
	knockback.apply(from_position, death_knockback_force)
	
	# Stronger impact effects on death
	freeze_frame_manager.freeze(death_freeze_duration)
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
	get: return not crunch_time.is_crunch_time_active() and capacity.current_capacity < 100.0

func pickup(amount: int) -> void:
	capacity.gain(float(amount))

func _on_crunch_drain_tick() -> void:
	var max_drain := maxf(0.0, capacity.current_capacity - crunch_time.deactivation_threshold)
	capacity.spend(minf(1.0, max_drain))
	if capacity.current_capacity <= crunch_time.deactivation_threshold:
		crunch_time.deactivate()

func _on_turret_placement_started():
	shoot.set_enabled(false)
	melee_weapon.set_enabled(false)

func _on_turret_placement_ended():
	shoot.set_enabled(true)
	melee_weapon.set_enabled(true)

func _on_turret_bought(price: float) -> void:
	capacity.spend(price)
	capacity.lower_threshold()

func _on_turret_lost() -> void:
	capacity.raise_threshold()

func _on_crunch_time_started(buffs: Dictionary) -> void:
	capacity.spend(crunch_time.activation_cost)
	melee_weapon.hitbox.damage = int(melee_weapon.hitbox.damage * buffs["damage"])
	melee_weapon.slash_radius *= buffs["radius"]
	movement.speed *= buffs["speed"]
	melee_weapon.arc_angle *= buffs["arc_angle"]
	melee_weapon.scale *= buffs["weapon_size"]
	melee_weapon.slash_cooldown *= buffs["cooldown"]
	animated_sprite.modulate = Color(1.5, 0.5, 0.5, 1.0)

func _on_crunch_time_ended(buffs: Dictionary) -> void:
	melee_weapon.hitbox.damage = int(melee_weapon.hitbox.damage / buffs["damage"])
	melee_weapon.slash_radius /= buffs["radius"]
	movement.speed /= buffs["speed"]
	melee_weapon.arc_angle /= buffs["arc_angle"]
	melee_weapon.scale /= buffs["weapon_size"]
	melee_weapon.slash_cooldown /= buffs["cooldown"]
	animated_sprite.modulate = Color.WHITE
