extends Node2D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: HitboxComponent = $HitboxComponent

@export var is_player_projectile := false

var projectile_speed: float
var direction := Vector2.ZERO
var _damage: int
var _knockback: int

func _ready() -> void:
	hitbox.hit_target.connect(_on_hit_target)
	hitbox.damage = _damage
	hitbox.knockback = _knockback

func _physics_process(delta: float) -> void:
	position += direction * projectile_speed * delta

func _on_hit_target(target: Node) -> void:
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	if is_player_projectile and target.is_in_group("turrets"):
		target.receive_repair_shot()
	_animation_player.play("hit")

func set_orientation(pos: Vector2, rot: float, dir: Vector2) -> void:
	global_position = pos
	rotation = rot
	direction = dir
	
func set_parameters(speed: float, damage: int, knockback: int) -> void:
	projectile_speed = speed
	_damage = damage
	_knockback = knockback
