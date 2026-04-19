extends Node2D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: HitboxComponent = $HitboxComponent

var projectile_speed: float
var direction := Vector2.ZERO
var _damage: int
var _knockback: int

func _ready() -> void:
	hitbox.hit_target.connect(_on_hit_target)
	hitbox.damage = _damage
	hitbox.knockback = _knockback

func _physics_process(delta):
	position += direction * projectile_speed * delta

func _on_hit_target(_target: Node) -> void:
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	_animation_player.play("hit")

func set_orientation(pos, rot, dir):
	global_position = pos
	rotation = rot
	direction = dir
	
func set_parameters(speed, damage, knockback):
	projectile_speed = speed
	_damage = damage
	_knockback = knockback
