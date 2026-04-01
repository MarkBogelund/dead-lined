extends Area2D
class_name HitboxComponent

## Deals damage to bodies by calling their take_damage method

@export var damage := 10
@export var knockback := 100.0
@export var enabled := true

signal hit_target(target: Node)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	
	# Call take_damage on body if it has the method
	if body.has_method("take_damage"):
		body.take_damage(damage, knockback, global_position)
	
	# Notify owner that we hit something (for projectile destruction, etc.)
	emit_signal("hit_target", body)

func get_damage() -> int:
	return damage

func get_knockback() -> float:
	return knockback

func enable() -> void:
	enabled = true
	monitoring = true

func disable() -> void:
	enabled = false
	monitoring = false
