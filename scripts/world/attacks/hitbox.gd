extends Area2D
class_name HitboxComponent

## Deals damage to bodies by calling their take_damage method

@export var damage := 10
@export var knockback := 100.0
@export var enabled := true
@export var no_damage_group: StringName = &""
## Hits report this node's position (e.g. the wielder) so directional armor and knockback see the attacker.
@export var origin_node: Node2D
## Each receiver takes at most one hit per enable(); a body may name its receiver via get_hit_receiver().
@export var one_hit_per_receiver := false

var knockback_direction := Vector2.ZERO
var _hit_receivers: Array[Node] = []

signal hit_target(target: Node)
signal hit_area_target(target: Node)

func initialize(s_damage: int, s_knockback: float) -> void:
	damage = s_damage
	knockback = s_knockback

## Shared target rule for every attack: takes hits, is alive, and is in one of the groups.
static func can_hit(body: Node, groups: Array[StringName]) -> bool:
	if not is_instance_valid(body) or not body.has_method("was_hit"):
		return false
	if body.has_method("is_dead") and body.is_dead():
		return false
	for group_name: StringName in groups:
		if body.is_in_group(group_name):
			return true
	return false

static func apply_hit(body: Node, amount: int, knockback_force: float, from_position: Vector2, bypass_armor := false) -> void:
	if bypass_armor and body.has_method("was_hit_bypassing_armor"):
		body.was_hit_bypassing_armor(amount, knockback_force, from_position)
	else:
		body.was_hit(amount, knockback_force, from_position)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	var should_damage := no_damage_group.is_empty() or not body.is_in_group(no_damage_group)
	if should_damage and body.has_method("was_hit"):
		if one_hit_per_receiver:
			var receiver: Node = body.call(&"get_hit_receiver") if body.has_method("get_hit_receiver") else body
			if _hit_receivers.has(receiver):
				return
			_hit_receivers.append(receiver)
		var hit_origin := origin_node.global_position if origin_node else global_position
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
	_hit_receivers.clear()
	monitoring = true

func disable() -> void:
	enabled = false
	monitoring = false
