extends AnimatableBody2D
class_name ArmorShieldComponent

signal shield_hit(amount: int, from_position: Vector2)

@export var collision_polygon: CollisionPolygon2D

var _enabled := true

func _ready() -> void:
	assert(collision_polygon, "ArmorShieldComponent requires its owned collision polygon")

func set_facing(angle: float) -> void:
	global_rotation = angle

func set_enabled(value: bool) -> void:
	_enabled = value
	collision_polygon.set_deferred("disabled", not value)

func was_hit(amount: int, _knockback_force: float, from_position: Vector2) -> void:
	if _enabled:
		shield_hit.emit(amount, from_position)