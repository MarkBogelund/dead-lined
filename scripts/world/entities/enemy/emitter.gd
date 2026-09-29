extends EnemyBase
class_name Emitter

## Runs to a random spot away from players/turrets, then stands still and emits a rotating two-sided stream of
## projectiles. Flees to a new spot when a target gets close; a hit while emitting pauses emission for hit_cooldown.

enum State {RELOCATE, EMIT}

## Minimum seconds between spot re-picks, so a spot that can't be made safe doesn't re-roll every frame.
const REPICK_INTERVAL := 0.5

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var shoot: ShootComponent = $ShootComponent
@onready var safe_spot: SafeSpotComponent = $SafeSpotComponent
@onready var emit_pivot: Node2D = $Visuals/EmitPivot
@onready var left_muzzle: Node2D = $Visuals/EmitPivot/LeftMuzzle
@onready var right_muzzle: Node2D = $Visuals/EmitPivot/RightMuzzle
@onready var body_sprite: AnimatedSprite2D = $Visuals/Body

@export var stats: EmitterStats

var _state := State.RELOCATE
var _spot := Vector2.ZERO
var _has_spot := false
var _repick_timer := 0.0
var _emit_timer := 0.0
var _emit_cooldown := 0.0

func _ready() -> void:
	_initialize()
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("run", 0, false)
	animation.configure_animation("emit", 0, false)

func _initialize() -> void:
	if not stats:
		push_error("%s requires an EmitterStats resource" % name)
		return
	_initialize_base(stats)
	hitbox.initialize(stats.damage, stats.knockback)
	# Emission timing is owned here; the component only spawns projectiles.
	shoot.initialize(0.0, stats.damage, stats.knockback, stats.projectile_speed)
	safe_spot.initialize(stats.spot_candidates, stats.spot_min_target_distance)

func _physics_process(delta: float) -> void:
	_emit_cooldown = maxf(0.0, _emit_cooldown - delta)
	_repick_timer = maxf(0.0, _repick_timer - delta)
	if knockback.is_active():
		velocity = knockback.velocity
	elif is_dead():
		velocity = Vector2.ZERO
	else:
		var threats := _get_threats()
		if _should_relocate(threats):
			_pick_spot(threats)
		match _state:
			State.RELOCATE:
				_process_relocate()
			State.EMIT:
				_process_emit(delta)

	knockback.process(delta)
	_add_conveyor_velocity()
	move_and_slide()

func _should_relocate(threats: Array[Node2D]) -> bool:
	if _repick_timer > 0.0:
		return false
	if not _has_spot:
		return true
	# While running, only a threatened destination forces a new spot; passing near a target is fine.
	var watched_point := global_position if _state == State.EMIT else _spot
	return safe_spot.get_nearest_threat_distance(watched_point, threats) < stats.flee_radius

func _pick_spot(threats: Array[Node2D]) -> void:
	var navigation_map := navigation.get_navigation_map()
	# Random-point queries return the origin until the navigation map has synced once.
	if NavigationServer2D.map_get_iteration_id(navigation_map) == 0:
		return
	_spot = safe_spot.pick_spot(navigation_map, navigation.navigation_layers, threats)
	_has_spot = true
	_state = State.RELOCATE
	_repick_timer = REPICK_INTERVAL

func _process_relocate() -> void:
	if not _has_spot:
		velocity = Vector2.ZERO
		animation.play_animation("idle")
		return
	# Pad by the agent's own arrival tolerance so it can't stop just short of the threshold.
	if global_position.distance_to(_spot) <= stats.arrive_distance + navigation.target_desired_distance:
		_state = State.EMIT
		_emit_timer = 0.0
		velocity = Vector2.ZERO
		return
	velocity = navigation.get_safe_velocity(_spot, stats.move_speed)
	_face_target(body_sprite, _spot)
	animation.play_animation("run")

func _process_emit(delta: float) -> void:
	velocity = Vector2.ZERO
	if _emit_cooldown > 0.0:
		animation.play_animation("idle")
		return
	animation.play_animation("emit")
	emit_pivot.rotation += deg_to_rad(stats.rotation_speed) * delta
	_emit_timer -= delta
	if _emit_timer <= 0.0:
		_emit_timer = stats.emit_interval
		_emit_from(right_muzzle)
		_emit_from(left_muzzle)

func _emit_from(muzzle: Node2D) -> void:
	shoot.try_shoot(muzzle.global_position, emit_pivot.global_position.direction_to(muzzle.global_position))

func _get_threats() -> Array[Node2D]:
	var threats: Array[Node2D] = []
	for group: StringName in [stats.targeting.primary_group, stats.targeting.secondary_group]:
		if group.is_empty():
			continue
		for node: Node in get_tree().get_nodes_in_group(group):
			if node is Node2D and not (node.has_method("is_dead") and node.is_dead()):
				threats.append(node)
	return threats

func is_emitting() -> bool:
	return _state == State.EMIT and _emit_cooldown <= 0.0

func buff_damage(multiplier: float) -> void:
	hitbox.damage = int(hitbox.damage * multiplier)
	shoot.projectile_damage = int(shoot.projectile_damage * multiplier)

func _before_handle_damage() -> void:
	if is_emitting():
		_emit_cooldown = stats.hit_cooldown
