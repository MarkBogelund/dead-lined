extends Area2D
class_name HitboxComponent

## Deals damage to bodies by calling their take_damage method

@export var damage := 10
@export var knockback := 100.0
@export var enabled := true
@export var no_damage_group: StringName = &""

signal hit_target(target: Node)

func initialize(s_damage: int, s_knockback: float) -> void:
	damage = s_damage
	knockback = s_knockback

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	var should_damage := no_damage_group.is_empty() or not body.is_in_group(no_damage_group)
	if should_damage and body.has_method("was_hit"):
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
