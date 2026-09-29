extends Node2D

## Base for every projectile scene (see projectile_base.tscn). Moves straight, hits via HitboxComponent, and
## despawns after its lifetime or, for enemy projectiles, when the build phase starts.

@onready var animation: AnimationHandler = $AnimationHandler
@onready var hitbox: HitboxComponent = $HitboxComponent

@export var is_player_projectile := false
@export var despawn_on_build_phase := false

var projectile_speed: float
var direction := Vector2.ZERO
var _damage: int
var _knockback: float
var _lifetime := -1.0
var _is_resolving_hit := false
var _is_despawning := false

func _ready() -> void:
	animation.configure_animation("idle", 0, false)
	animation.configure_animation("despawn", 1, true)
	animation.configure_animation("hit", 2, true)
	# Each projectile scene may supply its own looping idle (e.g. spin); the base only owns hit and despawn.
	if animation.has_configured_animation("idle"):
		animation.play_animation("idle")
	hitbox.hit_target.connect(_on_hit_target)
	hitbox.damage = _damage
	hitbox.knockback = _knockback
	if _lifetime > 0.0:
		get_tree().create_timer(_lifetime, false).timeout.connect(despawn)
	if despawn_on_build_phase:
		var wave_manager := get_tree().get_first_node_in_group("wave_manager") as WaveManager
		if wave_manager:
			wave_manager.build_phase_started.connect(despawn)

func _physics_process(delta: float) -> void:
	position += direction * projectile_speed * delta

## Plays despawn; the projectile keeps flying and can still hit until the animation frees it.
func despawn() -> void:
	if _is_despawning or _is_resolving_hit:
		return
	_is_despawning = true
	animation.play_animation("despawn")

func _on_hit_target(_target: Node) -> void:
	_resolve_hit()

func receive_wrench_hit() -> bool:
	if is_player_projectile or _is_resolving_hit:
		return false
	_resolve_hit()
	return true

func _resolve_hit() -> void:
	if _is_resolving_hit:
		return
	_is_resolving_hit = true
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	animation.play_animation("hit")

func set_orientation(pos: Vector2, rot: float, dir: Vector2) -> void:
	global_position = pos
	rotation = rot
	direction = dir
	
func set_parameters(speed: float, damage: int, knockback: float, lifetime: float) -> void:
	projectile_speed = speed
	_damage = damage
	_knockback = knockback
	_lifetime = lifetime
