extends Area2D
class_name HitboxComponent

## Deals damage to bodies by calling their take_damage method

@export var damage := 10
@export var knockback := 100.0
@export var enabled := true
@export var no_damage_group: StringName = &""

var knockback_direction := Vector2.ZERO

signal hit_target(target: Node)
signal hit_area_target(target: Node)

func initialize(s_damage: int, s_knockback: float) -> void:
	damage = s_damage
	knockback = s_knockback

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	var should_damage := no_damage_group.is_empty() or not body.is_in_group(no_damage_group)
	if should_damage and body.has_method("was_hit"):
		var hit_origin := global_position
		if knockback_direction.is_finite() and not knockback_direction.is_zero_approx():
			hit_origin = body.global_position - knockback_direction
		body.was_hit(damage, knockback, hit_origin)
	hit_target.emit(body)

func _on_area_entered(area: Area2D) -> void:
	if not enabled:
		return
	hit_area_target.emit(area.get_parent())

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
