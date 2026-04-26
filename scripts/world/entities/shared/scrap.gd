extends RigidBody2D

@export var value := 1
@export var despawn_delay := 10

var can_collect := false
@onready var detection_area: Area2D = $DetectionArea
@onready var animation_handler: AnimationHandler = $AnimationHandler

func _ready():
	add_to_group("scrap")
	detection_area.body_entered.connect(_on_body_entered)
	animation_handler.configure_animation("pick_up", 1, true)
	animation_handler.configure_animation("idle", 0, false)
	animation_handler.configure_animation("despawn", 2, true)
	animation_handler.animation_finished.connect(_on_animation_finished)

func enable_collection() -> void:
	can_collect = true
	get_tree().create_timer(despawn_delay).timeout.connect(_on_despawn_timer)

func _on_despawn_timer() -> void:
	if not is_inside_tree() or not can_collect:
		return
	_despawn()

func despawn_on_combat() -> void:
	if not can_collect:
		return
	_despawn()

func _despawn() -> void:
	can_collect = false
	animation_handler.play_animation("despawn")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "despawn" or anim_name == "pick_up":
		queue_free()

func _on_body_entered(body: Node2D):
	if not can_collect:
		return
	if body.is_in_group("player") and body.can_pickup:
		body.pickup(value)
		animation_handler.play_animation("pick_up")
