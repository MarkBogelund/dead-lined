extends Area2D

var resource_manager: ResourceManager

@export var value := 10
@export var move_duration := 0.25
@export var speed := 200.0

var velocity: Vector2
var time := 0.0
var can_collect := false

func _ready():
	resource_manager = get_tree().get_first_node_in_group("resource_manager")
	connect("body_entered", _on_body_entered)

func set_explosion(drop_position: Vector2, drop_radius: float) -> void:
	global_position = drop_position

	# Random direction
	var angle := randf() * TAU
	var dir := Vector2(cos(angle), sin(angle))

	# Random distance inside radius
	var distance := randf() * drop_radius
	var target_pos := drop_position + dir * distance

	# Quick outward tween
	create_tween().tween_property(
		self,
		"global_position",
		target_pos,
		0.15
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _process(delta):
	if time < move_duration:
		time += delta
		position += velocity * delta
	else:
		can_collect = true

func _on_body_entered(body: Node2D):
	if not can_collect:
		return

	if body.is_in_group("player"):
		resource_manager.add_scrap_amount(value)
		queue_free()
