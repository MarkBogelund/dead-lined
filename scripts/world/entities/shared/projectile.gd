extends Node2D

@onready var vfx_component: VFXComponent = $VFXComponent

var projectile_speed: float
var direction := Vector2.ZERO

@export var hit_vfx: PackedScene

func _ready() -> void:
	var hitbox: HitboxComponent = $HitboxComponent
	if hitbox:
		hitbox.hit_target.connect(_on_hit_target)

func _physics_process(delta):
	position += direction * projectile_speed * delta

func _on_hit_target(_target: Node) -> void:
	_destroy()

func _destroy() -> void:
	vfx_component.instantiate_vfx(hit_vfx, position)
	queue_free()

func set_orientation(pos, rot, dir):
	global_position = pos
	rotation = rot
	direction = dir
	
func set_parameters(speed, damage, knockback):
	projectile_speed = speed
	var hitbox: HitboxComponent = $HitboxComponent
	if hitbox:
		hitbox.damage = damage
		hitbox.knockback = knockback
