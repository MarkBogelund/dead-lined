extends Area2D
class_name HitboxComponent

## Deals damage to bodies by calling their take_damage method

@export var damage := 10
@export var knockback := 100.0
@export var enabled := true
@export var heals_turrets := false

signal hit_target(target: Node)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	
	if heals_turrets and body.is_in_group("turrets"):
		if body.has_method("heal_shot"):
			body.heal_shot(damage)
	elif body.has_method("was_hit"):
		body.was_hit(damage, knockback, global_position)
	
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
